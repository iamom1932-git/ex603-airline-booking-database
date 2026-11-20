-- ============================================================
-- Task 6.2 - Compare each row to its neighbours (Airline Booking)
-- Database: ex603_data
-- Mapping: producer = flights, event = bookings, metric = fare_paid
-- ============================================================

-- ---------------- PART A: row to row ----------------

-- 6.2A Q: For Flight 6 (the busiest flight, flagged in Unit 4), is the fare
--    paid going up or down from one booking to the next, in time order?
--    Requirement: LAG, LEAD, a delta column, one producer in the final output.
--    booking_id is a tie-breaker so bookings with the same timestamp keep a fixed order.
--    A fare of 0.00 is a cancelled booking, so booking_status is shown beside it:
--    a delta caused by a cancellation is not a price trend.
--    (WHERE runs before the window, so filtering to one flight here is safe:
--    the window is partitioned by flight and never needs the other flights' rows.)
SELECT b.flight_id,
       b.booking_id,
       b.booked_at,
       b.booking_status,
       b.fare_paid,
       LAG(b.fare_paid)  OVER w                AS prev_fare,
       LEAD(b.fare_paid) OVER w                AS next_fare,
       b.fare_paid - LAG(b.fare_paid) OVER w   AS delta
FROM   bookings b
WHERE  b.flight_id = 6
WINDOW w AS (PARTITION BY b.flight_id ORDER BY b.booked_at, b.booking_id)
ORDER BY b.booked_at, b.booking_id;

-- ---------------- PART B: cumulative and smoothed ----------------

-- 6.2B-1 Q: How is the platform doing over time: the running total of fares, how
--    close it is to the target, and the recent 7-day average?
--    TARGET: set below.
--    The daily series is built on a full calendar (generate_series) so days
--    with no bookings appear as zero; that makes "6 PRECEDING" exactly 7 days.
--    (On bookings-only days, ROWS counts rows, not days, and a 7-row window
--    would stretch over more than 7 days.)
WITH params AS (
    SELECT 4000::numeric AS target_total_fare
), bounds AS (
    SELECT MIN(booked_at)::date AS first_day,
           MAX(booked_at)::date AS last_day
    FROM   bookings
), calendar AS (
    SELECT d::date AS day
    FROM   bounds, generate_series(bounds.first_day, bounds.last_day, INTERVAL '1 day') AS d
), daily AS (
    SELECT c.day,
           COUNT(b.booking_id)                                       AS bookings,
           COUNT(b.booking_id) FILTER (WHERE b.booking_status = 'cancelled') AS failures,
           COALESCE(SUM(b.fare_paid), 0)                             AS fares
    FROM   calendar c
    LEFT JOIN bookings b ON b.booked_at::date = c.day
    GROUP BY c.day
)
SELECT d.day,
       d.bookings,
       d.failures,
       d.fares,
       SUM(d.fares) OVER (ORDER BY d.day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)        AS running_total_fares,
       ROUND(100.0 * SUM(d.fares) OVER (ORDER BY d.day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            / p.target_total_fare, 1)                                AS pct_of_target,
       ROUND(AVG(d.fares) OVER (ORDER BY d.day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2)            AS moving_avg_fares_7d,
       ROUND(100.0 * SUM(d.failures) OVER (ORDER BY d.day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
            / NULLIF(SUM(d.bookings) OVER (ORDER BY d.day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 0), 1)        AS failure_rate_7d_pct
FROM   daily d
CROSS JOIN params p
ORDER BY d.day;

-- 6.2B-2 Q: How many calendar days have no bookings at all? (Why the calendar
--    version above is needed.)
SELECT COUNT(DISTINCT booked_at::date)                                 AS days_with_bookings,
       (MAX(booked_at)::date - MIN(booked_at)::date) + 1               AS calendar_days,
       (MAX(booked_at)::date - MIN(booked_at)::date) + 1
         - COUNT(DISTINCT booked_at::date)                             AS days_without_bookings
FROM   bookings;

-- ---------------- PART C: where the series stops ----------------

-- 6.2C Q: Which flights go quiet for a long stretch and then get booked again?
--    The gap is computed in a CTE with LAG; WHERE in the outer query keeps only the gaps
--    (a window function result cannot be filtered in the same query level).
--    TODO: tune the threshold (14 days here) after looking at the largest gaps.
--    prev_booking_id / booking_id are shown so you can check the IDs either side
--    of the gap: consecutive IDs suggest nothing was deleted, missing IDs
--    suggest rows were lost. Also check whether the flight is_active.
WITH ordered AS (
    SELECT b.flight_id,
           b.booking_id,
           b.booked_at,
           LAG(b.booking_id) OVER w                  AS prev_booking_id,
           LAG(b.booked_at)  OVER w                  AS prev_booked_at
    FROM   bookings b
    WINDOW w AS (PARTITION BY b.flight_id ORDER BY b.booked_at, b.booking_id)
)
SELECT o.flight_id,
       f.flight_number,
       f.is_active,
       o.prev_booking_id,
       o.prev_booked_at,
       o.booking_id,
       o.booked_at,
       (o.booked_at::date - o.prev_booked_at::date)  AS gap_days
FROM   ordered o
JOIN   flights f ON f.flight_id = o.flight_id
WHERE  o.prev_booked_at IS NOT NULL
  AND  (o.booked_at::date - o.prev_booked_at::date) >= 14
ORDER BY gap_days DESC, o.flight_id;

-- 6.2C-2 Q: During the single largest gap, were OTHER flights still being booked?
--    Yes  -> the platform kept recording bookings, so the quiet flight is a real
--            stop or a flight-specific recording problem.
--    No   -> the whole platform went quiet, which points to the data feed or load.
WITH ordered AS (
    SELECT b.flight_id, b.booked_at,
           LAG(b.booked_at) OVER (PARTITION BY b.flight_id ORDER BY b.booked_at, b.booking_id) AS prev_booked_at
    FROM   bookings b
), biggest AS (
    SELECT flight_id, prev_booked_at, booked_at
    FROM   ordered
    WHERE  prev_booked_at IS NOT NULL
    ORDER BY (booked_at::date - prev_booked_at::date) DESC, flight_id
    LIMIT 1
)
SELECT bg.flight_id                                                           AS gap_flight,
       bg.prev_booked_at,
       bg.booked_at                                                           AS resumed_at,
       COUNT(b.booking_id) FILTER (WHERE b.flight_id =  bg.flight_id)         AS this_flight_bookings_in_gap,
       COUNT(b.booking_id) FILTER (WHERE b.flight_id <> bg.flight_id)         AS other_flight_bookings_in_gap,
       COUNT(DISTINCT b.flight_id) FILTER (WHERE b.flight_id <> bg.flight_id) AS other_flights_booked_in_gap
FROM   biggest bg
LEFT JOIN bookings b ON b.booked_at > bg.prev_booked_at AND b.booked_at < bg.booked_at
GROUP BY bg.flight_id, bg.prev_booked_at, bg.booked_at;

-- 6.2C-3 Q: Are any booking IDs missing from the table as a whole?
--    booking_id is an identity column, so unexplained holes in the sequence can
--    mean rows were deleted or never loaded. (No holes does not prove nothing
--    was lost upstream, it only rules out deletion inside this table.)
SELECT MIN(booking_id)                              AS first_id,
       MAX(booking_id)                              AS last_id,
       COUNT(*)                                     AS rows_present,
       (MAX(booking_id) - MIN(booking_id) + 1) - COUNT(*) AS missing_ids
FROM   bookings;