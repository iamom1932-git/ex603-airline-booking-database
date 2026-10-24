-- 4.1a Q: Across all bookings, what are the count, total, average, min and max fare,
--    and how many distinct passengers appear? (Aggregate functions)
SELECT COUNT(*)                     AS booking_count,
       SUM(fare_paid)               AS total_fare,
       ROUND(AVG(fare_paid), 2)     AS avg_fare,
       MIN(fare_paid)               AS min_fare,
       MAX(fare_paid)               AS max_fare,
       COUNT(DISTINCT passenger_id) AS distinct_passengers
FROM   bookings;

-- 4.1a-check Q: The minimum is 0.00. Is every zero fare a cancelled booking?
SELECT booking_status,
       COUNT(*)                                AS bookings,
       COUNT(*) FILTER (WHERE fare_paid = 0)   AS zero_fare_rows,
       ROUND(AVG(fare_paid), 2)                AS avg_fare
FROM   bookings
GROUP BY booking_status
ORDER BY bookings DESC;

-- 4.1b Q: For each flight, how many bookings and what average fare, busiest first? (GROUP BY)
SELECT flight_id,
       COUNT(*)                 AS bookings,
       ROUND(AVG(fare_paid), 2) AS avg_fare
FROM   bookings
GROUP BY flight_id
ORDER BY bookings DESC, flight_id;

-- 4.1c Q: Which flights have enough bookings for their numbers to mean something? (HAVING)
--    Threshold 15: flights below it have ~11 or fewer bookings, so one cancellation
--    swings their rate by 9+ points.
SELECT flight_id,
       COUNT(*)                 AS bookings,
       ROUND(AVG(fare_paid), 2) AS avg_fare
FROM   bookings
GROUP BY flight_id
HAVING COUNT(*) >= 15
ORDER BY bookings DESC, flight_id;

-- 4.1d Q: How does performance vary by booking country AND flight? (two-dimension GROUP BY)
SELECT booking_country,
       flight_id,
       COUNT(*)                                              AS bookings,
       COUNT(*) FILTER (WHERE booking_status = 'cancelled')  AS cancelled,
       ROUND(AVG(fare_paid), 2)                              AS avg_fare
FROM   bookings
GROUP BY booking_country, flight_id
ORDER BY booking_country, flight_id;