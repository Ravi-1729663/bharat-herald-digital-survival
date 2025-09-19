/* ================================================================
   1: Monthly Circulation Drop Check 
   Generate a report showing the top 3 months (2019–2024) where any 
   city recorded the sharpest month-over-month decline in net_circulation.
   Fields: city_name, month (YYYY-MM), net_circulation
================================================================ */
WITH mom AS (
    SELECT 
        city_id,
        month,
        net_circulation,
        LAG(net_circulation, 1) OVER (PARTITION BY city_id ORDER BY month) AS prev_month,
        net_circulation - LAG(net_circulation, 1) OVER (PARTITION BY city_id ORDER BY month) AS mom,
        COALESCE(
            (net_circulation - LAG(net_circulation, 1, 0) OVER (PARTITION BY city_id ORDER BY month)) 
            / NULLIF(LAG(net_circulation, 1, 0) OVER (PARTITION BY city_id ORDER BY month), 0),
            0
        ) * 100 AS mom_per
    FROM fact_print_sales
)
SELECT 
    c.city AS city_name,
    DATE_FORMAT(m.month, "%Y-%m") AS month,
    m.net_circulation
FROM mom AS m
INNER JOIN dim_city AS c ON m.city_id = c.city_id
ORDER BY m.mom_per
LIMIT 3;

/* ================================================================
   2: Yearly Revenue Concentration by Category 
   Identify ad categories that contributed > 50% of total yearly ad revenue.
   Fields: year, category_name, category_revenue, total_revenue_year, pct_of_year_total
================================================================ */
WITH yearly_revenue AS (
    SELECT 
        LEFT(quarter, 4) AS year,
        ad_category_id,
        SUM(ad_revenue_inINR) OVER (PARTITION BY LEFT(quarter, 4)) AS total_revenue_year,
        SUM(ad_revenue_inINR) OVER (PARTITION BY ad_category_id, LEFT(quarter, 4)) AS category_revenue
    FROM fact_ad_revenue
)
SELECT 
    year,
    d.standard_ad_category AS category_name,
    category_revenue,
    total_revenue_year,
    COALESCE(category_revenue / total_revenue_year, 0) * 100 AS pct_of_year_total
FROM yearly_revenue AS y
INNER JOIN dim_ad_category AS d ON y.ad_category_id = d.ad_category_id
WHERE category_revenue > 0.5 * total_revenue_year;

/* ================================================================
   3: 2024 Print Efficiency Leaderboard 
   Rank cities by print efficiency = net_circulation / copies_printed (Top 5 only)
================================================================ */
WITH efficiency_year_2024 AS (
    SELECT 
        city_id,
        SUM(copies_sold) AS copies_printed_2024,
        SUM(net_circulation) AS net_circulation_2024,
        NULLIF(SUM(net_circulation) / SUM(copies_sold), 0) AS efficiency_ratio
    FROM fact_print_sales
    WHERE month BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY city_id
), leader_board AS (
    SELECT 
        d.city AS city_name,
        e.copies_printed_2024,
        e.net_circulation_2024,
        e.efficiency_ratio,
        DENSE_RANK() OVER (ORDER BY efficiency_ratio DESC) AS efficiency_rank_2024
    FROM efficiency_year_2024 AS e
    INNER JOIN dim_city AS d ON e.city_id = d.city_id
)
SELECT *
FROM leader_board
WHERE efficiency_rank_2024 <= 5;

/* ================================================================
   4: Internet Readiness Growth (2021)
   Find the city with highest improvement in internet penetration 
   from Q1-2021 to Q4-2021.
================================================================ */
SELECT 
    f1.city_id,
    d.city AS city_name,
    f1.internet_penetration AS internet_rate_q1_2021,
    f2.internet_penetration AS internet_rate_q4_2021,
    f2.internet_penetration - f1.internet_penetration AS delta_internet_rate
FROM fact_city_readiness AS f1
INNER JOIN fact_city_readiness AS f2
    ON f1.city_id = f2.city_id 
   AND f1.quarter = '2021-Q1' 
   AND f2.quarter = '2021-Q4'
INNER JOIN dim_city AS d ON f1.city_id = d.city_id
ORDER BY delta_internet_rate DESC
LIMIT 1;

