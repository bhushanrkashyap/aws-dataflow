SELECT AVG(open) AS avg_open_price,
	AVG(close) AS avg_close_price,
	MAX(high) AS highest_price,
	MIN(low) AS lowest_price,
	SUM(volume) AS total_volume
FROM ohlcv_db.ohlcv;


SELECT date,
	AVG(open) AS avg_open_price,
	AVG(close) AS avg_close_price,
	MAX(high) AS highest_price,
	MIN(low) AS lowest_price,
	SUM(volume) AS total_volume
FROM ohlcv_db.ohlcv
GROUP BY date
ORDER BY date;



SELECT AVG(high - low) AS avg_daily_volatility
FROM ohlcv_db.ohlcv;
SELECT date,
	((close - open) / open) * 100 AS daily_return_pct
FROM ohlcv_db.ohlcv
ORDER BY date;


SELECT AVG((close - open) / open * 100) AS avg_daily_return_pct,
	AVG(high - low) AS avg_volatility,
	SUM(volume) / COUNT(*) AS avg_daily_volume
FROM ohlcv_db.ohlcv;



SELECT MAX(close) AS highest_close_price,
	MIN(close) AS lowest_close_price
FROM ohlcv_db.ohlcv;
SELECT date,
	close
FROM ohlcv_db.ohlcv
WHERE close = (
		SELECT MAX(close)
		FROM ohlcv_db.ohlcv
	);
	
	
SELECT date,
	close
FROM ohlcv_db.ohlcv
WHERE close = (
		SELECT MIN(close)
		FROM ohlcv_db.ohlcv
	);