-- =================================================================
-- EX 603 Assignment 2 - schema.sql
-- Theme: Airline Booking
-- Author: Om Pandey
-- Target: PostgreSQL 14+
-- =================================================================
-- Reset. Reverse creation order, so no dependency blocks a drop.
 
DROP TABLE IF EXISTS flight_routes CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS flights CASCADE;
DROP TABLE IF EXISTS airports CASCADE;
DROP TABLE IF EXISTS passengers CASCADE;

-- 1. passengers
-- Created first because it does not reference another table.

CREATE TABLE passengers (
passenger_id INTEGER GENERATED ALWAYS AS IDENTITY,
display_name VARCHAR(100) NOT NULL,

CONSTRAINT pk_passengers
    PRIMARY KEY (passenger_id)

);

-- 2. airports
-- Created before flight_routes because flight_routes references it.
-- It does not reference another table itself.

CREATE TABLE airports (
airport_id INTEGER GENERATED ALWAYS AS IDENTITY,
name VARCHAR(150) NOT NULL,

CONSTRAINT pk_airports
    PRIMARY KEY (airport_id)

);

-- 3. flights
-- Created before bookings and flight_routes because both tables
-- reference flights.

CREATE TABLE flights (
flight_id INTEGER GENERATED ALWAYS AS IDENTITY,
display_name VARCHAR(100) NOT NULL,
is_active BOOLEAN NOT NULL DEFAULT TRUE,
capacity INTEGER NOT NULL,

CONSTRAINT pk_flights
    PRIMARY KEY (flight_id),

CONSTRAINT chk_flights_capacity_positive
    CHECK (capacity > 0)

);

-- 4. bookings
-- Created after passengers and flights because it references both.
-- Existing bookings are treated as historical records, so deleting
-- a referenced passenger or flight is restricted.

CREATE TABLE bookings (
booking_id INTEGER GENERATED ALWAYS AS IDENTITY,
passenger_id INTEGER NOT NULL,
flight_id INTEGER NOT NULL,
booked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
fare_paid NUMERIC(10,2) NOT NULL,

CONSTRAINT pk_bookings
    PRIMARY KEY (booking_id),

CONSTRAINT fk_bookings_passenger
    FOREIGN KEY (passenger_id)
    REFERENCES passengers (passenger_id)
    ON DELETE RESTRICT,

CONSTRAINT fk_bookings_flight
    FOREIGN KEY (flight_id)
    REFERENCES flights (flight_id)
    ON DELETE RESTRICT,

CONSTRAINT chk_bookings_fare_nonnegative
    CHECK (fare_paid >= 0)

);

-- 5. flight_routes
-- Created last because it references both flights and airports.
-- The composite primary key prevents the same flight-airport
-- relationship from being recorded more than once.

CREATE TABLE flight_routes (
flight_id INTEGER NOT NULL,
airport_id INTEGER NOT NULL,

CONSTRAINT pk_flight_routes
    PRIMARY KEY (flight_id, airport_id),

CONSTRAINT fk_flight_routes_flight
    FOREIGN KEY (flight_id)
    REFERENCES flights (flight_id)
    ON DELETE CASCADE,

CONSTRAINT fk_flight_routes_airport
    FOREIGN KEY (airport_id)
    REFERENCES airports (airport_id)
    ON DELETE RESTRICT

);
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;