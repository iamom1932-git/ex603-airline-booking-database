-- ============================================================
-- Task 3.3 - Hand the team a corrected query (Airline Booking)
-- Question: which passengers were involved in disputed bookings?
-- ============================================================

-- 3.3a FORM 1 - subquery with IN.
SELECT passenger_id, passenger_name
FROM   passengers
WHERE  passenger_id IN (SELECT passenger_id
                        FROM   bookings
                        WHERE  booking_status = 'disputed')
ORDER BY passenger_id;

-- 3.3b FORM 2 - Common Table Expression (WITH) + join.
WITH disputed_passengers AS (
    SELECT DISTINCT passenger_id
    FROM   bookings
    WHERE  booking_status = 'disputed'
)
SELECT p.passenger_id, p.passenger_name
FROM   passengers p
JOIN   disputed_passengers d ON d.passenger_id = p.passenger_id
ORDER BY p.passenger_id;

-- 3.3c FORM 3 - correlated EXISTS (a different subquery form).
SELECT p.passenger_id, p.passenger_name
FROM   passengers p
WHERE  EXISTS (SELECT 1
               FROM   bookings b
               WHERE  b.passenger_id = p.passenger_id
                 AND  b.booking_status = 'disputed')
ORDER BY p.passenger_id;

-- 3.3d PROOF THE ROWS MATCH (not just the counts).
--   Every pairwise difference must be empty, and the three fingerprints
--   (count + hash of the ordered rows) must be identical.
WITH f1 AS (
    SELECT passenger_id, passenger_name FROM passengers
    WHERE  passenger_id IN (SELECT passenger_id FROM bookings WHERE booking_status = 'disputed')
), f2 AS (
    WITH disputed_passengers AS (
        SELECT DISTINCT passenger_id FROM bookings WHERE booking_status = 'disputed')
    SELECT p.passenger_id, p.passenger_name
    FROM   passengers p JOIN disputed_passengers d ON d.passenger_id = p.passenger_id
), f3 AS (
    SELECT p.passenger_id, p.passenger_name FROM passengers p
    WHERE  EXISTS (SELECT 1 FROM bookings b
                   WHERE b.passenger_id = p.passenger_id AND b.booking_status = 'disputed')
)
SELECT 'rows only in IN-form, not CTE'    AS check_name, COUNT(*) AS rows FROM (SELECT * FROM f1 EXCEPT SELECT * FROM f2) x
UNION ALL SELECT 'rows only in CTE, not IN-form',      COUNT(*) FROM (SELECT * FROM f2 EXCEPT SELECT * FROM f1) x
UNION ALL SELECT 'rows only in IN-form, not EXISTS',   COUNT(*) FROM (SELECT * FROM f1 EXCEPT SELECT * FROM f3) x
UNION ALL SELECT 'rows only in EXISTS, not IN-form',   COUNT(*) FROM (SELECT * FROM f3 EXCEPT SELECT * FROM f1) x
UNION ALL SELECT 'IN-form fingerprint: ' || COUNT(*) || ' rows, hash ' || MD5(STRING_AGG(passenger_id || passenger_name, '|' ORDER BY passenger_id)), 0 FROM f1
UNION ALL SELECT 'CTE fingerprint:     ' || COUNT(*) || ' rows, hash ' || MD5(STRING_AGG(passenger_id || passenger_name, '|' ORDER BY passenger_id)), 0 FROM f2
UNION ALL SELECT 'EXISTS fingerprint:  ' || COUNT(*) || ' rows, hash ' || MD5(STRING_AGG(passenger_id || passenger_name, '|' ORDER BY passenger_id)), 0 FROM f3;

-- 3.3e WHERE EQUIVALENCE BREAKS: NULLs in the subquery column (NOT IN), and duplicates (JOIN).
--   (i) NULL: the NOT IN version of this question returns ZERO rows as soon as the
--       subquery contains one NULL, while NOT EXISTS still returns the right rows.
--       passengers.referred_by is nullable, so it demonstrates this directly:
SELECT 'NOT IN (list has NULLs)' AS form, COUNT(*) AS rows
FROM   passengers
WHERE  passenger_id NOT IN (SELECT referred_by FROM passengers)
UNION ALL
SELECT 'NOT EXISTS', COUNT(*)
FROM   passengers p
WHERE  NOT EXISTS (SELECT 1 FROM passengers r WHERE r.referred_by = p.passenger_id);
--   (ii) Duplicates: a plain JOIN (no DISTINCT) to bookings returns one row per
--       disputed booking, not per passenger, so it can return more rows than IN / EXISTS.
SELECT 'plain JOIN, no DISTINCT' AS form, COUNT(*) AS rows
FROM   passengers p JOIN bookings b ON b.passenger_id = p.passenger_id AND b.booking_status = 'disputed'
UNION ALL
SELECT 'IN form', COUNT(*)
FROM   passengers WHERE passenger_id IN (SELECT passenger_id FROM bookings WHERE booking_status = 'disputed');
