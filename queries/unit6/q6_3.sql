-- ============================================================
-- Task 6.3 - Build the reporting patterns (Airline Booking)
-- Database: ex603_data
-- Mapping: producer = flights, event = bookings, metric = fare_paid
-- ============================================================

-- ---------------- PART A: top N per category ----------------

-- 6.3A Q: What are the three highest-fare bookings on each flight, and how does each
--    compare with that flight's best?
--    TIES AT THIRD PLACE: ROW_NUMBER with an explicit tie-breaker (earlier
--    booked_at, then lower booking_id). A "top 3" list has three slots, so it
--    must return exactly three rows per flight; the tie-breaker makes the choice
--    repeatable instead of arbitrary. RANK or DENSE_RANK would keep every tied
--    booking and could return more than three rows. Fares repeat a lot, so
--    ties are expected. Flights with fewer than 3 bookings return fewer rows.
--    FIRST_VALUE gives the flight's top fare (its default frame is fine for
--    FIRST_VALUE; LAST_VALUE would need ROWS BETWEEN UNBOUNDED PRECEDING AND
--    UNBOUNDED FOLLOWING).
WITH ranked AS (
    SELECT b.flight_id,
           b.booking_id,
           b.booked_at,
           b.fare_paid,
           ROW_NUMBER() OVER w                    AS rn,
           FIRST_VALUE(b.fare_paid) OVER w        AS flight_top_fare
    FROM   bookings b
    WINDOW w AS (PARTITION BY b.flight_id
                 ORDER BY b.fare_paid DESC, b.booked_at, b.booking_id)
)
SELECT flight_id,
       rn          AS rank_in_flight,
       booking_id,
       booked_at,
       fare_paid,
       flight_top_fare,
       ROUND(100.0 * fare_paid / NULLIF(flight_top_fare, 0), 1) AS pct_of_flight_top
FROM   ranked
WHERE  rn <= 3
ORDER BY flight_id, rn;

-- 6.3A-check Q: Where did the tie-breaker actually matter, i.e. is the 3rd fare
--    shared with a 4th booking that was left out?
WITH ranked AS (
    SELECT flight_id, booking_id, fare_paid,
           ROW_NUMBER() OVER (PARTITION BY flight_id ORDER BY fare_paid DESC, booked_at, booking_id) AS rn
    FROM   bookings
)
SELECT t.flight_id,
       t.fare_paid                      AS third_place_fare,
       COUNT(*) FILTER (WHERE r.rn > 3) AS tied_bookings_left_out
FROM   ranked t
JOIN   ranked r ON r.flight_id = t.flight_id AND r.fare_paid = t.fare_paid
WHERE  t.rn = 3
GROUP BY t.flight_id, t.fare_paid
HAVING COUNT(*) FILTER (WHERE r.rn > 3) > 0
ORDER BY t.flight_id;

-- ---------------- PART B: period over period ----------------

-- 6.3B-1 Q: Is the platform's failure rate getting better or worse month by month?
--    Failure = booking_status = 'cancelled' (as in Unit 4).
--    LAG counts rows, not months, so prev_month is compared with the expected
--    previous month: month_is_consecutive = FALSE means the % change is
--    comparing months that are not adjacent. NULLIF avoids division by zero.
--    Bookings per month are shown because small months make noisy rates.
--    CAUTION: the first and last months may be partial (data starting or ending mid-month).
--    A rate on a handful of bookings can swing wildly; check bookings and the
--    min/max booked_at before treating the latest change as a trend.
WITH monthly AS (
    SELECT DATE_TRUNC('month', booked_at)                              AS month,
           COUNT(*)                                                    AS bookings,
           COUNT(*) FILTER (WHERE booking_status = 'cancelled')        AS failures,
           ROUND(100.0 * COUNT(*) FILTER (WHERE booking_status = 'cancelled')
                 / COUNT(*), 1)                                        AS failure_rate_pct
    FROM   bookings
    GROUP BY DATE_TRUNC('month', booked_at)
), compared AS (
    SELECT month, bookings, failures, failure_rate_pct,
           LAG(month)            OVER (ORDER BY month) AS prev_month,
           LAG(failure_rate_pct) OVER (ORDER BY month) AS prev_rate_pct
    FROM   monthly
)
SELECT month::date                                                     AS month,
       bookings,
       failures,
       failure_rate_pct,
       prev_rate_pct,
       ROUND(failure_rate_pct - prev_rate_pct, 1)                      AS change_pct_points,
       ROUND(100.0 * (failure_rate_pct - prev_rate_pct)
             / NULLIF(prev_rate_pct, 0), 1)                            AS pct_change,
       (prev_month = month - INTERVAL '1 month')                       AS month_is_consecutive
FROM   compared
ORDER BY month;

-- 6.3B-2 Q: Which calendar months between the first and last booking have no
--    bookings at all? (A month missing from the series is invisible to LAG.)
WITH bounds AS (
    SELECT DATE_TRUNC('month', MIN(booked_at)) AS first_month,
           DATE_TRUNC('month', MAX(booked_at)) AS last_month
    FROM   bookings
)
SELECT m::date AS missing_month
FROM   bounds, generate_series(bounds.first_month, bounds.last_month, INTERVAL '1 month') AS m
WHERE  NOT EXISTS (SELECT 1
                   FROM   bookings b
                   WHERE  DATE_TRUNC('month', b.booked_at) = m)
ORDER BY m;