-- ============================================================
-- Task 5.2 - Find Records That Joins May Exclude (Airline Booking)
-- Producer = flight, event = booking. Count producers by flight_id so a
-- flight with many bookings is counted once.
-- ============================================================

-- ---------------- PART A: LEFT JOIN vs INNER JOIN ----------------

-- 5.2a-1 Q: List every flight with its booking count, including flights with none.
SELECT f.flight_id, f.flight_number, COUNT(b.booking_id) AS bookings
FROM   flights f
LEFT JOIN bookings b ON b.flight_id = f.flight_id
GROUP BY f.flight_id, f.flight_number
ORDER BY f.flight_id;

-- 5.2a-2 Q: Same list using INNER JOIN. Which flights are missing?
SELECT f.flight_id, f.flight_number, COUNT(b.booking_id) AS bookings
FROM   flights f
INNER JOIN bookings b ON b.flight_id = f.flight_id
GROUP BY f.flight_id, f.flight_number
ORDER BY f.flight_id;

-- 5.2a-3 Q: How many flights does the INNER JOIN exclude?
SELECT (SELECT COUNT(DISTINCT f.flight_id) FROM flights f
        LEFT JOIN  bookings b ON b.flight_id = f.flight_id) AS flights_left_join,
       (SELECT COUNT(DISTINCT f.flight_id) FROM flights f
        INNER JOIN bookings b ON b.flight_id = f.flight_id) AS flights_inner_join,
       (SELECT COUNT(DISTINCT f.flight_id) FROM flights f
        LEFT JOIN  bookings b ON b.flight_id = f.flight_id)
     - (SELECT COUNT(DISTINCT f.flight_id) FROM flights f
        INNER JOIN bookings b ON b.flight_id = f.flight_id) AS flights_excluded;

-- 5.2a-4 Q: Which flights are they, and what do we know about them?
SELECT f.flight_id, f.flight_number, f.is_active, f.seat_capacity
FROM   flights f
LEFT JOIN bookings b ON b.flight_id = f.flight_id
WHERE  b.booking_id IS NULL
ORDER BY f.flight_id;

-- ---------------- PART B: RIGHT JOIN and FULL OUTER JOIN ----------------

-- 5.2b-1 Q: The Part A LEFT JOIN, rewritten as a RIGHT JOIN (tables swapped).
SELECT f.flight_id, f.flight_number, COUNT(b.booking_id) AS bookings
FROM   bookings b
RIGHT JOIN flights f ON b.flight_id = f.flight_id
GROUP BY f.flight_id, f.flight_number
ORDER BY f.flight_id;

-- 5.2b-2 Q: Do the LEFT and RIGHT versions return identical rows? (verify, don't assume)
--    Both difference counts must be 0, and the row counts must match.
WITH l AS (
    SELECT f.flight_id, f.flight_number, COUNT(b.booking_id) AS bookings
    FROM flights f LEFT JOIN bookings b ON b.flight_id = f.flight_id
    GROUP BY f.flight_id, f.flight_number
), r AS (
    SELECT f.flight_id, f.flight_number, COUNT(b.booking_id) AS bookings
    FROM bookings b RIGHT JOIN flights f ON b.flight_id = f.flight_id
    GROUP BY f.flight_id, f.flight_number
)
SELECT (SELECT COUNT(*) FROM l)                          AS left_rows,
       (SELECT COUNT(*) FROM r)                          AS right_rows,
       (SELECT COUNT(*) FROM (SELECT * FROM l EXCEPT SELECT * FROM r) x) AS only_in_left,
       (SELECT COUNT(*) FROM (SELECT * FROM r EXCEPT SELECT * FROM l) x) AS only_in_right;

-- 5.2b-3 Q: FULL OUTER JOIN of flights and bookings: how many rows fall in each
--    category (matched / flight with no booking / booking with no flight)?
SELECT COUNT(*) FILTER (WHERE f.flight_id IS NOT NULL AND b.booking_id IS NOT NULL) AS matched_rows,
       COUNT(*) FILTER (WHERE b.booking_id IS NULL)                                 AS flights_without_bookings,
       COUNT(*) FILTER (WHERE f.flight_id  IS NULL)                                 AS bookings_without_flight
FROM   flights f
FULL OUTER JOIN bookings b ON b.flight_id = f.flight_id;

-- ---------------- PART C: two ways to find flights with no events ----------------

-- 5.2c-1 NOT EXISTS
SELECT f.flight_id, f.flight_number
FROM   flights f
WHERE  NOT EXISTS (SELECT 1 FROM bookings b WHERE b.flight_id = f.flight_id)
ORDER BY f.flight_id;

-- 5.2c-2 EXCEPT
SELECT flight_id, flight_number FROM flights
EXCEPT
SELECT f.flight_id, f.flight_number
FROM   flights f JOIN bookings b ON b.flight_id = f.flight_id
ORDER BY flight_id;

-- 5.2c-3 Q: Do the two approaches identify the same flights?
WITH ne AS (
    SELECT f.flight_id FROM flights f
    WHERE NOT EXISTS (SELECT 1 FROM bookings b WHERE b.flight_id = f.flight_id)
), ex AS (
    SELECT flight_id FROM flights
    EXCEPT
    SELECT flight_id FROM bookings
)
SELECT (SELECT COUNT(*) FROM ne) AS not_exists_count,
       (SELECT COUNT(*) FROM ex) AS except_count,
       (SELECT COUNT(*) FROM (SELECT * FROM ne EXCEPT SELECT * FROM ex) x) AS only_in_not_exists,
       (SELECT COUNT(*) FROM (SELECT * FROM ex EXCEPT SELECT * FROM ne) x) AS only_in_except;