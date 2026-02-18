-- ============================================================
--  NESTLOOP RENTAL ANALYTICS — SQL Server
-- ============================================================

CREATE DATABASE NestloopAnalytics;
GO

USE NestloopAnalytics;
GO

-- ============================================================
--  1. SCHEMA
-- ============================================================

-- Drop tables in reverse dependency order (for re-runs)
IF OBJECT_ID('reviews',            'U') IS NOT NULL DROP TABLE reviews;
IF OBJECT_ID('bookings',           'U') IS NOT NULL DROP TABLE bookings;
IF OBJECT_ID('property_amenities', 'U') IS NOT NULL DROP TABLE property_amenities;
IF OBJECT_ID('amenities',          'U') IS NOT NULL DROP TABLE amenities;
IF OBJECT_ID('properties',         'U') IS NOT NULL DROP TABLE properties;
IF OBJECT_ID('guests',             'U') IS NOT NULL DROP TABLE guests;
IF OBJECT_ID('hosts',              'U') IS NOT NULL DROP TABLE hosts;


-- == HOSTS ==
CREATE TABLE hosts (
    host_id         INT           PRIMARY KEY IDENTITY(1,1),
    full_name       NVARCHAR(100) NOT NULL,
    email           NVARCHAR(150) NOT NULL UNIQUE,
    phone           NVARCHAR(20),
    city            NVARCHAR(100),
    is_superhost    BIT           NOT NULL DEFAULT 0,
    response_rate   DECIMAL(5,2),          -- e.g. 98.50 = 98.5%
    joined_date     DATE          NOT NULL
);


-- == GUESTS ==
CREATE TABLE guests (
    guest_id        INT           PRIMARY KEY IDENTITY(1,1),
    full_name       NVARCHAR(100) NOT NULL,
    email           NVARCHAR(150) NOT NULL UNIQUE,
    phone           NVARCHAR(20),
    country         NVARCHAR(100),
    joined_date     DATE          NOT NULL
);


-- == PROPERTIES ==
CREATE TABLE properties (
    property_id         INT             PRIMARY KEY IDENTITY(1,1),
    host_id             INT             NOT NULL REFERENCES hosts(host_id),
    title               NVARCHAR(200)   NOT NULL,
    property_type       NVARCHAR(50)    NOT NULL,  -- Apartment, House, Villa, etc.
    room_type           NVARCHAR(50)    NOT NULL,  -- Entire place, Private room, Shared room
    neighborhood        NVARCHAR(100),
    city                NVARCHAR(100)   NOT NULL,
    country             NVARCHAR(100)   NOT NULL,
    latitude            DECIMAL(9,6),
    longitude           DECIMAL(9,6),
    bedrooms            TINYINT         NOT NULL DEFAULT 1,
    bathrooms           DECIMAL(3,1)    NOT NULL DEFAULT 1.0,
    max_guests          TINYINT         NOT NULL DEFAULT 2,
    price_per_night     DECIMAL(10,2)   NOT NULL,
    cleaning_fee        DECIMAL(10,2)   NOT NULL DEFAULT 0,
    min_nights          TINYINT         NOT NULL DEFAULT 1,
    is_active           BIT             NOT NULL DEFAULT 1,
    created_at          DATETIME        NOT NULL DEFAULT GETDATE()
);


-- == AMENITIES ==
CREATE TABLE amenities (
    amenity_id      INT           PRIMARY KEY IDENTITY(1,1),
    name            NVARCHAR(100) NOT NULL UNIQUE   -- WiFi, Pool, Kitchen, etc.
);


-- == PROPERTY_AMENITIES (many-to-many) ==
CREATE TABLE property_amenities (
    property_id     INT NOT NULL REFERENCES properties(property_id),
    amenity_id      INT NOT NULL REFERENCES amenities(amenity_id),
    PRIMARY KEY (property_id, amenity_id)
);


