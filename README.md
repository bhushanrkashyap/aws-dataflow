---
# AWS Serverless OHLCV Data Engine

[![Python](https://img.shields.io/badge/Python-3.8%2B-blue)](https://www.python.org/)
[![AWS Glue](https://img.shields.io/badge/AWS%20Glue-Serverless-orange)](https://aws.amazon.com/glue/)
[![Athena](https://img.shields.io/badge/Athena-Serverless-purple)](https://aws.amazon.com/athena/)

Overview
--------
This repository implements a production-ready, serverless data engine that ingests OHLCV time-series, performs ETL and data quality operations, catalogs data for querying, and exposes analytics to business users via QuickSight.

System Architecture
-------------------

```mermaid
graph LR
  API[External API: Twelve Data] --> Ingest(Ingestion: Lambda / Notebook)
  Ingest --> Raw[S3 Raw Zone]
  Raw --> Glue(AWS Glue ETL)
  Glue --> Processed[S3 Processed Zone]
  Processed --> Athena(Amazon Athena)
  Athena --> QuickSight(Amazon QuickSight)
  Glue --> Catalog(Glue Data Catalog)
  subgraph Observability
    CloudWatch[CloudWatch Logs & Metrics]
    Catalog -- updates --> CloudWatch
  end
```

Rendered architecture (PNG):

![Architecture diagram](docs/assets/diagrams/image.png)

Visual assets
-------------
- QuickSight dashboards: `docs/assets/dashboards/` (1.png, 2.png, 4.png, 6.png)
- Glue-specific diagrams: `docs/assets/glue/` (gluejob.png, jobruns.png, monitoring_glue.png)
- Monitoring screenshots: `docs/assets/monitoring/` (data_quality_checks.png, image.png, image copy.png)

Project layout
--------------
```text
aws-dataflow/
├─ notebooks/                # exploratory notebooks and ingestion PoCs
├─ src/
│  └─ etl/
│     └─ jobs/               # Glue job scripts (production-ready)
├─ sql/
---
# AWS Serverless OHLCV Data Engine

[![Python](https://img.shields.io/badge/Python-3.8%2B-blue)](https://www.python.org/)
[![AWS Glue](https://img.shields.io/badge/AWS%20Glue-Serverless-orange)](https://aws.amazon.com/glue/)
[![Athena](https://img.shields.io/badge/Athena-Serverless-purple)](https://aws.amazon.com/athena/)

Overview
--------
This repository implements a production-ready, serverless data engine that ingests OHLCV time-series, performs ETL and data-quality operations, catalogs data for querying, and exposes analytics to business users via QuickSight.

Architecture (PNG)
------------------

The canonical architecture diagram is embedded below. (PNG is used to ensure consistent rendering on GitHub.)

![Architecture diagram](docs/assets/diagrams/image.png)

Visual assets
-------------
- QuickSight dashboards: `docs/assets/dashboards/` (`1.png`, `2.png`, `4.png`, `6.png`)
- Glue diagrams: `docs/assets/glue/` (`gluejob.png`, `jobruns.png`, `monitoring_glue.png`)
- Monitoring screenshots: `docs/assets/monitoring/` (`data_quality_checks.png`, `image.png`)

Project layout
--------------
Use the simple tree below (plain text) — Mermaid diagrams were removed because they do not render reliably in all readers.

```text
aws-dataflow/
├─ notebooks/                # exploratory notebooks and ingestion PoCs
├─ src/                      # production code
│  └─ etl/
│     └─ jobs/               # Glue job scripts
├─ sql/
│  └─ queries/               # Athena queries
├─ docs/
│  └─ assets/                # diagrams, dashboards, monitoring screenshots
├─ requirements.txt
└─ README.md
```

QuickSight Dashboard Examples
-----------------------------

Below are small thumbnails with a short description of the insight each dashboard provides:

![Daily price change](docs/assets/dashboards/1.png)
*Daily price change — shows short-term volatility and price movement across symbols.*

![Daily volume](docs/assets/dashboards/2.png)
*Daily volume — highlights trading activity and unusually high-volume days.*

![Monthly volume](docs/assets/dashboards/4.png)
*Monthly volume — illustrates longer-term trends and seasonal patterns in liquidity.*

![Price vs volume](docs/assets/dashboards/6.png)
*Price vs volume — helps surface correlations between price moves and volume spikes.*

How to run (quick)
------------------

1. Set S3 bucket names and Glue database in environment variables or a parameter store.
2. Run unit tests for transforms (if available): `pytest tests/`.
3. Start Glue job (example):

```bash
aws glue start-job-run --job-name my-glue-job --arguments '--S3_INPUT=s3://mybucket/raw/ --S3_OUTPUT=s3://mybucket/processed/'
```


