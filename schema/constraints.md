# Airline Booking — Integrity Constraints

The schema uses primary keys, foreign keys, uniqueness constraints, nullability constraints, and value constraints to prevent invalid data from being stored.

## Primary Key Constraints

### Passengers

`passengers.passenger_id` is the primary key.

This ensures that every passenger has a unique identifier and that the identifier cannot be NULL.

### Flights

`flights.flight_id` is the primary key.

This ensures that every flight can be uniquely identified.

### Bookings

`bookings.booking_id` is the primary key.

Each booking represents a distinct booking event, so every booking requires its own unique identifier.

### Airports

`airports.airport_id` is the primary key.

This provides a stable identifier for each airport.

### Flight Routes

`flight_routes` uses the composite primary key:

`(flight_id, airport_id)`

This prevents the same flight-airport relationship from being recorded more than once.

---

## Foreign Key Constraints

### Bookings → Passengers

`bookings.passenger_id` references `passengers.passenger_id`.

**ON DELETE behavior: RESTRICT**

A passenger should not be deleted while booking records still reference that passenger. Restricting deletion protects the historical booking data and prevents orphaned bookings.

The platform's booking history is important for reporting and auditing, so deleting a passenger should require an explicit data-retention decision rather than automatically removing their booking history.

---

### Bookings → Flights

`bookings.flight_id` references `flights.flight_id`.

**ON DELETE: RESTRICT**

A flight should not be deleted while bookings reference it. Existing bookings represent historical transactions and should remain valid even after a flight is no longer available for booking.

Instead of deleting a flight that is no longer offered, the `is_active` attribute can be changed to indicate that it is no longer active.

---

### Flight Routes → Flights

`flight_routes.flight_id` references `flights.flight_id`.

**ON DELETE: CASCADE**

A route association has no independent meaning without its flight. If a flight is removed, its associated flight-route records should also be removed automatically.

This avoids orphaned rows in the junction relation.

---

### Flight Routes → Airports

`flight_routes.airport_id` references `airports.airport_id`.

**ON DELETE: RESTRICT**

An airport should not be deleted while it is referenced by a flight route. Removing the airport could otherwise leave a route without a valid airport.

Restricting the deletion forces the relationship to be dealt with explicitly before an airport is removed.

---

## Attribute Constraints

### Passenger display name

`passengers.display_name` should be NOT NULL.

Every passenger needs a display name because the platform must be able to identify the passenger in its user-facing interface.

### Flight display name

`flights.display_name` should be NOT NULL.

A flight requires a human-readable identifier for display and administration.

### Flight active status

`flights.is_active` should be NOT NULL.

Every flight must have a defined active/inactive state. An unknown state would make filtering and reporting ambiguous.

### Flight capacity

`flights.capacity` should be NOT NULL and must be greater than zero.

A flight with zero or negative passenger capacity would represent an invalid operational state.

### Booking timestamp

`bookings.booked_at` should be NOT NULL.

Every booking is an event and therefore requires a timestamp indicating when it occurred.

### Fare paid

`bookings.fare_paid` should be NOT NULL and must be greater than or equal to zero.

A booking cannot have a negative fare. Zero can be permitted because legitimate zero-fare bookings, promotional bookings, or fully discounted bookings may exist.

### Foreign key attributes

`bookings.passenger_id`, `bookings.flight_id`, `flight_routes.flight_id`, and `flight_routes.airport_id` should be NOT NULL.

Each relationship is mandatory for the corresponding record to have meaning.

---

## Integrity Principle

The design places rules that are fundamental to the correctness of the data in the database rather than relying exclusively on application code. This means that invalid relationships, duplicate identifiers, impossible capacities, and negative fares are prevented regardless of which application or client attempts to modify the database.
