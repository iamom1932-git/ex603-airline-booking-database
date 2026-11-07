# Unit 5 Analysis

Mapping used throughout: producer = flight, actor = passenger, event = booking, catalog = airport, junction = `flight_routes`.
Items in **[brackets]** are numbers or IDs to copy from your own result sets after running the queries on `ex603_data`.

## Task 5.1

**Three-table join (Q1).** This is the shape of an operations "booking activity" screen: one row per booking showing who booked (passenger name), on which flight (flight number), and when. A customer-service agent could use it to look up a passenger's bookings, and the Network Performance team could use it to see who was on the bookings of the flagged flights (2, 6, 11).

**Why the junction table matters (Q2).** A flight can serve many airports and an airport can serve many flights. `flight_routes` holds one row per flight-airport pair, so the join stays clean. Without it, we would have to store a list of airports inside each flight row, which can't be joined, filtered or kept consistent, or repeat flight columns once per airport. Both make "which flights share an airport?" very hard to answer reliably.

**What the self joins showed.** [Do the flagged flights share airports with each other (5.1b-2)? Do they differ from other flights in capacity or booking volume (5.1c)? State only what the rows show.]

## Task 5.2

**Flights excluded by the inner join:** [IDs from 5.2a-4]. The inner join returned [n] flights against [n] for the left join, so it excluded [n]. These flights exist in `flights` but have no row in `bookings`, so there was nothing to match.

**RIGHT vs LEFT (Part B).** The RIGHT JOIN is the LEFT JOIN with the tables swapped. I verified this: both queries return [n] rows and the EXCEPT checks in both directions return 0. The FULL OUTER JOIN adds a check on the other side: it reports [n] bookings with no flight. A left join alone can't show orphans on the right side. Here that number should be 0, because the foreign key on `bookings.flight_id` forbids them, so the full join confirms the data is clean.

**NOT EXISTS vs EXCEPT (Part C).** NOT EXISTS tests, flight by flight, whether any booking exists. EXCEPT subtracts the set of flights that have bookings from the set of all flights. Both returned [same flights / n], confirmed by the 5.2c-3 difference counts of 0 and 0.

**What it means when a flight has no bookings.** It has never been booked. Possible explanations: it is inactive or newly scheduled, it was never put on sale, its fare or route setup is wrong, it duplicates another flight number, or it is test data.

**How an inner-join report misleads.** Any "flights and their performance" report built on an inner join silently drops the flights with no bookings. Leadership would see a platform with fewer flights than it actually has, and averages and failure rates would describe only the flights that sell.

**Why identify never-booked flights.** They represent supply that earns nothing, and they are invisible in Unit 4's analysis. Leadership can tell a flight that needs help from one that should be retired.

**Action.** Review each never-booked flight with the scheduling team and either launch it properly, fix the listing, or retire it.

**Shown by the data vs. needs investigation.**
- *Data shows:* which flights have zero bookings, whether they are active, and their capacity.
- *Needs investigation:* why. The data cannot say whether a flight was never on sale, is mispriced, or is simply new. That needs scheduling and commercial records.

## Task 5.3

**Cartesian product on this platform.** Useful: generating every flight-by-airport combination to find routes that are not yet offered, or building a flight-by-month grid so months with zero bookings still appear in a report. It signals a bug when a join is missing its ON clause: flights x airports returns [rows] rows ([flights] x [airports]) and every one is meaningless if I wanted real routes.

**Join algorithms chosen:** [e.g. Hash Join / Nested Loop / Merge Join, copy from your plan, with the node order].

**What in the plan explains it.** [Quote the estimated `rows=` for each scan, the `Seq Scan` vs `Index Scan` nodes, and the `Hash` / `Memory Usage` line.] With tables this small, PostgreSQL usually scans fully and builds an in-memory hash table on the smaller side, because that is cheaper than any index lookup.

**Why knowing the algorithm is useful.** The algorithm tells you how cost will grow. A hash join grows roughly with the sum of the table sizes, a nested loop with their product unless an index is used, and a merge join needs sorted input.

**What would change it.** See the reflection.

**Which part will slow down first.** The scan of `bookings`, the high-volume table, and the final sort on `booked_at`, since the sort has no supporting index.

## Reflection

PostgreSQL picks a join algorithm by estimating cost from table statistics, so changing the data changes the choice. On 200 bookings, 30-odd passengers and a dozen flights, everything fits in memory and a hash join over sequential scans is cheapest. If `bookings` grew to millions of rows while `flights` stayed tiny, the hash table would still be built on `flights`, but the big scan would dominate. A hash table that no longer fits in `work_mem` spills to disk and slows sharply, and PostgreSQL might switch to a merge join if both inputs were already sorted, for example through an index on `bookings(flight_id)`.

Indexes matter most when the filter is selective. If I looked up one passenger's bookings, an index on `bookings(passenger_id)` would let PostgreSQL use a nested loop with index lookups, touching a handful of rows rather than scanning the table. The number of matching rows matters too: a join that returns almost every row favours a hash join, while one returning very few favours a nested loop. Foreign keys do not create indexes automatically in PostgreSQL, so adding them to `bookings` and keeping statistics fresh with `ANALYZE` are the two changes I'd make first as the platform grows.
