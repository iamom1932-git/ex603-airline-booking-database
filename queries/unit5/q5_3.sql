-- ============================================================
-- Task 5.3 - Understand Join Performance and Execution Plans (Airline Booking)
-- ============================================================

-- ---------------- PART A: CROSS JOIN ----------------

-- 5.3a-1 Q: How many rows are in each source table, what should the product be,
--    and how many rows does the CROSS JOIN actually return?
SELECT (SELECT COUNT(*) FROM flights)                           AS flights_rows,
       (SELECT COUNT(*) FROM airports)                          AS airports_rows,
       (SELECT COUNT(*) FROM flights) * (SELECT COUNT(*) FROM airports) AS expected_product,
       (SELECT COUNT(*) FROM flights CROSS JOIN airports)       AS cross_join_rows,
       (SELECT COUNT(*) FROM flights) * (SELECT COUNT(*) FROM airports)
         = (SELECT COUNT(*) FROM flights CROSS JOIN airports)   AS product_matches;

-- 5.3a-2 Q: What does the Cartesian product look like? Every flight paired with
--    every airport (first 15 rows).
SELECT f.flight_id, f.flight_number, a.airport_id, a.name AS airport_name
FROM   flights f
CROSS JOIN airports a
ORDER BY f.flight_id, a.airport_id
LIMIT 15;

-- ---------------- PART B: execution plan for the 5.1a three-table join ----------------

-- 5.3b Q: How does PostgreSQL plan the three-table join? (plan only, query not run)
EXPLAIN
SELECT b.booking_id, p.passenger_name, f.flight_number, b.booked_at
FROM   bookings   b
JOIN   passengers p ON p.passenger_id = b.passenger_id
JOIN   flights    f ON f.flight_id    = b.flight_id
ORDER BY b.booked_at, b.booking_id;

-- 5.3b-2 Same statement with actual timings and row counts (safe: read-only SELECT).
EXPLAIN (ANALYZE, BUFFERS)
SELECT b.booking_id, p.passenger_name, f.flight_number, b.booked_at
FROM   bookings   b
JOIN   passengers p ON p.passenger_id = b.passenger_id
JOIN   flights    f ON f.flight_id    = b.flight_id
ORDER BY b.booked_at, b.booking_id;