/*==========================================================================
5. Amenity Impact on Ratings

Finds out which amenities correlate with higher average ratings. 
For each amenity, calculates the average rating_overall across all reviewed properties that have it, 
and compares it against the platform-wide average. 
Returns the results ordered by the difference between the amenity's average and the global average.
=============================================================================*/
WITH global_avg AS (
    SELECT 
        AVG(CAST(r.rating_overall AS FLOAT)) AS platform_avg_rating
    FROM reviews r
),
amenity_avg AS (
    SELECT
        a.name AS amenity_name,
        AVG(CAST(r.rating_overall AS FLOAT)) AS amenity_avg_rating
    FROM amenities a
    JOIN property_amenities pa ON a.amenity_id = pa.amenity_id
    JOIN properties p          ON pa.property_id = p.property_id
    JOIN bookings b            ON p.property_id = b.property_id
    JOIN reviews r             ON b.booking_id = r.booking_id
    GROUP BY a.name
)
SELECT
    aa.amenity_name,
    ROUND(aa.amenity_avg_rating, 2) AS amenity_avg_rating,
    ROUND(ga.platform_avg_rating, 2) AS platform_avg_rating,
    ROUND(aa.amenity_avg_rating - ga.platform_avg_rating, 2) AS rating_difference
FROM amenity_avg aa
CROSS JOIN global_avg ga
ORDER BY rating_difference DESC;
