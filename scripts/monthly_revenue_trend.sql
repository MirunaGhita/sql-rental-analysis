/*==========================================================================
4. Monthly Revenue Trend Report
Shows a month-by-month revenue report for 2024 (completed bookings only) broken down by city. 
Each row displays the city, month, total revenue, number of bookings, 
and a month_over_month_change column showing the revenue difference vs. the prior month for that city.
=============================================================================*/
WITH monthly_revenue AS (
    SELECT
        p.city,
        DATEPART(YEAR, b.check_in) AS booking_year,
        DATEPART(MONTH, b.check_in) AS booking_month,
        DATENAME(MONTH, b.check_in) AS month_name,
        SUM(b.total_amount) AS total_revenue,
        COUNT(b.booking_id) AS total_bookings
    FROM bookings b
    JOIN properties p ON b.property_id = p.property_id
    WHERE b.status = 'completed'
      AND YEAR(b.check_in) = 2024
    GROUP BY 
        p.city,
        DATEPART(YEAR, b.check_in),
        DATEPART(MONTH, b.check_in),
        DATENAME(MONTH, b.check_in)
)
SELECT
    city,
    month_name,
    booking_month,
    total_revenue,
    total_bookings,
    total_revenue - LAG(total_revenue) OVER (PARTITION BY city ORDER BY booking_month) AS month_over_month_change
FROM monthly_revenue
ORDER BY city, booking_month;
