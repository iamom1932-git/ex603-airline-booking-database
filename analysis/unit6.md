# Unit 6 Analysis

Mapping used throughout: producer = flight, actor = passenger, event = booking, metric = `fare_paid`, failure = `booking_status = 'cancelled'`.

## Task 6.1: Compute across a window without collapsing

**A question that needs each row next to its group's average.** Which individual bookings paid far more or far less than is normal for their own flight, so a fares analyst can review them? The question is about a booking, but the yardstick is the flight's average. `GROUP BY flight_id` returns one row per flight (13 rows from `6.1a-2`), so the bookings disappear and nobody can say which one was unusual. The window version keeps all 200 rows and puts the flight average on each (`6.1a-1`). One caveat: cancelled bookings carry a fare of 0.00, so a flight with many cancellations has a low average, which is why `6.1a-1` also shows the average over paid bookings only.

**Ranking is never neutral.** Feature: a "most-booked flights" leaderboard shown to the commercial team, which decides where to add capacity or promotion. It should use `RANK()`. In my data Flights 2 and 11 tie on 15 bookings. `ROW_NUMBER()` would put one above the other only because of the tie-breaker I chose (`flight_id`), and that flight would look better for no reason in the data. `DENSE_RANK()` would call both second but also make the next flight third, hiding that two flights are ahead of it. `RANK()` shows the tie honestly (both 2nd) and the next flight is 4th, which matches how many flights really outrank it. `ROW_NUMBER()` is the right choice only when exactly one record per slot is needed (for example "pick one flight to review today").

**NTILE and ties.** `NTILE(4)` splits by row position, not by value. [13] flights make bands of 4, 3, 3 and 3. Where tied flights straddle a boundary ([flights and counts from `tie_split_across_bands = true`]), they have the same booking count but land in different bands, and which band each gets depends on the tie-breaker. A band label built this way should not be published as a statement about the flights' size.

## Task 6.2: Compare each row to its neighbours

**Part A: a large delta.** On Flight 6, a delta of -42.02 appears where booking_id 66 was cancelled (fare 0.00). A large delta in this platform is usually not a price change. It is a cancellation between two paid bookings, or a switch between fare classes. Someone reading it should first check `booking_status` and `cancellation_reason` on the row. If several large drops cluster in time, the operations team should look at what happened on the flight in that period (cancelled departures, payment problems), not at pricing.

**Part B: running total.** A plain `SUM` gives one number: where we are. A running total shows how we got there and when. It answers "are we on pace for the target?" at any date, and it shows when the pace changed. **Target:** 4,000.00. The final running total is 3628.19, which is 90.7% of target (`6.2B-1`).

**ROWS vs RANGE.** `ROWS` counts physical rows, so rows with the same `ORDER BY` value are handled one at a time. `RANGE` treats rows with equal `ORDER BY` values as peers and puts them all in the frame together, so tied rows get the same running total.

**Window size.** I used 7 days because bookings have a weekly rhythm and one week smooths daily noise without hiding a month-long shift. A 3-day window would swing with single cancellations and show many false alarms. A 30-day window would be smooth but would react to a real deterioration weeks late. With only [200] bookings over 362 days (0.55 bookings a day), even 7 days holds few bookings, so I read the 7-day failure rate as a rough direction, not a precise value. The calendar-filled series makes `6 PRECEDING` mean exactly 7 days; `6.2B-2` shows 207 of 362 calendar days have no bookings, so a 7-row window on bookings-only days would have covered much more than a week.

**Part C: the gap.** [Flight X] has no bookings from [date] to [date], [n] days, and then resumes. What the checks say:
- `6.2C-2`: during the gap, [n] bookings were made on [n] other flights, so [the platform kept recording / the whole platform went quiet].
- `6.2C-3`: booking IDs run [1 to 200 with 0 missing / have n holes], so [nothing was deleted from this table / rows are missing].
- `is_active` for the flight is [TRUE/FALSE].

My conclusion: [pick one and justify with the three checks above.]
- *Data quality problem* if the whole platform is quiet or IDs are missing: re-check the load, ask who supplied the data.
- *Real stop in activity* if other flights kept booking, IDs are intact and the flight was inactive or not on sale: ask scheduling.
- *Recording side effect* if the flight kept operating but its bookings were recorded elsewhere or under another flight number: ask the booking-system owners.

## Task 6.3: Build the reporting patterns

**Top N per category.** Feature: a "highest-value bookings per flight" review list for the revenue team to spot fare-class mix-ups or unusual high fares. Three is the right number because it gives enough to see whether the top fare is an outlier (compare #1 with #2 and #3) while staying short enough to read per flight. One shows only a single value, which can be a typo. Ten is more than many flights have: a flight with [5] bookings would list all of them, and the list would stop being a "top". **Ties at third place:** `ROW_NUMBER()` with a tie-breaker (earlier booking first) keeps exactly three rows per flight. Fares repeat a lot, so ties are common: `6.3A-check` finds 0 flights where a booking with the same fare as the 3rd was left out.

**Month over month.** A large change in the monthly failure rate would mean something changed in how bookings end up: a new problem on a route, a payment issue, or a batch of cancelled departures. The action is to break that month's failures down by `cancellation_reason` and `flight_id` and hand the largest cause to its owner (operations for flight cancellations, payments for payment failures). Before acting, check the month's booking count: with about [40] bookings a month, a change of 2 failures moves the rate by 5 points. **Missing months:** `6.3B-2` shows [no missing months / April missing]. `month_is_consecutive = false` marks a row where `LAG` compared with a non-adjacent month, so that % change is not a month-over-month change. The first and last months may also be partial, so I do not treat them as trends.

## Reflection

Window functions keep rows; aggregates collapse them. On my airline platform, a question that is easy with a window function and awkward with `GROUP BY` is: after a passenger's booking is cancelled, how long until that same passenger books again? Answering it means looking at each passenger's bookings in time order and, for every cancelled booking, finding the next booking by the same person. `LEAD(booked_at) OVER (PARTITION BY passenger_id ORDER BY booked_at)` returns that next date on the cancelled row, and subtracting `booked_at` gives the number of days. It leaves every booking visible, so a retention analyst can sort by the days, filter to cancellations, and look at the reasons.

`GROUP BY passenger_id` cannot do this because an aggregate collapses a passenger's bookings into one value such as `MAX(booked_at)` or `COUNT(*)`. It can say when a passenger last booked, but not which booking followed which, because order between rows is exactly what a collapsed group no longer has. A self join on `booked_at > cancelled.booked_at` plus a `MIN` could approximate it, but it needs a join, a subquery for the "next" booking, and extra care with ties and passengers with no later booking. The window version states the question in one line, which makes it easier to check and less likely to hide a bug.
