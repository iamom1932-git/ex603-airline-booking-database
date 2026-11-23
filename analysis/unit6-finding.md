# Unit 6 Finding: Is the Failure Problem Getting Better or Worse?

## Bottom line

Over 2023, the failure rate (cancelled bookings as a share of all bookings) fell from 22.6% in the first quarter to 14.6% in the second and has stayed between 14.6% and 15.7% since. So it looks better than at the start of the year and is not getting worse, but with about 50 bookings a quarter the improvement is suggestive, not proven. Month by month the rate bounces between 0% and 27%, which is mostly small numbers: about 17 bookings a month, so one cancellation moves a month by about 6 points. The problem is concentrated on a few flights rather than spread across the platform, so next quarter's effort should go there.

## Is it getting better or worse?

- **By quarter** (`q6_3.sql`, 6.3B-3): Q1 had 12 failures in 53 bookings (22.6%), Q2 7 in 48 (14.6%), Q3 8 in 51 (15.7%) and Q4 7 in 48 (14.6%). The whole-year rate is 17.0% (34 of 200, Unit 4).
- **By month** (`q6_3.sql`, 6.3B-1): January 23.8%, February 19.0%, March 27.3%, April 0.0%, May 11.8%, June 25.0%, July 11.8%, August 16.7%, September 18.8%, October 11.1%, November 14.3%, December 18.8%. The percent-change column swings from -100% to +112% on one or two bookings, so I do not read any single month-to-month change as news.
- **How much to trust it:** the Q1-to-Q2 drop of about 8 points is the largest move, and it has held for three quarters, but at roughly 50 bookings a quarter a swing of that size is within what chance could produce. The Q2-to-Q4 movement (14.6%, 15.7%, 14.6%) is flat. I would call the trend "no sign of worsening, possible early improvement". No months are missing (6.3B-2), so every comparison is between adjacent months.

## Where the problem sits

- **Flights** (`q6_1.sql`, 6.1b): Flights 11, 2 and 6 were flagged in Unit 4 (31.3%, 25.0% and 19.0% failure against a 15.2% baseline). Flight 6 is the busiest with 21 bookings. Flights 2 and 11 tie on 16 bookings (both 7th), so any volume ranking has to show the tie rather than put one above the other.
- **Never-booked flights** (Unit 5): Flights 14 and 15 have no bookings. They appear in the 6.1b leaderboard with 0, so they are not hidden by a report that only lists flights with bookings.
- **Gap** (`q6_2.sql`, 6.2C): Flight 9 had no bookings for 113 days (5 January to 28 April 2023) while 61 bookings were made on 11 other flights (6.2C-2), no booking IDs are missing (6.2C-3), and the flight is now inactive. That points to a real stop, not a data problem. Flight 9 is also on the Unit 4 watch list at 28.6% failure. A gap is not a failure and should not be counted as one.

## What the team should do next quarter

1. **Review the flagged flights' cancellations booking by booking**, starting with Flight 11, split by `cancellation_reason`: no-shows get reminders and check-in prompts (Flight 2), flight cancellations go to scheduling (Flight 6), payment failures go to payments. *Measure:* each flight's failure rate against the 15.2% baseline, by quarter, since single months are too noisy.
2. **Confirm what happened to Flight 9.** Ask scheduling whether it was off sale from January to April and why it is now inactive. If it is retired, remove it from failure comparisons. If it is meant to be running, find out why it went quiet. Do the same for never-booked Flights 14 and 15: launch, leave alone, or retire.
3. **Report with volume beside the rate and judge by quarter.** Any monthly figure should show the booking count, and a month should not be called better or worse on a change of one or two bookings. Re-run 6.3B-3 at the end of the quarter: the goal is to hold at or below 14.6% and to see the flagged flights move toward the baseline.

## What this does not tell us

- The data shows where and when failures happen, not why.
- There are only 200 bookings over 12 months, so even quarterly rates move by several points on a handful of cancellations.
- `booked_at` is when the booking was made, not when the passenger flew, so a "quarter" here is a booking quarter. The failure rate by travel date could differ.
- "Failure" here means cancelled for any reason. Counting disputed bookings (5% of bookings) would raise every figure.