-- == BOOKINGS ==
CREATE TABLE bookings (
    booking_id          INT             PRIMARY KEY IDENTITY(1,1),
    property_id         INT             NOT NULL REFERENCES properties(property_id),
    guest_id            INT             NOT NULL REFERENCES guests(guest_id),
    check_in            DATE            NOT NULL,
    check_out           DATE            NOT NULL,
    num_guests          TINYINT         NOT NULL DEFAULT 1,
    price_per_night     DECIMAL(10,2)   NOT NULL,   -- locked-in rate at time of booking
    cleaning_fee        DECIMAL(10,2)   NOT NULL DEFAULT 0,
    total_amount        AS ( DATEDIFF(DAY, check_in, check_out) * price_per_night + cleaning_fee ) PERSISTED,
    status              NVARCHAR(20)    NOT NULL DEFAULT 'confirmed',  -- confirmed, cancelled, completed
    booked_at           DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT chk_checkout_after_checkin CHECK (check_out > check_in),
    CONSTRAINT chk_booking_status CHECK (status IN ('confirmed','cancelled','completed'))
);


-- == REVIEWS ==
CREATE TABLE reviews (
    review_id           INT             PRIMARY KEY IDENTITY(1,1),
    booking_id          INT             NOT NULL UNIQUE REFERENCES bookings(booking_id),
    property_id         INT             NOT NULL REFERENCES properties(property_id),
    guest_id            INT             NOT NULL REFERENCES guests(guest_id),
    rating_overall      TINYINT         NOT NULL,   -- 1–5
    rating_cleanliness  TINYINT,
    rating_location     TINYINT,
    rating_value        TINYINT,
    comment             NVARCHAR(2000),
    reviewed_at         DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT chk_rating_overall     CHECK (rating_overall     BETWEEN 1 AND 5),
    CONSTRAINT chk_rating_cleanliness CHECK (rating_cleanliness BETWEEN 1 AND 5),
    CONSTRAINT chk_rating_location    CHECK (rating_location    BETWEEN 1 AND 5),
    CONSTRAINT chk_rating_value       CHECK (rating_value       BETWEEN 1 AND 5)
);


-- == INDEXES ==
CREATE INDEX idx_properties_host       ON properties (host_id);
CREATE INDEX idx_properties_city       ON properties (city);
CREATE INDEX idx_bookings_property     ON bookings   (property_id);
CREATE INDEX idx_bookings_guest        ON bookings   (guest_id);
CREATE INDEX idx_bookings_dates        ON bookings   (check_in, check_out);
CREATE INDEX idx_reviews_property      ON reviews    (property_id);



-- ============================================================
--  2. DATA
-- ============================================================

-- == HOSTS ==
INSERT INTO hosts (full_name, email, phone, city, is_superhost, response_rate, joined_date) VALUES
('Sarah Mitchell',   'sarah.mitchell@email.com',  '+1-212-555-0101', 'New York',      1, 99.00, '2018-03-15'),
('James Okonkwo',    'james.okonkwo@email.com',   '+1-323-555-0182', 'Los Angeles',   1, 97.50, '2019-06-20'),
('Emily Tran',       'emily.tran@email.com',       '+1-305-555-0143', 'Miami',         0, 88.00, '2020-11-05'),
('Carlos Mendez',    'carlos.mendez@email.com',   '+1-312-555-0167', 'Chicago',       0, 92.00, '2021-02-28'),
('Priya Sharma',     'priya.sharma@email.com',    '+1-415-555-0198', 'San Francisco', 1, 100.00,'2017-09-10'),
('Daniel Weiss',     'daniel.weiss@email.com',    '+1-512-555-0211', 'Austin',        1, 98.00, '2018-07-04'),
('Naomi Clarke',     'naomi.clarke@email.com',    '+1-720-555-0234', 'Denver',        0, 85.00, '2021-04-19'),
('Sofia Reyes',      'sofia.reyes@email.com',     '+1-206-555-0256', 'Seattle',       1, 99.50, '2019-01-30'),
('Marcus Johnson',   'marcus.johnson@email.com',  '+1-404-555-0278', 'Atlanta',       0, 91.00, '2022-06-11'),
('Hana Nakamura',    'hana.nakamura@email.com',   '+1-808-555-0290', 'Honolulu',      1, 97.00, '2017-11-22');


