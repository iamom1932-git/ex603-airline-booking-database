# Unit 4 Finding: The Platform's True Failure Rate

## Bottom line
Of 200 bookings, 34 failed, a platform-wide failure rate of 17.0%.
Here, "failed" means the booking was cancelled for any reason (no-show,
payment failure, passenger cancellation, or flight cancellation). Ten further
bookings are in dispute and are not counted as failures; if leadership wants
them included, the rate rises to 22.0%.

## How it varies across flights
Among flights with at least 15 bookings, failure rates range from 0% (Flight 10)
to 31.3% (Flight 11). Most sit between about 12% and 25%, so the spread is
wide: the worst flight fails at roughly twice the platform rate, while the
best has had no failures at all.

Small flights can look extreme by chance. A flight with 11 bookings and
two cancellations shows an 18% rate, but one booking changes it by 9 points.
So I only compared flights with at least 15 bookings. Those eight flights
fail at a combined 15.2% (22 of 145 bookings), which I use as the baseline.

## Flights to investigate
1. **Flight 11**: 31.3% failure on 16 bookings, about double the 15.2% baseline.
   It also has the most failures of any flight (5), spread across flight
   cancellations, a no-show, a passenger cancellation and a payment failure,
   so no single cause explains it.
2. **Flight 2**: 25.0% failure on 16 bookings. Three of its four failures are
   passenger no-shows, which points to a customer-behavior pattern rather
   than an operational one.
3. **Flight 6**: 19.0% failure on 21 bookings, the busiest flight. The rate is
   only moderately above baseline, but two of its four failures were flight
   cancellations, which are within the airline's control.

Flight 9 (28.6% on 14 bookings) just misses the 15-booking cutoff. I would
keep it on a watch list rather than investigate it now.

## What this does and doesn't tell
- A high rate shows where to look, not why it happened.
- The numbers are small. Flight 11 has about 5 failures where the baseline
  would predict about 2 or 3, so these flights deserve a closer look,
  not a conclusion.
- Results depend on counting every cancellation as a failure. Counting only
  no-shows, or including disputes, would change the ranking.
- Next step: break the flagged flights' failures down by reason and booking
  country, and check whether the same passengers or dates repeat.
