# AWS Glue Notes

This document contains notes and pointers for the Glue jobs in `src/etl/jobs`.

- Job scripts: `src/etl/jobs/gluejob.py`
- Configuration: use environment variables or a parameter store for S3 bucket names, Glue database names, and credential/role ARNs.
- Best practice: run unit tests locally using small CSV samples and a Spark local runner before submitting to Glue.
