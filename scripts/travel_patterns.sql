/*==========================================================================
3. Guest Travel Patterns
Finds all guests who have booked in more than one city. 
For each of those guests, shows every city they've stayed in, how many times they've visited each, and their total spend.
Adds a column showing their single highest-rated stay (property title + rating).
=============================================================================*/
WITH guest_city_counts AS (
    SELECT 
        g.guest_id,
        g.full_name,
        p.city,
        COUNT(b.booking_id) AS times_visited
    FROM guests g
    JOIN bookings b   ON g.guest_id = b.guest_id
    JOIN properties p ON b.property_id = p.property_id
    GROUP BY g.guest_id, g.full_name, p.city
),
multi_city_guests AS (
    SELECT guest_id
    FROM guest_city_counts
    GROUP BY guest_id
    HAVING COUNT(DISTINCT city) > 1
),
guest_spend AS (
    SELECT 
        g.guest_id,
        SUM(b.total_amount) AS total_spend
    FROM guests g
    JOIN bookings b ON g.guest_id = b.guest_id
    WHERE b.status = 'completed'
    GROUP BY g.guest_id
),
highest_rated_stay AS (
    SELECT
        g.guest_id,
        p.title,
        r.rating_overall,
        ROW_NUMBER() OVER (
            PARTITION BY g.guest_id
            ORDER BY r.rating_overall DESC
        ) AS rn
    FROM guests g
    JOIN bookings b   ON g.guest_id = b.guest_id
    JOIN properties p ON b.property_id = p.property_id
    JOIN reviews r    ON b.booking_id = r.booking_id
)
SELECT 
    gcc.full_name,
    gcc.city,
    gcc.times_visited,
    gs.total_spend,
    hrs.title AS highest_rated_property,
    hrs.rating_overall AS highest_rating
FROM guest_city_counts gcc
JOIN multi_city_guests mcg ON gcc.guest_id = mcg.guest_id
JOIN guest_spend gs        ON gcc.guest_id = gs.guest_id
LEFT JOIN highest_rated_stay hrs 
       ON gcc.guest_id = hrs.guest_id AND hrs.rn = 1
ORDER BY gcc.full_name, gcc.city;
