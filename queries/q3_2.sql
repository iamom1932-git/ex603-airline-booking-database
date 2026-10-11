-- ============================================================
-- Task 3.2 — Find the bug (Airline Booking)
-- Nullable column used: bookings.cancellation_reason (NULL = no reason recorded).
-- The dataset already contains NULLs (166 rows), so nothing was inserted.
-- ============================================================

-- ---------------- PART A: the rows that vanished ----------------

-- 3.2A-0 Table total (the number every other count must reconcile to).
SELECT COUNT(*) AS table_total FROM bookings;

-- 3.2A-1 THE BROKEN QUERY. "Bookings that were not no-shows."
--    Looks exhaustive, but a comparison with NULL is UNKNOWN, so every row
--    with no reason is silently discarded.
SELECT COUNT(*) AS rows_returned
FROM   bookings
WHERE  cancellation_reason != 'Passenger no show';

-- 3.2A-2 Rows the broken query silently omitted:
--    the no-shows (intended exclusion) plus the NULL-reason rows (the bug).
SELECT COUNT(*) FILTER (WHERE cancellation_reason = 'Passenger no show') AS excluded_on_purpose_no_shows,
       COUNT(*) FILTER (WHERE cancellation_reason IS NULL)               AS silently_dropped_null_reason
FROM   bookings;

-- 3.2A-3 Proof the counts do not reconcile: returned + no-shows != total.
SELECT (SELECT COUNT(*) FROM bookings WHERE cancellation_reason != 'Passenger no show') AS returned_by_broken_query,
       (SELECT COUNT(*) FROM bookings WHERE cancellation_reason  = 'Passenger no show') AS no_shows,
       (SELECT COUNT(*) FROM bookings)                                                    AS table_total,
       (SELECT COUNT(*) FROM bookings WHERE cancellation_reason != 'Passenger no show')
     + (SELECT COUNT(*) FROM bookings WHERE cancellation_reason  = 'Passenger no show')   AS returned_plus_no_shows,
       (SELECT COUNT(*) FROM bookings)
     - (SELECT COUNT(*) FROM bookings WHERE cancellation_reason != 'Passenger no show')
     - (SELECT COUNT(*) FROM bookings WHERE cancellation_reason  = 'Passenger no show')   AS unaccounted_for;

-- 3.2A-4 THE REPAIR (explicit IS NULL). Returns every booking that was
--    not a no-show.
SELECT COUNT(*) AS repaired_rows_returned
FROM   bookings
WHERE  cancellation_reason != 'Passenger no show'
   OR  cancellation_reason IS NULL;

-- 3.2A-5 Same repair with COALESCE, plus the full reconciliation:
--    188 not-no-show + 12 no-show = 200 = table total.
SELECT COUNT(*) FILTER (WHERE COALESCE(cancellation_reason, 'No reason provided') != 'Passenger no show') AS not_no_show,
       COUNT(*) FILTER (WHERE cancellation_reason = 'Passenger no show')                                  AS no_show,
       COUNT(*)                                                                                           AS table_total
FROM   bookings;

-- ---------------- PART B: the alias that did not exist yet ----------------

-- 3.2B-1 FAILING QUERY: the alias fare_band is defined in SELECT and used
--    in WHERE. WHERE is evaluated BEFORE SELECT, so the alias does not exist yet.
--    Run it alone to see the error. Verbatim PostgreSQL 16 message:
--      ERROR:  column "fare_band" does not exist
--      LINE 4: WHERE  fare_band = 'High fare';
--      HINT:  Perhaps you meant to reference the column "bookings.fare_paid".
--
--    (Left commented out so the file runs end-to-end without stopping;
--     un-comment and run alone for the screenshot.)
-- SELECT booking_id,
--        CASE WHEN fare_paid >= 30 THEN 'High fare' ELSE 'Other' END AS fare_band
-- FROM   bookings
-- WHERE  fare_band = 'High fare';

-- 3.2B-2 REWRITE 1: repeat the expression in WHERE.
SELECT booking_id,
       CASE WHEN fare_paid >= 30 THEN 'High fare' ELSE 'Other' END AS fare_band
FROM   bookings
WHERE  CASE WHEN fare_paid >= 30 THEN 'High fare' ELSE 'Other' END = 'High fare'
ORDER BY booking_id;

-- 3.2B-3 REWRITE 2: wrap in a CTE so the alias becomes a real column.
WITH banded AS (
    SELECT booking_id,
           CASE WHEN fare_paid >= 30 THEN 'High fare' ELSE 'Other' END AS fare_band
    FROM   bookings
)
SELECT booking_id, fare_band
FROM   banded
WHERE  fare_band = 'High fare'
ORDER BY booking_id;
