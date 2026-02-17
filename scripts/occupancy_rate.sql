/*=========================================================================================
 2. Occupancy Rate by Property
Calculates each property's 2024 occupancy
Showing title, city, price, and average reviews. 
Compares each property against the platform average.
===========================================================================================*/

WITH occupancy AS (
    SELECT
        p.property_id,
        p.title,
        p.city,
        p.price_per_night,
        ROUND(AVG(CAST(r.rating_overall AS FLOAT)), 2) AS avg_rating,
        ROUND(
            CAST(SUM(
                CASE 
                    WHEN b.status = 'completed' AND YEAR(b.check_in) = 2024
                    THEN DATEDIFF(DAY, b.check_in, b.check_out)
                    ELSE 0
                END
            ) AS FLOAT) / 365 * 100, 2
        ) AS occupancy_rate_pct
    FROM properties p
    LEFT JOIN bookings b ON p.property_id = b.property_id
    LEFT JOIN reviews r  ON b.booking_id  = r.booking_id
    GROUP BY p.property_id, p.title, p.city, p.price_per_night
)
SELECT
    *,
    CASE 
    WHEN occupancy_rate_pct < AVG(occupancy_rate_pct) OVER () THEN 'Below Average'
    ELSE 'Above Average'
END AS performance_label
FROM occupancy
ORDER BY occupancy_rate_pct DESC;
