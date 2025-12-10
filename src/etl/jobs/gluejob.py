"""Glue ETL job: clean, dedupe, aggregate, and write processed OHLCV data.

This version refactors the original Glue script to improve readability, add
basic logging, and provide clearer function interfaces. It is intended to be
used as a template — adapt configuration (S3 paths, job name) to your
environment before deployment.
"""
from __future__ import annotations

import logging
import sys
from typing import Iterable, List, Tuple

from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import DropFields
from awsglue.utils import getResolvedOptions
from awsglue.dynamicframe import DynamicFrame
from awsgluedq.transforms import EvaluateDataQuality
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql.types import (
    ArrayType,
    DoubleType,
    IntegerType,
    LongType,
    NullType,
    StringType,
    StructType,
)

logger = logging.getLogger("gluejob")
logging.basicConfig(level=logging.INFO)


def find_null_like_columns(df_dynamic: DynamicFrame, null_string_set: Iterable[str], null_numeric_set: Iterable[int]) -> List[str]:
    """Return list of column paths where values are only null-like according to provided sets.

    This helper inspects top-level and nested struct fields. For performance,
    limit the schema depth and avoid collecting very large distinct sets in
    production; prefer statistical checks or data-quality rules.
    """
    df = df_dynamic.toDF()
    schema = df.schema
    null_cols: List[str] = []

    def _inspect_field(prefix: str, field_type):
        if isinstance(field_type, StructType):
            for f in field_type:
                _inspect_field(f"{prefix}.{f.name}" if prefix else f.name, f.dataType)
        elif isinstance(field_type, ArrayType) and isinstance(field_type.elementType, StructType):
            _inspect_field(prefix, field_type.elementType)
        elif isinstance(field_type, NullType):
            null_cols.append(prefix)
        else:
            col_name = prefix.split(".")[-1]
            distinct_vals = df.select(prefix).distinct().collect()
            vals = set()
            for row in distinct_vals:
                v = row[col_name]
                if isinstance(v, list):
                    for it in v:
                        vals.add(it.strip() if isinstance(it, str) else it)
                elif isinstance(v, str):
                    vals.add(v.strip())
                else:
                    vals.add(v)

            if isinstance(field_type, StringType):
                if vals.issubset(set(null_string_set)):
                    null_cols.append(prefix)
            elif isinstance(field_type, (IntegerType, LongType, DoubleType)):
                if vals.issubset(set(null_numeric_set)):
                    null_cols.append(prefix)

    _inspect_field("", schema)
    return null_cols


def drop_null_fields(glue_context: GlueContext, frame: DynamicFrame, null_string_set=None, null_numeric_set=None, transformation_ctx: str = "DropNulls") -> DynamicFrame:
    null_string_set = null_string_set or {"", "NULL", "null", None}
    null_numeric_set = null_numeric_set or {None}
    paths = find_null_like_columns(frame, null_string_set, null_numeric_set)
    if paths:
        logger.info("Dropping null-like fields: %s", paths)
        return DropFields.apply(frame=frame, paths=paths, transformation_ctx=transformation_ctx)
    return frame


def spark_aggregate(glue_context: GlueContext, parent_frame: DynamicFrame, groups: List[str], aggs: List[Tuple[str, str]], transformation_ctx: str) -> DynamicFrame:
    agg_exprs = [getattr(F, func)(col).alias(f"{func}_{col}") for col, func in aggs]
    df = parent_frame.toDF()
    result = df.groupBy(*groups).agg(*agg_exprs) if groups else df.agg(*agg_exprs)
    return DynamicFrame.fromDF(result, glue_context, transformation_ctx)


def main():
    args = getResolvedOptions(sys.argv, ["JOB_NAME"])  # extend as needed
    sc = SparkContext()
    glue_context = GlueContext(sc)
    spark = glue_context.spark_session
    job = Job(glue_context)
    job.init(args["JOB_NAME"], args)

    DEFAULT_DATA_QUALITY_RULESET = """
        Rules = [
            ColumnCount > 0
        ]
    """

    # Read raw CSV from S3 (example path; replace with job arguments/config)
    raw = glue_context.create_dynamic_frame.from_options(
        format_options={"quoteChar": '"', "withHeader": True, "separator": ","},
        connection_type="s3",
        format="csv",
        connection_options={"paths": ["s3://csvbucketdatabricks/ohlcv/"], "recurse": True},
        transformation_ctx="ReadRaw",
    )

    deduped = DynamicFrame.fromDF(raw.toDF().dropDuplicates(), glue_context, "Deduped")

    cleaned = drop_null_fields(glue_context, deduped)

    aggregated = spark_aggregate(glue_context, parent_frame=cleaned, groups=["open", "low"], aggs=[("high", "avg")], transformation_ctx="Aggregate")

    # Data quality evaluation
    EvaluateDataQuality().process_rows(
        frame=aggregated,
        ruleset=DEFAULT_DATA_QUALITY_RULESET,
        publishing_options={"dataQualityEvaluationContext": "DQContext", "enableDataQualityResultsPublishing": True},
        additional_options={"dataQualityResultsPublishing.strategy": "BEST_EFFORT", "observations.scope": "ALL"},
    )

    # Write processed output
    glue_context.write_dynamic_frame.from_options(
        frame=aggregated,
        connection_type="s3",
        format="csv",
        connection_options={"path": "s3://csvbucketdatabricks/processed_data/", "partitionKeys": []},
        transformation_ctx="WriteProcessed",
    )

    job.commit()


if __name__ == "__main__":
    main()