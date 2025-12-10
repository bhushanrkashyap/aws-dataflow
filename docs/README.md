# 🧠 Stage 3: Athena Queries
Query processed data using **Amazon Athena**.

```sql
SELECT symbol, AVG(close) AS avg_close FROM ohlcv_processed GROUP BY symbol;
```
