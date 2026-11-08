-- ============================================================
-- Task 5.1 - Connect Producers to Their Data (Airline Booking)
-- Database: ex603_data
-- Mapping: producer = flights, actor = passengers, event = bookings,
--          catalog = airports, junction = flight_routes.
-- Assignment 4 flagged flights: 11, 2, 6 (watch list: 9).
-- ============================================================

-- 5.1a Q: Who are the people behind the events? For each booking, which
--    passenger made it, which flight (producer) is it on, and when was it booked?
--    Requirement: three-table INNER JOIN.
SELECT b.booking_id,
       p.passenger_id,
       p.passenger_name,
       f.flight_id,
       f.flight_number,
       b.booked_at,
       b.booking_status
FROM   bookings   b
JOIN   passengers p ON p.passenger_id = b.passenger_id
JOIN   flights    f ON f.flight_id    = b.flight_id
ORDER BY b.booked_at, b.booking_id
LIMIT 25;

-- 5.1b Q: Which airports (catalog records) are connected to the theme flights
--    (active, capacity >= 180), and are the Assignment 4 flights among them?
--    Requirement: producer -> junction -> catalog traversal.
SELECT f.flight_id,
       f.flight_number,
       f.seat_capacity,
       a.airport_id,
       a.name AS airport_name,
       CASE WHEN f.flight_id IN (2, 6, 11) THEN 'Flagged in Assignment 4'
            WHEN f.flight_id = 9           THEN 'Watch list'
            ELSE '' END AS assignment4_status
FROM   flights       f
JOIN   flight_routes fr ON fr.flight_id  = f.flight_id
JOIN   airports      a  ON a.airport_id  = fr.airport_id
WHERE  f.is_active = TRUE
  AND  f.seat_capacity >= 180
ORDER BY f.flight_id, a.airport_id;

-- 5.1b-2 Q: Do the flagged flights share airports with each other?
--    Self join on the junction table: pairs of flagged flights using the same airport.
SELECT a.name AS shared_airport,
       r1.flight_id AS flight_a,
       r2.flight_id AS flight_b
FROM   flight_routes r1
JOIN   flight_routes r2 ON r2.airport_id = r1.airport_id
                       AND r2.flight_id  > r1.flight_id
JOIN   airports      a  ON a.airport_id  = r1.airport_id
WHERE  r1.flight_id IN (2, 6, 11)
  AND  r2.flight_id IN (2, 6, 11)
ORDER BY a.name, r1.flight_id, r2.flight_id;

-- 5.1c Q: How do the flagged flights compare with every other flight in size and
--    activity? Requirement: self join (the per-flight summary joined to itself).
--    LEFT JOIN to bookings so flights with zero bookings still get a row.
WITH flight_stats AS (
    SELECT f.flight_id,
           f.flight_number,
           f.is_active,
           f.seat_capacity,
           COUNT(b.booking_id) AS bookings,
           COUNT(*) FILTER (WHERE b.booking_status = 'cancelled') AS failures
    FROM   flights f
    LEFT JOIN bookings b ON b.flight_id = f.flight_id
    GROUP BY f.flight_id, f.flight_number, f.is_active, f.seat_capacity
)
SELECT s1.flight_id                            AS flagged_flight,
       s2.flight_id                            AS compared_with,
       s1.seat_capacity                        AS flagged_capacity,
       s2.seat_capacity                        AS other_capacity,
       (s1.seat_capacity = s2.seat_capacity)   AS same_capacity,
       (s1.is_active     = s2.is_active)       AS same_active_status,
       s1.bookings                             AS flagged_bookings,
       s2.bookings                             AS other_bookings,
       ROUND(100.0 * s1.failures / NULLIF(s1.bookings, 0), 1) AS flagged_fail_pct,
       ROUND(100.0 * s2.failures / NULLIF(s2.bookings, 0), 1) AS other_fail_pct
FROM   flight_stats s1
JOIN   flight_stats s2 ON s2.flight_id <> s1.flight_id
WHERE  s1.flight_id IN (2, 6, 11)
ORDER BY s1.flight_id, s2.flight_id;
