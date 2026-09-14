# Airline Booking — Relation Schema

## 1. Passengers

**Relation:** `passengers`

| Attribute      | Domain       | Description                          |
| -------------- | ------------ | ------------------------------------ |
| `passenger_id` | INTEGER      | Unique identifier for each passenger |
| `display_name` | VARCHAR(100) | Passenger's display name             |

**Primary key:** `passenger_id`

The `passengers` relation represents the users of the airline booking platform. Each passenger is uniquely identified by `passenger_id`.

---

## 2. Flights

**Relation:** `flights`

| Attribute      | Domain       | Description                                             |
| -------------- | ------------ | ------------------------------------------------------- |
| `flight_id`    | INTEGER      | Unique identifier for each flight                       |
| `display_name` | VARCHAR(100) | Flight identifier or display name                       |
| `is_active`    | BOOLEAN      | Indicates whether the flight is currently active        |
| `capacity`     | INTEGER      | Maximum number of passengers the flight can accommodate |

**Primary key:** `flight_id`

The `flights` relation represents the supply-side entities that passengers can book. `capacity` is the numeric attribute used for filtering and analysis.

---

## 3. Bookings

**Relation:** `bookings`

| Attribute      | Domain        | Description                                 |
| -------------- | ------------- | ------------------------------------------- |
| `booking_id`   | INTEGER       | Unique identifier for each booking          |
| `passenger_id` | INTEGER       | Passenger who made the booking              |
| `flight_id`    | INTEGER       | Flight being booked                         |
| `booked_at`    | TIMESTAMP     | Date and time at which the booking was made |
| `fare_paid`    | NUMERIC(10,2) | Amount paid for the booking                 |

**Primary key:** `booking_id`

`passenger_id` is a foreign key referencing `passengers(passenger_id)`.

`flight_id` is a foreign key referencing `flights(flight_id)`.

The `bookings` relation is the high-volume fact table. Each row records an individual booking made by a passenger for a flight.

---

## 4. Airports

**Relation:** `airports`

| Attribute    | Domain       | Description                        |
| ------------ | ------------ | ---------------------------------- |
| `airport_id` | INTEGER      | Unique identifier for each airport |
| `name`       | VARCHAR(150) | Airport name                       |

**Primary key:** `airport_id`

The `airports` relation provides descriptive information about airports that can be associated with flight routes.

---

## 5. Flight Routes

**Relation:** `flight_routes`

| Attribute    | Domain  | Description                              |
| ------------ | ------- | ---------------------------------------- |
| `flight_id`  | INTEGER | Flight associated with the route         |
| `airport_id` | INTEGER | Airport associated with the flight route |

**Primary key:** (`flight_id`, `airport_id`)

`flight_id` is a foreign key referencing `flights(flight_id)`.

`airport_id` is a foreign key referencing `airports(airport_id)`.

The composite primary key ensures that the same flight-airport association cannot be stored more than once.
