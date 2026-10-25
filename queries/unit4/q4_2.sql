-- 4.2a Q: For each flight, how many bookings in total and how many failures,
--    in one pass with no WHERE clause? (CASE inside aggregate)
SELECT flight_id,
       COUNT(*)                                                  AS total_bookings,
       SUM(CASE WHEN booking_status = 'cancelled' THEN 1 ELSE 0 END) AS failed_bookings,
       ROUND(100.0 * SUM(CASE WHEN booking_status = 'cancelled' THEN 1 ELSE 0 END)
             / COUNT(*), 1)                                      AS failure_rate_pct
FROM   bookings
GROUP BY flight_id
ORDER BY failure_rate_pct DESC, flight_id;

-- 4.2b Q: What are the failure counts per region, plus a platform grand total,
--    without detail rows? (ROLLUP)
--    Rows with a country = regional subtotals; the row labelled 'PLATFORM TOTAL' = grand total.
SELECT CASE WHEN GROUPING(booking_country) = 1 THEN 'PLATFORM TOTAL'
            ELSE booking_country END                              AS region,
       COUNT(*)                                                   AS total_bookings,
       SUM(CASE WHEN booking_status = 'cancelled' THEN 1 ELSE 0 END) AS failed_bookings,
       ROUND(100.0 * SUM(CASE WHEN booking_status = 'cancelled' THEN 1 ELSE 0 END)
             / COUNT(*), 1)                                       AS failure_rate_pct
FROM   bookings
GROUP BY ROLLUP (booking_country)
ORDER BY GROUPING(booking_country), booking_country;

-- 4.2c Q: Among high-volume flights (15+ bookings), what is the baseline failure rate? (CTE pipeline)
WITH per_flight AS (
    SELECT flight_id,
           COUNT(*) AS bookings,
           SUM(CASE WHEN booking_status = 'cancelled' THEN 1 ELSE 0 END) AS failures
    FROM   bookings
    GROUP BY flight_id
)
SELECT COUNT(*)                                         AS high_volume_flights,
       ROUND(100.0 * SUM(failures) / SUM(bookings), 1)  AS pooled_failure_rate_pct,
       ROUND(AVG(100.0 * failures / bookings), 1)       AS avg_of_flight_rates_pct
FROM   per_flight
WHERE  bookings >= 15;