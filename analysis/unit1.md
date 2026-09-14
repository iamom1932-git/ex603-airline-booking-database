# Unit 1 Analysis

## Modelling Justification

The Airline Booking system is modelled using five relations: `passengers`, `flights`, `bookings`, `airports`, and `flight_routes`. These relations represent the five required roles of the project: actor, producer, event, catalog, and junction. The design separates operational entities from booking events and descriptive data so that each fact is stored in an appropriate place and duplication is minimized.

Each main entity uses a single-column primary key. `passenger_id`, `flight_id`, `booking_id`, and `airport_id` provide stable identifiers that are independent of display names or other attributes that may change. A booking receives its own identifier because it represents an individual event rather than simply a relationship between a passenger and a flight. The `flight_routes` relation is different because it exists specifically to represent a many-to-many relationship. Its composite primary key, `(flight_id, airport_id)`, ensures that a particular flight-airport association cannot be stored more than once.

The `bookings` relation connects passengers to flights. A passenger can make many bookings, and a flight can have many bookings, so this structure supports the high volume of transactional data expected from a booking platform. The `booked_at` timestamp allows booking activity to be analysed over time, while `fare_paid` provides the numeric metric required for aggregation. The `flights` relation includes `capacity` as its numeric filtering attribute and `is_active` so that flights can be made unavailable without necessarily deleting their historical records.

Foreign key deletion behavior is chosen according to whether dependent records have independent historical value. The relationship from bookings to passengers uses RESTRICT because deleting a passenger should not automatically erase booking history. Similarly, bookings reference flights with RESTRICT. A flight may become inactive, but its historical bookings should remain available for reporting and auditing. In contrast, `flight_routes` uses CASCADE when a flight is deleted because a route association has no useful independent existence without its parent flight. The airport relationship uses RESTRICT because an airport should not be removed while active route associations depend on it.

Several business rules are enforced at the database level rather than being left entirely to the application. Primary keys prevent duplicate identities, foreign keys prevent references to nonexistent entities, and NOT NULL constraints ensure that required relationships and event attributes exist. A positive capacity constraint prevents impossible flight capacities, while a non-negative fare constraint prevents invalid financial values. Enforcing these rules in the database provides protection even if data is inserted or modified by a different application, reporting tool, or database client.

Overall, the design aims to preserve historical booking information, prevent structurally invalid data, and provide a foundation for the analytical queries that will be developed in later units.

## Reflection

One design decision that another designer could reasonably make differently is the treatment of deleted flights. I chose to use RESTRICT between `bookings` and `flights`, meaning a flight with existing bookings cannot simply be deleted. Another designer might choose CASCADE, arguing that a flight and all of its bookings should be treated as one unit of data.

I prefer RESTRICT because an airline booking platform is likely to have significant historical read activity. Analysts may need to calculate revenue, booking volumes, passenger activity, and other measures from previous flights. Automatically deleting those bookings would destroy valuable historical information and make the results of future analysis incomplete.

The `is_active` attribute provides an alternative to deletion for normal operational use. A flight can become inactive while its historical bookings remain available. This design therefore favors data retention and analytical consistency over making deletion operations as simple as possible.

This decision also reflects the expected write pattern. Bookings are high-volume transactional records, while flight deletion should be relatively rare. It is therefore more important to protect booking history than to optimize for the occasional deletion of a flight.