-- == GUESTS ==
INSERT INTO guests (full_name, email, phone, country, joined_date) VALUES
('Lucas Ferreira',   'lucas.ferreira@email.com',  '+55-11-91234-5678', 'Brazil',        '2021-01-10'),
('Anna Kowalski',    'anna.kowalski@email.com',   '+48-501-234-567',   'Poland',        '2020-07-22'),
('Tom Richardson',   'tom.richardson@email.com',  '+44-7911-123456',   'UK',            '2019-05-30'),
('Yuki Tanaka',      'yuki.tanaka@email.com',     '+81-90-1234-5678',  'Japan',         '2022-03-14'),
('Fatima Al-Rashid', 'fatima.alrashid@email.com', '+971-50-123-4567',  'UAE',           '2021-08-18'),
('Marco Rossi',      'marco.rossi@email.com',     '+39-333-123-4567',  'Italy',         '2020-12-01'),
('Chloe Dubois',     'chloe.dubois@email.com',    '+33-6-12-34-56-78', 'France',        '2023-02-09'),
('Ryan Park',        'ryan.park@email.com',       '+1-647-555-0177',   'Canada',        '2022-09-25'),
('Diego Hernandez',  'diego.hernandez@email.com', '+52-55-1234-5678',  'Mexico',        '2021-05-15'),
('Ingrid Larsson',   'ingrid.larsson@email.com',  '+46-70-123-4567',   'Sweden',        '2020-03-08'),
('Kwame Asante',     'kwame.asante@email.com',    '+233-24-123-4567',  'Ghana',         '2023-01-20'),
('Mei-Ling Chen',    'meiling.chen@email.com',    '+86-138-0013-8000', 'China',         '2022-07-11'),
('Oliver Bennett',   'oliver.bennett@email.com',  '+61-400-123-456',   'Australia',     '2019-09-03'),
('Valentina Cruz',   'valentina.cruz@email.com',  '+54-11-5678-9012',  'Argentina',     '2021-11-27'),
('Ravi Patel',       'ravi.patel@email.com',      '+91-98765-43210',   'India',         '2020-06-14'),
('Leila Hassan',     'leila.hassan@email.com',    '+20-100-123-4567',  'Egypt',         '2023-04-02');

-- == AMENITIES ==
INSERT INTO amenities (name) VALUES
('WiFi'), ('Kitchen'), ('Air Conditioning'), ('Heating'), ('Washer'),
('Dryer'), ('Free Parking'), ('Pool'), ('Hot Tub'), ('Gym'),
('Balcony'), ('Pet Friendly'), ('Smoke Alarm'), ('Carbon Monoxide Alarm'), ('Workspace');


