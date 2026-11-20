-- ============================================================
-- Task 6.1 - Compute across a window without collapsing (Airline Booking)
-- Database: ex603_data
-- Mapping: producer = flights, event = bookings, metric = fare_paid
-- Note: cancelled bookings carry fare_paid = 0 (see Task 4.1a-check), so a
--       plain average per flight is pulled down by cancellations. Where it
--       matters, a "paid only" average (non-cancelled bookings) is shown too.
-- ============================================================

-- 6.1a-1 Q: Is a booking's fare unusual for its own flight? Show every booking
--    next to its flight's average fare, and how far it sits from that average.
--    Requirement: AVG(...) OVER (PARTITION BY ...).
SELECT b.booking_id,
       b.flight_id,
       b.booking_status,
       b.fare_paid,
       ROUND(AVG(b.fare_paid) OVER (PARTITION BY b.flight_id), 2)  AS flight_avg_fare,
       ROUND(b.fare_paid - AVG(b.fare_paid) OVER (PARTITION BY b.flight_id), 2)
                                                                   AS diff_from_flight_avg,
       ROUND(AVG(b.fare_paid) FILTER (WHERE b.booking_status <> 'cancelled')
             OVER (PARTITION BY b.flight_id), 2)                   AS flight_avg_paid_only
FROM   bookings b
ORDER BY b.flight_id, b.booking_id;

-- 6.1a-2 Q: The GROUP BY version of the same average.
--    One row per flight; the individual bookings are gone, so it cannot say
--    which booking is unusual.
SELECT flight_id,
       COUNT(*)                 AS bookings,
       ROUND(AVG(fare_paid), 2) AS flight_avg_fare
FROM   bookings
GROUP BY flight_id
ORDER BY flight_id;

-- 6.1a-3 Q: How many rows does each version return?
SELECT (SELECT COUNT(*) FROM bookings)                                       AS window_version_rows,
       (SELECT COUNT(*) FROM (SELECT flight_id FROM bookings GROUP BY flight_id) g)
                                                                             AS group_by_version_rows;

-- 6.1b Q: If we publish a flight leaderboard by number of bookings, how does the
--    ranking method change who appears where when flights tie?
--    LEFT JOIN so flights with zero bookings still appear (lesson from Unit 5).
--    ROW_NUMBER gets a tie-breaker (flight_id) so its output is repeatable;
--    without it, tied flights would be numbered in an arbitrary order.
WITH counts AS (
    SELECT f.flight_id,
           f.flight_number,
           COUNT(b.booking_id) AS n_events
    FROM   flights f
    LEFT JOIN bookings b ON b.flight_id = f.flight_id
    GROUP BY f.flight_id, f.flight_number
)
SELECT flight_id,
       flight_number,
       n_events,
       ROW_NUMBER() OVER (ORDER BY n_events DESC, flight_id) AS row_num,
       RANK()       OVER (ORDER BY n_events DESC)            AS rnk,
       DENSE_RANK() OVER (ORDER BY n_events DESC)            AS dense_rnk
FROM   counts
ORDER BY n_events DESC, flight_id;
-- Look for rows where rnk repeats: row_num still counts 1,2,3,4...; rnk repeats
-- then skips (1,2,2,4); dense_rnk repeats and does not skip (1,2,2,3).

-- 6.1c Q: Sort flights into four bands by number of bookings, and show what
--    happens to tied flights at a band boundary.
--    NTILE splits by row position, not by value. With 13 flights the bands
--    hold 4, 3, 3, 3 flights (the first band takes the extra one).
WITH counts AS (
    SELECT f.flight_id,
           f.flight_number,
           COUNT(b.booking_id) AS n_events
    FROM   flights f
    LEFT JOIN bookings b ON b.flight_id = f.flight_id
    GROUP BY f.flight_id, f.flight_number
), banded AS (
    SELECT flight_id,
           flight_number,
           n_events,
           RANK()     OVER (ORDER BY n_events DESC)            AS rnk,
           NTILE(4)   OVER (ORDER BY n_events DESC, flight_id) AS band
    FROM   counts
)
SELECT flight_id,
       flight_number,
       n_events,
       rnk,
       band,
       -- TRUE when flights with this same count sit in more than one band:
       (MIN(band) OVER (PARTITION BY n_events)
        <> MAX(band) OVER (PARTITION BY n_events))              AS tie_split_across_bands
FROM   banded
ORDER BY n_events DESC, flight_id;