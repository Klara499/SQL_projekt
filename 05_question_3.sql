-- 05_question_3.sql
-- Potraviny s nejnižším průměrným meziročním nárůstem ceny

WITH base AS (
    SELECT
        year,
        food_name,
        avg_price_item,
        LAG(avg_price_item) OVER (PARTITION BY food_name ORDER BY year) AS prev_price
    FROM t_klara_klimova_project_SQL_primary_final
),
growth AS (
    SELECT
        food_name,
        ROUND((avg_price_item - prev_price) / NULLIF(prev_price,0) * 100, 2) AS yoy_growth
    FROM base
    WHERE prev_price IS NOT NULL
)
SELECT
    food_name,
    ROUND(AVG(yoy_growth), 2) AS avg_yoy_growth
FROM growth
GROUP BY food_name
ORDER BY avg_yoy_growth ASC
LIMIT 5;