-- ── PROPERTIES ───────────────────────────────────────────────
INSERT INTO properties (host_id, title, property_type, room_type, neighborhood, city, country, latitude, longitude, bedrooms, bathrooms, max_guests, price_per_night, cleaning_fee, min_nights) VALUES
(1, 'Chic SoHo Loft with Skyline Views',        'Apartment', 'Entire place',   'SoHo',          'New York',      'USA', 40.723319, -74.002953, 2, 1.0, 4, 275.00, 85.00, 2),
(1, 'Cozy Brooklyn Studio Near Prospect Park',  'Apartment', 'Entire place',   'Park Slope',    'New York',      'USA', 40.671543, -73.977664, 1, 1.0, 2, 145.00, 55.00, 1),
(2, 'Sunny Venice Beach Bungalow',              'House',     'Entire place',   'Venice',        'Los Angeles',   'USA', 33.985680, -118.473160,2, 2.0, 5, 320.00, 110.00,3),
(2, 'Hollywood Hills Private Room with View',  'House',     'Private room',   'Hollywood Hills','Los Angeles',  'USA', 34.124150, -118.321350,1, 1.0, 2, 95.00,  35.00, 2),
(3, 'Luxury Oceanfront Condo — South Beach',   'Apartment', 'Entire place',   'South Beach',   'Miami',         'USA', 25.782430, -80.130290, 3, 2.0, 6, 490.00, 150.00,3),
(3, 'Art Deco Studio in Wynwood Arts District', 'Apartment', 'Entire place',   'Wynwood',       'Miami',         'USA', 25.800900, -80.199150, 1, 1.0, 2, 165.00, 60.00, 2),
(4, 'Modern Wicker Park Apartment',            'Apartment', 'Entire place',   'Wicker Park',   'Chicago',       'USA', 41.908040, -87.677210, 2, 1.0, 4, 185.00, 70.00, 2),
(4, 'Downtown Chicago Private Room',           'Apartment', 'Private room',   'The Loop',      'Chicago',       'USA', 41.882610, -87.629820, 1, 1.0, 2, 80.00,  30.00, 1),
(5, 'Victorian Flat in the Mission District',  'Apartment', 'Entire place',   'Mission District','San Francisco','USA',37.759450, -122.415720,2, 1.5, 4, 240.00, 90.00, 2),
(5, 'Minimalist Loft — Hayes Valley',          'Apartment', 'Entire place',   'Hayes Valley',  'San Francisco', 'USA', 37.776100, -122.424680,1, 1.0, 2, 195.00, 65.00, 1),
(6,  'Sun-Drenched East Austin Cottage',            'House',     'Entire place',  'East Austin',    'Austin',    'USA', 30.264980,  -97.720300, 2, 1.0, 4, 210.00,  75.00, 2),
(6,  'Sleek South Congress Studio',                 'Apartment', 'Entire place',  'South Congress', 'Austin',    'USA', 30.243560,  -97.749120, 1, 1.0, 2, 140.00,  50.00, 1),
(7,  'RiNo Art District Loft',                      'Apartment', 'Entire place',  'RiNo',           'Denver',    'USA', 39.766180, -104.971020, 2, 2.0, 4, 175.00,  65.00, 2),
(7,  'Cozy Capitol Hill Private Room',              'House',     'Private room',  'Capitol Hill',   'Denver',    'USA', 39.731450, -104.978900, 1, 1.0, 2,  85.00,  30.00, 1),
(8,  'Stylish Capitol Hill Apartment',              'Apartment', 'Entire place',  'Capitol Hill',   'Seattle',   'USA', 47.623150, -122.319880, 2, 1.5, 4, 230.00,  80.00, 2),
(8,  'Charming Fremont Craftsman Home',             'House',     'Entire place',  'Fremont',        'Seattle',   'USA', 47.651710, -122.349810, 3, 2.0, 6, 295.00, 100.00, 3),
(9,  'Modern Midtown Atlanta Condo',                'Apartment', 'Entire place',  'Midtown',        'Atlanta',   'USA', 33.781890,  -84.383940, 2, 2.0, 4, 195.00,  70.00, 2),
(9,  'Historic Inman Park Bungalow',                'House',     'Entire place',  'Inman Park',     'Atlanta',   'USA', 33.753640,  -84.352290, 3, 2.0, 6, 255.00,  95.00, 2),
(10, 'Oceanview Studio — Waikiki',                  'Apartment', 'Entire place',  'Waikiki',        'Honolulu',  'USA', 21.277490, -157.829720, 1, 1.0, 2, 350.00, 100.00, 3),
(10, 'Tropical 3BR Villa — Kailua',                 'Villa',     'Entire place',  'Kailua',         'Honolulu',  'USA', 21.402660, -157.739600, 3, 2.5, 7, 620.00, 180.00, 4);



