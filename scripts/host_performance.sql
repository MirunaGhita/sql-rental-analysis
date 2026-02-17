/*==================================================================================================================
  1. Host Performance Dashboard
  Ranks all hosts by total revenue earned from completed bookings. 
  Includes their number of listings, average property rating, cancellation rate,
  and label that flags them as 'Superhost' or 'Standard'.
==================================================================================================================*/

SELECT
    h.full_name,
    CASE WHEN h.is_superhost = 1 THEN 'Superhost' ELSE 'Standard' END AS host_type,
    COUNT(DISTINCT p.property_id) AS total_listings,
    SUM(CASE WHEN b.status = 'completed' THEN b.total_amount ELSE 0 END) AS total_revenue,
    ROUND(AVG(CAST(r.rating_overall AS FLOAT)), 2) AS avg_rating,
    ROUND(
        CAST(SUM(CASE WHEN b.status = 'cancelled' THEN 1 ELSE 0 END) AS FLOAT) 
        / NULLIF(COUNT(b.booking_id), 0) * 100, 2
    ) AS cancellation_rate_pct
FROM hosts h
LEFT JOIN properties p  ON h.host_id      = p.host_id
LEFT JOIN bookings b    ON p.property_id  = b.property_id
LEFT JOIN reviews r     ON b.booking_id   = r.booking_id
GROUP BY h.full_name, h.is_superhost
ORDER BY total_revenue DESC;

