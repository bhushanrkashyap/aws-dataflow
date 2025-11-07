# 📊 OHLCV AWS Data Pipeline
A simple, serverless AWS pipeline that ingests, cleans, and visualizes **financial OHLCV data**.
<p align ="center"><img src="5.architecture/architecture.png" width="700"></p>
**Stages:** Ingestion → ETL (Glue) → Query (Athena) → Visualization (QuickSight) → Monitoring (CloudWatch)