-- == PROPERTY AMENITIES ==
-- Property 1: Chic SoHo Loft
INSERT INTO property_amenities VALUES (1,1),(1,2),(1,3),(1,4),(1,11),(1,13),(1,14),(1,15);
-- Property 2: Brooklyn Studio
INSERT INTO property_amenities VALUES (2,1),(2,2),(2,4),(2,5),(2,13),(2,14);
-- Property 3: Venice Beach Bungalow
INSERT INTO property_amenities VALUES (3,1),(3,2),(3,3),(3,7),(3,8),(3,12),(3,13),(3,14);
-- Property 4: Hollywood Hills Private Room
INSERT INTO property_amenities VALUES (4,1),(4,3),(4,4),(4,7),(4,13);
-- Property 5: Luxury South Beach Condo
INSERT INTO property_amenities VALUES (5,1),(5,2),(5,3),(5,4),(5,8),(5,9),(5,10),(5,11),(5,13),(5,14);
-- Property 6: Wynwood Studio
INSERT INTO property_amenities VALUES (6,1),(6,2),(6,3),(6,13),(6,14),(6,15);
-- Property 7: Wicker Park Apartment
INSERT INTO property_amenities VALUES (7,1),(7,2),(7,4),(7,5),(7,6),(7,13),(7,14),(7,15);
-- Property 8: Downtown Chicago Room
INSERT INTO property_amenities VALUES (8,1),(8,3),(8,4),(8,13);
-- Property 9: Mission District Victorian
INSERT INTO property_amenities VALUES (9,1),(9,2),(9,4),(9,5),(9,11),(9,12),(9,13),(9,14);
-- Property 10: Hayes Valley Loft
INSERT INTO property_amenities VALUES (10,1),(10,2),(10,3),(10,13),(10,14),(10,15);
-- Property 11: East Austin Cottage
INSERT INTO property_amenities VALUES (11,1),(11,2),(11,3),(11,4),(11,7),(11,12),(11,13),(11,14);
-- Property 12: South Congress Studio
INSERT INTO property_amenities VALUES (12,1),(12,2),(12,3),(12,13),(12,14),(12,15);
-- Property 13: RiNo Loft
INSERT INTO property_amenities VALUES (13,1),(13,2),(13,4),(13,5),(13,6),(13,11),(13,13),(13,14),(13,15);
-- Property 14: Capitol Hill Denver Room
INSERT INTO property_amenities VALUES (14,1),(14,4),(14,13),(14,14);
-- Property 15: Capitol Hill Seattle Apartment
INSERT INTO property_amenities VALUES (15,1),(15,2),(15,4),(15,5),(15,11),(15,13),(15,14),(15,15);
-- Property 16: Fremont Craftsman Home
INSERT INTO property_amenities VALUES (16,1),(16,2),(16,4),(16,5),(16,6),(16,7),(16,12),(16,13),(16,14);
-- Property 17: Midtown Atlanta Condo
INSERT INTO property_amenities VALUES (17,1),(17,2),(17,3),(17,4),(17,10),(17,11),(17,13),(17,14);
-- Property 18: Inman Park Bungalow
INSERT INTO property_amenities VALUES (18,1),(18,2),(18,3),(18,7),(18,12),(18,13),(18,14);
-- Property 19: Waikiki Studio
INSERT INTO property_amenities VALUES (19,1),(19,2),(19,3),(19,11),(19,13),(19,14);
-- Property 20: Kailua Villa
INSERT INTO property_amenities VALUES (20,1),(20,2),(20,3),(20,7),(20,8),(20,9),(20,12),(20,13),(20,14);


