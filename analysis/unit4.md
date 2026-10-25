# Unit 4 Analysis

## Task 4.1: What the per-flight breakdown hides

**Who acts on it:** [A named role, e.g. the Operations / Network Performance
Manager who decides which flights to review.]

**What the average hides:** [Average fare per flight mixes two kinds of booking:
cancelled ones (fare 0.00) and paid ones. A flight with many cancellations looks
"cheap" rather than "failing". The average doesn't show the spread either:
two flights with the same average could have steady mid-range fares or a
mix of zeros and high fares.]

**What the count hides:** [Booking counts don't show who is counted. A flight
with 20 bookings could have 20 different passengers or a few repeat bookers
(e.g. Passenger 1 books many flights). It also doesn't say how many are
cancelled, disputed or confirmed.]

**What I'd need next:** [e.g. the failure rate and reasons per flight,
distribution of fares (median, spread) for paid bookings only, distinct
passengers per flight, and bookings over time to see whether failures cluster
on certain dates.]

**Threshold note (4.1c):** [Your chosen threshold and why: 15, because below it
one failure moves the rate by 6+ points; still leaves 8 of 13 flights.]

## Task 4.2

**Part A, two questions side by side:**
| Question 1 | Question 2 |
|---|---|
| How many bookings does each flight handle? (`COUNT(*)`) | How many of those failed? (`SUM(CASE WHEN ... cancelled)`) |
[One sentence: both come from the same pass, so the rate is
consistent: same rows in numerator and denominator.]

**Part B, subtotals and grand total:**
- *Reader:* [e.g. the regional director, who needs one line per country to
  compare regions and doesn't want 200 detail rows.]
- *What the grand total adds:* [The group rows say how each region is doing;
  the grand total gives the 17.0% platform rate, the benchmark each region is
  judged against and the figure leadership reports or decides on (e.g.
  whether the platform as a whole needs intervention).]
- *Row key:* [Rows named by country = regional subtotals;
  the `PLATFORM TOTAL` row = grand total.]
[What failure rate should we treat as normal for flights with enough volume
to trust, so we can judge individual flights against it? Step 1 summarises each
flight; step 2 keeps flights with 15+ bookings and pools them (15.2%).]

## Reflection
[150–250 words, see below]
