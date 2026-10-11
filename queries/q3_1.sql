-- ============================================================
-- Task 3.1 — Establish what the data contains (Airline Booking)
-- Database: ex603_data   Theme filter: is_active = 1 AND seat_capacity >= 180
-- (written as is_active = TRUE because PostgreSQL uses booleans)
-- ============================================================

-- 3.1a Active, high-capacity flights — the producers whose records
--    anchor the audit. Requirement: SELECT, WHERE, ORDER BY, LIMIT.
SELECT flight_id, flight_number, seat_capacity
FROM   flights
WHERE  is_active = TRUE
  AND  seat_capacity >= 180
ORDER BY seat_capacity DESC, flight_id
LIMIT 10;

-- 3.1b What booking statuses exist, and how many bookings has each?
--    Requirement: DISTINCT / GROUP BY.
SELECT DISTINCT booking_status
FROM   bookings
ORDER BY booking_status;

-- 3.1b (cont.) Same question with counts. Finding: only THREE statuses
--    (confirmed, cancelled, disputed). There is NO 'no_show' status, so a
--    no-show can only be found in cancellation_reason.
SELECT booking_status, COUNT(*) AS bookings
FROM   bookings
GROUP BY booking_status
ORDER BY bookings DESC;

-- 3.1b (cont.) Which reasons exist? Finding: 'Passenger no show' is one of
--    four reasons, and NULL (no reason) is by far the largest group.
SELECT cancellation_reason, COUNT(*) AS bookings
FROM   bookings
GROUP BY cancellation_reason
ORDER BY bookings DESC;

-- 3.1c-1 Filter a numeric range: mid-priced fares between 20 and 50.
--    Requirement: BETWEEN.
SELECT booking_id, flight_id, fare_paid
FROM   bookings
WHERE  fare_paid BETWEEN 20 AND 50
ORDER BY fare_paid DESC, booking_id;

-- 3.1c-2 Filter with an explicit list: bookings made in Japan or Korea.
--    Requirement: IN.
SELECT booking_id, booking_country, booking_status, fare_paid
FROM   bookings
WHERE  booking_country IN ('Japan', 'Korea')
ORDER BY booking_id;

-- 3.1d-1 Flights whose number matches a text pattern (VN21x series).
--    Requirement: LIKE.
SELECT flight_id, flight_number, seat_capacity
FROM   flights
WHERE  flight_number LIKE 'VN21%'
ORDER BY flight_number;

-- 3.1d-2 Bookings with a missing cancellation reason, relabelled in plain
--    language. Requirement: IS NULL, COALESCE.
SELECT booking_id,
       booking_status,
       COALESCE(cancellation_reason, 'No reason provided') AS reason_label
FROM   bookings
WHERE  cancellation_reason IS NULL
ORDER BY booking_id
LIMIT 15;

-- 3.1e Bookings a non-SQL reader can understand: fare band, time of day,
--    check-in outcome and a plain-language no-show flag.
--    Requirement: computed columns, CASE.
SELECT b.booking_id,
       f.flight_number,
       b.fare_paid,
       CASE WHEN b.fare_paid = 0  THEN 'No fare paid'
            WHEN b.fare_paid < 10 THEN 'Low fare (under 10)'
            WHEN b.fare_paid < 30 THEN 'Mid fare (10-29.99)'
            ELSE                       'High fare (30+)' END         AS fare_band,
       CASE WHEN EXTRACT(HOUR FROM b.booked_at) BETWEEN 5  AND 11 THEN 'Morning'
            WHEN EXTRACT(HOUR FROM b.booked_at) BETWEEN 12 AND 17 THEN 'Afternoon'
            WHEN EXTRACT(HOUR FROM b.booked_at) BETWEEN 18 AND 22 THEN 'Evening'
            ELSE 'Overnight' END                                      AS booked_time_of_day,
       CASE WHEN b.checked_in_at IS NOT NULL THEN 'Checked in'
            ELSE 'Did not check in' END                               AS check_in_result,
       CASE WHEN b.cancellation_reason = 'Passenger no show' THEN 'No-show'
            WHEN b.booking_status = 'cancelled'              THEN 'Cancelled (other reason)'
            WHEN b.booking_status = 'disputed'               THEN 'Disputed'
            ELSE 'Travelled / confirmed' END                          AS plain_outcome,
       ROUND(b.fare_paid * b.fare_multiplier, 2)                      AS fare_with_multiplier
FROM   bookings b
JOIN   flights  f ON f.flight_id = b.flight_id
ORDER BY b.booking_id
LIMIT 20;