-- == BOOKINGS ==
INSERT INTO bookings (property_id, guest_id, check_in, check_out, num_guests, price_per_night, cleaning_fee, status, booked_at) VALUES
-- Completed stays
(1,  1, '2024-01-10', '2024-01-14', 2, 275.00,  85.00, 'completed', '2023-12-20'),
(1,  3, '2024-02-20', '2024-02-25', 3, 275.00,  85.00, 'completed', '2024-01-15'),
(2,  2, '2024-01-05', '2024-01-08', 1, 145.00,  55.00, 'completed', '2023-12-28'),
(3,  4, '2024-02-14', '2024-02-18', 4, 320.00, 110.00, 'completed', '2024-01-20'),
(3,  6, '2024-03-01', '2024-03-07', 2, 320.00, 110.00, 'completed', '2024-02-10'),
(5,  5, '2024-01-20', '2024-01-25', 5, 490.00, 150.00, 'completed', '2023-12-30'),
(5,  7, '2024-03-15', '2024-03-20', 4, 490.00, 150.00, 'completed', '2024-02-25'),
(6,  8, '2024-02-01', '2024-02-04', 2, 165.00,  60.00, 'completed', '2024-01-10'),
(7,  1, '2024-01-15', '2024-01-19', 3, 185.00,  70.00, 'completed', '2023-12-22'),
(9,  2, '2024-02-10', '2024-02-14', 2, 240.00,  90.00, 'completed', '2024-01-18'),
(9,  4, '2024-03-05', '2024-03-09', 4, 240.00,  90.00, 'completed', '2024-02-12'),
(10, 3, '2024-01-22', '2024-01-25', 1, 195.00,  65.00, 'completed', '2024-01-01'),
(11,  9, '2024-03-10', '2024-03-14', 2, 210.00,  75.00, 'completed', '2024-02-18'),
(11, 12, '2024-04-05', '2024-04-09', 3, 210.00,  75.00, 'completed', '2024-03-10'),
(12, 10, '2024-02-15', '2024-02-18', 1, 140.00,  50.00, 'completed', '2024-01-25'),
(13, 11, '2024-01-08', '2024-01-12', 2, 175.00,  65.00, 'completed', '2023-12-15'),
(13,  9, '2024-03-20', '2024-03-25', 4, 175.00,  65.00, 'completed', '2024-02-28'),
(14, 13, '2024-02-01', '2024-02-03', 1,  85.00,  30.00, 'completed', '2024-01-12'),
(15, 14, '2024-01-18', '2024-01-23', 3, 230.00,  80.00, 'completed', '2023-12-26'),
(15,  2, '2024-04-10', '2024-04-15', 2, 230.00,  80.00, 'completed', '2024-03-18'),
(16,  6, '2024-02-22', '2024-02-27', 5, 295.00, 100.00, 'completed', '2024-01-30'),
(16, 15, '2024-04-18', '2024-04-23', 4, 295.00, 100.00, 'completed', '2024-03-25'),
(17,  3, '2024-01-25', '2024-01-29', 2, 195.00,  70.00, 'completed', '2024-01-02'),
(17, 10, '2024-03-12', '2024-03-16', 3, 195.00,  70.00, 'completed', '2024-02-20'),
(18,  7, '2024-02-08', '2024-02-13', 4, 255.00,  95.00, 'completed', '2024-01-16'),
(18,  1, '2024-04-01', '2024-04-06', 5, 255.00,  95.00, 'completed', '2024-03-05'),
(19,  4, '2024-01-30', '2024-02-03', 2, 350.00, 100.00, 'completed', '2023-12-10'),
(19, 16, '2024-03-22', '2024-03-26', 1, 350.00, 100.00, 'completed', '2024-02-29'),
(20,  5, '2024-02-17', '2024-02-24', 6, 620.00, 180.00, 'completed', '2024-01-22'),
(20,  8, '2024-04-14', '2024-04-21', 5, 620.00, 180.00, 'completed', '2024-03-20'),
-- Confirmed (upcoming)
(1,  5, '2025-05-01', '2025-05-05', 2, 275.00,  85.00, 'confirmed', '2025-04-01'),
(3,  8, '2025-05-10', '2025-05-15', 3, 320.00, 110.00, 'confirmed', '2025-04-05'),
(5,  6, '2025-06-01', '2025-06-07', 4, 490.00, 150.00, 'confirmed', '2025-04-20'),
(7,  7, '2025-05-20', '2025-05-24', 2, 185.00,  70.00, 'confirmed', '2025-04-10'),
(9,  1, '2025-06-10', '2025-06-15', 3, 240.00,  90.00, 'confirmed', '2025-04-15'),
(11, 13, '2025-06-01', '2025-06-05', 2, 210.00,  75.00, 'confirmed', '2025-04-22'),
(13, 16, '2025-05-15', '2025-05-20', 3, 175.00,  65.00, 'confirmed', '2025-04-08'),
(15, 11, '2025-06-20', '2025-06-25', 2, 230.00,  80.00, 'confirmed', '2025-04-18'),
(16,  9, '2025-07-04', '2025-07-10', 5, 295.00, 100.00, 'confirmed', '2025-05-01'),
(18, 14, '2025-06-15', '2025-06-20', 4, 255.00,  95.00, 'confirmed', '2025-04-25'),
(19, 12, '2025-05-28', '2025-06-02', 2, 350.00, 100.00, 'confirmed', '2025-04-12'),
(20, 15, '2025-07-01', '2025-07-08', 6, 620.00, 180.00, 'confirmed', '2025-05-05'),
-- Cancelled
(2,  6, '2024-04-01', '2024-04-04', 1, 145.00,  55.00, 'cancelled', '2024-03-01'),
(4,  3, '2024-03-10', '2024-03-13', 2,  95.00,  35.00, 'cancelled', '2024-02-15'),
(8,  5, '2024-02-20', '2024-02-22', 1,  80.00,  30.00, 'cancelled', '2024-02-01'),
(12, 11, '2024-05-01', '2024-05-04', 1, 140.00,  50.00, 'cancelled', '2024-04-01'),
(14,  8, '2024-04-20', '2024-04-22', 2,  85.00,  30.00, 'cancelled', '2024-04-05'),
(17,  4, '2024-05-10', '2024-05-13', 2, 195.00,  70.00, 'cancelled', '2024-04-15'),
(19,  6, '2024-06-01', '2024-06-05', 3, 350.00, 100.00, 'cancelled', '2024-05-10'),
(20,  3, '2024-05-20', '2024-05-27', 4, 620.00, 180.00, 'cancelled', '2024-04-28');

