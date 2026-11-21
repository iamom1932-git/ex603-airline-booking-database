# Unit 6 Finding: Is the Failure Problem Getting Better or Worse?

## Bottom line

Between [first month] and [last month], the failure rate (cancelled bookings as a share of all bookings) [fell from X% to Y% / stayed near X% / rose from X% to Y%]. [One sentence: better, worse, or too noisy to call?] The problem is concentrated on a few flights rather than spread across the platform, so next quarter's effort should go there.

## Is it getting better or worse?

- **Month by month** (`q6_3.sql`, 6.3B-1): the monthly failure rate was [list months and rates]. The whole-period rate is [17.0]% (Unit 4).
- **Recent direction** (`q6_2.sql`, 6.2B-1): the 7-day failure rate at the end of the data is [x]%, against [y]% [n] weeks earlier.
- **How much to trust it:** monthly counts are small ([n] to [n] bookings), so one or two bookings can move a month's rate by several points. [The first/last month is partial (bookings column in 6.3B-1).] [Month X has no bookings (6.3B-2), so the change across it is not month over month.] I would call the trend [clear / suggestive / not established].

## Where the problem sits

- **Flights** (`q6_1.sql`, 6.1a-1 and 6.1b): Flights 11, 2 and 6 were flagged in Unit 4. [Do they still stand out? Say how each compares with its own flight average or its rank.] Flights 2 and 11 tie on [16] bookings, so any volume ranking must show the tie.
- **Never-booked flights** (Unit 5): [n] flights have no bookings. They appear in the 6.1b leaderboard with zero, so they are not hidden.
- **Gap** (`q6_2.sql`, 6.2C): Flight [X] had no bookings for [n] days. The checks in 6.2C-2 and 6.2C-3 point to [a real stop / a data issue / a recording side effect]. A gap is not a failure and should not be counted as one until it is explained.

## What the team should do next quarter

1. **Review the worst flights' cancellations booking by booking**, starting with Flight [11], split by `cancellation_reason`: no-shows get reminders and check-in prompts, flight cancellations go to scheduling, payment failures go to payments. *Measure:* each flight's monthly failure rate against the [15.2]% baseline.
2. **Resolve the Flight [X] gap** by asking the booking-system owner whether bookings from [date range] were recorded elsewhere. *Measure:* the gap is either explained or confirmed as a real stop.
3. **Report monthly with volume beside the rate**, and flag any month with fewer than [n] bookings, so a two-booking swing is not read as a trend. Re-run 6.3B-1 at the end of the quarter.

## What this does not tell us

- The data shows where and when failures happen, not why.
- There are only [200] bookings over [n] months, so rates move a lot on small changes.
- "Failure" here means cancelled for any reason. Counting disputed bookings (5% of bookings) would raise every figure.