/* ================================================================
   5: Consistent Multi-Year Decline (2019→2024)
   Find cities where both net_circulation and ad_revenue strictly 
   decreased every year between 2019 and 2024.
================================================================ */
WITH net_circulation_year_city AS (
    SELECT city_id, YEAR(month) AS year, SUM(net_circulation) AS total_net_circulation
    FROM fact_print_sales
    WHERE YEAR(month) BETWEEN 2019 AND 2024
    GROUP BY city_id, YEAR(month)
), ad_revenue_year_city AS (
    SELECT city_id, LEFT(quarter, 4) AS year, SUM(ad_revenue_inINR) AS total_ad_revenue
    FROM fact_ad_revenue
    WHERE LEFT(quarter, 4) BETWEEN '2019' AND '2024'
    GROUP BY city_id, LEFT(quarter, 4)
), combined AS (
    SELECT  
        d.city,
        n.year,
        n.total_net_circulation,
        a.total_ad_revenue
    FROM net_circulation_year_city AS n
    INNER JOIN ad_revenue_year_city AS a
        ON n.city_id = a.city_id AND n.year = a.year
    INNER JOIN dim_city AS d ON n.city_id = d.city_id
), with_flags AS (
    SELECT 
        c.*,
        LAG(total_net_circulation, 1) OVER (PARTITION BY city ORDER BY year) AS prev_total_net_circulation,
        LAG(total_ad_revenue, 1) OVER (PARTITION BY city ORDER BY year) AS prev_total_ad_revenue,
        CASE 
            WHEN LAG(total_net_circulation, 1) OVER (PARTITION BY city ORDER BY year) IS NULL THEN 1
            WHEN total_net_circulation < LAG(total_net_circulation, 1) OVER (PARTITION BY city ORDER BY year) THEN 1
            ELSE 0
        END AS net_decline_flag,
        CASE 
            WHEN LAG(total_ad_revenue, 1) OVER (PARTITION BY city ORDER BY year) IS NULL THEN 1
            WHEN total_ad_revenue < LAG(total_ad_revenue, 1) OVER (PARTITION BY city ORDER BY year) THEN 1
            ELSE 0
        END AS ad_decline_flag
    FROM combined AS c
), city_summary AS (
    SELECT 
        city,
        COUNT(*) AS total_years,
        SUM(net_decline_flag) AS years_net_declined,
        SUM(ad_decline_flag) AS years_ad_declined
    FROM with_flags
    GROUP BY city
)
SELECT 
    w.city,
    w.year,
    w.total_net_circulation,
    w.total_ad_revenue,
    CASE WHEN cs.years_net_declined = cs.total_years THEN 'Yes' ELSE 'No' END AS is_declining_print,
    CASE WHEN cs.years_ad_declined = cs.total_years THEN 'Yes' ELSE 'No' END AS is_declining_ad_revenue,
    CASE WHEN cs.years_net_declined = cs.total_years 
           AND cs.years_ad_declined = cs.total_years THEN 'Yes' ELSE 'No' END AS is_declining_both
FROM with_flags AS w
JOIN city_summary AS cs ON w.city = cs.city
ORDER BY w.city, w.year;

/* ================================================================
   6: 2021 Digital Readiness vs. Engagement Outlier 
   Find city with highest readiness but among bottom 3 in engagement.
================================================================ */
WITH readiness AS (
    SELECT  
        f.city_id,
        c.city,
        ROUND(AVG((literacy_rate + smartphone_penetration + internet_penetration) / 3), 3) AS readiness_score_2021
    FROM fact_city_readiness AS f
    INNER JOIN dim_city AS c ON f.city_id = c.city_id
    WHERE LEFT(quarter, 4) = '2021'
    GROUP BY f.city_id, c.city
), engagement AS (
    SELECT
        city_id,
        ROUND(AVG(avg_bounce_rate), 3) AS engagement_metric_2021
    FROM fact_digital_pilot
    WHERE LEFT(launch_month, 4) = '2021'
    GROUP BY city_id
), combined AS (
    SELECT 
        r.city,
        readiness_score_2021,
        engagement_metric_2021,
        DENSE_RANK() OVER (ORDER BY readiness_score_2021 DESC) AS readiness_rank_desc,
        DENSE_RANK() OVER (ORDER BY engagement_metric_2021 DESC) AS engagement_rank_asc
    FROM readiness AS r 
    INNER JOIN engagement AS e ON r.city_id = e.city_id
)
SELECT  
    *,
    CASE 
        WHEN readiness_rank_desc = 1 AND engagement_rank_asc <= 3 THEN 'Yes' 
        ELSE 'No' 
    END AS is_outlier
FROM combined;