-- ===REVIEWS===
INSERT INTO reviews (booking_id, property_id, guest_id, rating_overall, rating_cleanliness, rating_location, rating_value, comment, reviewed_at) VALUES
(1,  1,  1, 5, 5, 5, 4, 'Absolutely stunning loft! Sarah was incredibly responsive. The views are even better in person.',                       '2024-01-15'),
(2,  1,  3, 4, 4, 5, 4, 'Great location in SoHo, very stylish apartment. A bit noisy at night but that''s NYC for you.',                        '2024-02-26'),
(3,  2,  2, 5, 5, 4, 5, 'Cozy and clean. Perfect for a solo trip. Loved the neighborhood coffee shops.',                                        '2024-01-09'),
(4,  3,  4, 5, 5, 5, 5, 'Dream come true! The bungalow is exactly as pictured. Beach was a 2-minute walk. Will definitely be back.',            '2024-02-19'),
(5,  3,  6, 4, 4, 5, 4, 'Beautiful place and great location. Check-in was a little confusing but James sorted it quickly.',                     '2024-03-08'),
(6,  5,  5, 5, 5, 5, 4, 'Stunning condo right on the ocean. Pool was amazing. Pricy but worth every penny for a special occasion.',            '2024-01-26'),
(7,  5,  7, 5, 5, 5, 5, 'Best Nestloop experience I''ve ever had. Emily was a fantastic host and the place was spotless.',                        '2024-03-21'),
(8,  6,  8, 3, 3, 5, 3, 'Location in Wynwood is incredible but the studio felt a bit tired. AC was a little weak in the heat.',                '2024-02-05'),
(9,  7,  1, 4, 5, 4, 4, 'Very clean modern apartment. Carlos was responsive. Close to great restaurants and bars.',                             '2024-01-20'),
(10, 9,  2, 5, 5, 4, 5, 'Loved the Victorian charm. Priya is a wonderful host — left a welcome basket. Highly recommend!',                     '2024-02-15'),
(11, 9,  4, 4, 4, 4, 4, 'Beautiful flat in a great neighborhood. A little street noise but nothing major. Would return.',                       '2024-03-10'),
(12, 10, 3, 5, 5, 5, 5, 'Sleek, stylish, and perfectly located. Priya thought of everything. One of my favorite stays ever.',                  '2024-01-26'),
(21, 11,  9, 5, 5, 4, 5, 'The cottage had such a homey feel. Daniel was a great host and left us local restaurant recommendations.',         '2024-03-15'),
(22, 11, 12, 4, 4, 4, 4, 'Cute place in a fun neighborhood. A little small for three people but we made it work.',                         '2024-04-11'),
(23, 12, 10, 5, 5, 5, 5, 'Perfectly located for exploring South Congress. Clean, modern, and everything I needed for a solo trip.',        '2024-02-19'),
(24, 13, 11, 4, 5, 4, 3, 'Super stylish loft with great natural light. Parking was a hassle but the space itself was fantastic.',          '2024-01-13'),
(25, 13,  9, 5, 5, 5, 4, 'Wonderful stay in RiNo. We walked to galleries and breweries every night. Would absolutely come back.',          '2024-03-26'),
(26, 14, 13, 3, 3, 4, 3, 'Decent room and a kind host but the listing photos were a bit misleading about the size.',                      '2024-02-04'),
(27, 15, 14, 5, 5, 5, 5, 'Sofia''s apartment is immaculate. The Capitol Hill location is unbeatable — coffee shops and parks everywhere.', '2024-01-24'),
(28, 15,  2, 4, 4, 5, 4, 'Lovely flat and a very convenient location. Check-in instructions were a bit unclear but Sofia responded fast.','2024-04-16'),
(29, 16,  6, 5, 5, 4, 4, 'The Craftsman home had so much character. Plenty of space for our group and the backyard was a bonus.',         '2024-02-28'),
(30, 16, 15, 5, 5, 5, 5, 'Best house rental I''ve ever had. Sofia thought of every detail. The neighborhood is charming and walkable.',   '2024-04-24'),
(31, 17,  3, 4, 4, 5, 4, 'Great condo in Midtown. Marcus was responsive and the rooftop view was a nice surprise.',                       '2024-01-30'),
(32, 17, 10, 3, 3, 5, 3, 'Location is excellent but the unit needed some maintenance. AC was noisy and one of the burners didn''t work.',  '2024-03-17'),
(33, 18,  7, 5, 5, 4, 5, 'The bungalow was gorgeous — original hardwood floors and a huge porch. Marcus was an excellent host.',          '2024-02-14'),
(34, 18,  1, 4, 4, 4, 4, 'Charming home with lots of character. The neighborhood is quieter than expected which was a nice change.',      '2024-04-07'),
(35, 19,  4, 5, 5, 5, 4, 'Waking up to that ocean view every morning was priceless. Hana left fresh fruit which was such a lovely touch.','2024-02-05'),
(36, 19, 16, 4, 4, 5, 3, 'Great location in Waikiki — everything within walking distance. The studio is compact but well designed.',       '2024-03-27'),
(37, 20,  5, 5, 5, 5, 5, 'The Kailua villa exceeded every expectation. The private pool, the garden, the beach access — absolutely flawless.', '2024-02-25'),
(38, 20,  8, 5, 5, 5, 4, 'Hana is the definition of a superhost. The villa is stunning and our group had the most memorable week.',       '2024-04-22');
