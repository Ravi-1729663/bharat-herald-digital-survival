
Business Request 1: Monthly Circulation Drop Check

Generate a report showing the top 3 months (2019–2024) where any city recorded the sharpest month-over-month decline in net_circulation.

Fields:

city_name

month (YYYY-MM)

net_circulation

Business Request 2: Yearly Revenue Concentration by Category

Identify ad categories that contributed > 50% of total yearly ad revenue.

Fields:

year

category_name

category_revenue

total_revenue_year

pct_of_year_total

Business Request 3: 2024 Print Efficiency Leaderboard

For 2024, rank cities by print efficiency = net_circulation / copies_printed. Return top 5.

Fields:

city_name

copies_printed_2024

net_circulation_2024

efficiency_ratio (net_circulation_2024 / copies_printed_2024)

efficiency_rank_2024

Business Request 4: Internet Readiness Growth (2021)

For each city, compute the change in internet penetration from Q1-2021 to Q4-2021 and identify the city with the highest improvement.

Fields:

city_name

internet_rate_q1_2021

internet_rate_q4_2021

delta_internet_rate (internet_rate_q4_2021 − internet_rate_q1_2021)

Business Request 5: Consistent Multi-Year Decline (2019→2024)

Find cities where both net_circulation and ad_revenue decreased every year from 2019 through 2024 (strictly decreasing sequences).

Fields:

city_name

year

yearly_net_circulation

yearly_ad_revenue

is_declining_print (Yes/No per city over 2019–2024)

is_declining_ad_revenue (Yes/No)

is_declining_both (Yes/No)

Business Request 6: 2021 Readiness vs Pilot Engagement Outlier

In 2021, identify the city with the highest digital readiness score but among the bottom 3 in digital pilot engagement.

Formula:

readiness_score = AVG(smartphone_rate, internet_rate, literacy_rate)

Fields:

city_name

readiness_score_2021

engagement_metric_2021

readiness_rank_desc

engagement_rank_asc

is_outlier (Yes/No)
