-- 04_question_2.sql
-- Kolik lze koupit mléka a chleba za průměrnou mzdu

WITH bounds AS (
    SELECT MIN(year) AS first_year, MAX(year) AS last_year
    FROM t_klara_klimova_project_SQL_primary_final
),
filtered AS (
    SELECT
        year,
        avg_salary_overall,
        food_name,
        avg_price_item
    FROM t_klara_klimova_project_SQL_primary_final
    WHERE food_name ILIKE '%léko%' OR food_name ILIKE '%chléb%'
),
calc AS (
    SELECT
        year,
        food_name,
        ROUND(avg_salary_overall / avg_price_item, 2) AS units_affordable
    FROM filtered
)
SELECT
    c1.food_name,
    c1.year AS first_year,
    c1.units_affordable AS qty_first,
    c2.year AS last_year,
    c2.units_affordable AS qty_last,
    ROUND((c2.units_affordable - c1.units_affordable)/NULLIF(c1.units_affordable,0)*100,2) AS pct_change
FROM calc c1
JOIN calc c2 
  ON c1.food_name = c2.food_name
JOIN bounds b 
  ON c1.year = b.first_year AND c2.year = b.last_year
ORDER BY food_name;
