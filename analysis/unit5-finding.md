
# Unit 5 Finding: Two Different Problems, Two Different Responses

**To:** Leadership team  **From:** Trust and Data

## Bottom line
Our flights fall into two groups that need opposite responses. A few flights are booked often and fail too often, so they need investigating. Other flights have never been booked at all, so they need a decision, not an investigation. Treating them the same would waste effort on both.

## Group 1: Flights that fail often (Flights 11, 2 and 6; Flight 9 on watch)
These flights are in use, but their cancellation rates were well above the platform's baseline of about 15%. Flight 11 was the highest at 31.3%.

**Recommended action:** Have the operations team review each flagged flight's cancellations booking by booking, starting with Flight 11. Flight 2's failures are mostly passenger no-shows, so look at reminders and check-in prompts there. Flight 6 includes flight cancellations, which the airline controls, so look at scheduling. [Add what 5.1b-2 and 5.1c showed: whether these flights share airports or differ in size from the others.] Re-check in a quarter. If a flight's rate has not moved toward the baseline, escalate.

**What we do not know:** why they fail. The numbers show where to look, and the counts are small, so a single bad week could explain some of it.

## Group 2: Flights that have never been booked ([n] flights: [IDs])
These flights are listed on the platform but have no bookings at all. They were invisible in the earlier failure analysis because a flight with no bookings has no failure rate. A report that leaves them out gives an overly rosy picture of the platform.

**Recommended action:** Do not investigate failures, since there are none. Instead, ask the scheduling and commercial teams one question per flight: should this flight be on sale? Each one should end up in one of three places: launched properly (fix pricing, availability or listing), left alone because it is new, or retired from the system.

**What we do not know:** whether each flight is inactive, newly scheduled, priced out of the market, or leftover test data. The booking records cannot tell us.

## Why the difference matters
A flight that fails often has customers and a problem with service. A flight that has never started has no customers and a problem with the listing or the decision to run it. The first calls for an operational fix, the second for a business decision.

## Going forward
Reports that list flights should include flights with no bookings, shown as zero, so that unused flights are visible to leadership.
