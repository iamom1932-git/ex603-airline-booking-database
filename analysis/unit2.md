# Unit 2 — DDL Design Decisions

## Creation Order

The tables are created in the following order:

1. `passengers`
2. `airports`
3. `flights`
4. `bookings`
5. `flight_routes`

`passengers`, `airports`, and `flights` do not reference other tables, so they can be created first. `bookings` is created after `passengers` and `flights` because it references both tables. `flight_routes` is created last because it references both `flights` and `airports`.

## Foreign-Key Constraints and ON DELETE Decisions

| Foreign key                                         | ON DELETE  | Reason                                                                                                            |
| --------------------------------------------------- | ---------- | ----------------------------------------------------------------------------------------------------------------- |
| `bookings.passenger_id` → `passengers.passenger_id` | `RESTRICT` | A passenger cannot be deleted while booking records still reference that passenger.                               |
| `bookings.flight_id` → `flights.flight_id`          | `RESTRICT` | A flight cannot be deleted while historical booking records still reference it.                                   |
| `flight_routes.flight_id` → `flights.flight_id`     | `CASCADE`  | When a flight is removed, its associated route records are no longer meaningful and can be removed automatically. |
| `flight_routes.airport_id` → `airports.airport_id`  | `RESTRICT` | An airport cannot be deleted while it is still referenced by a flight route.                                      |

### Passenger deletion

The `bookings.passenger_id` foreign key uses `ON DELETE RESTRICT`. A booking represents a historical airline booking, so deleting a passenger should not automatically delete those booking records. If `CASCADE` were used instead, deleting one passenger would also delete all of that passenger's bookings, causing historical booking information to disappear.

### Flight deletion from bookings

The `bookings.flight_id` foreign key also uses `ON DELETE RESTRICT`. Existing bookings contain information about passengers who booked a particular flight, including the fare they paid. If a flight with existing bookings were deleted using `CASCADE`, those historical booking records would also disappear. `RESTRICT` prevents the flight from being deleted while bookings still reference it.

### Flight deletion from flight routes

The `flight_routes.flight_id` foreign key uses `ON DELETE CASCADE`. A row in `flight_routes` represents the relationship between a flight and an airport. If the flight itself is removed, those relationship rows no longer have a meaningful parent flight. Cascading the deletion removes the dependent route records automatically.

Using `RESTRICT` here instead would require every route relationship to be manually removed before its flight could be deleted.

### Airport deletion

The `flight_routes.airport_id` foreign key uses `ON DELETE RESTRICT`. An airport should not be removed while flight-route records still identify it as part of a flight's route. Using `CASCADE` would automatically remove those route relationships when an airport was deleted. `RESTRICT` instead requires the dependent route records to be handled first and prevents accidental loss of route information.

## CHECK Constraints

### `chk_flights_capacity_positive`

The `flights` table contains:

```sql
CHECK (capacity > 0)
```

This prevents a flight from being stored with a capacity of zero or a negative capacity. A zero-capacity flight could not accept any passengers, while a negative capacity is not a meaningful airline capacity. Without the constraint, either value could be inserted because `capacity` is only defined as an `INTEGER`.

### `chk_bookings_fare_nonnegative`

The `bookings` table contains:

```sql
CHECK (fare_paid >= 0)
```

This prevents a booking from being stored with a negative fare. A negative fare would represent an invalid monetary value for the amount paid by a passenger. Without the constraint, PostgreSQL would allow a negative numeric value because `fare_paid` is defined as `NUMERIC(10,2)`.

## Design Notes

The surrogate identifiers use PostgreSQL's `INTEGER GENERATED ALWAYS AS IDENTITY` syntax rather than MySQL's `AUTO_INCREMENT`. This follows the PostgreSQL 14+ requirements for the assignment.

The `flight_routes` table uses a composite primary key consisting of `(flight_id, airport_id)`. This prevents the same flight-airport relationship from being recorded more than once while avoiding the need for an additional surrogate identifier for the junction table.

The `is_active` column uses `BOOLEAN` with a default of `TRUE`. This allows a flight to be explicitly marked inactive without deleting the flight or its historical relationships.

The `fare_paid` column uses `NUMERIC(10,2)` rather than a floating-point type because monetary values require exact decimal representation.
