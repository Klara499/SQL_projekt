-- 06_question_4.sql
-- Roky, kdy ceny potravin rostly o více než 10 p.b. rychleji než mzdy

WITH food_per_year AS (
    -- průměrná cena potravinového koše za rok
    SELECT
        year,
        AVG(avg_price_item) AS avg_food_price
    FROM t_klara_klimova_project_SQL_primary_final
    GROUP BY year
),
salary_per_year AS (
    -- průměrná mzda za rok
    SELECT
        year,
        AVG(avg_salary_overall) AS avg_salary
    FROM t_klara_klimova_project_SQL_primary_final
    GROUP BY year
),
joined AS (
    -- spojíme ceny potravin a mzdu do jedné řádky na rok
    SELECT
        f.year,
        f.avg_food_price,
        s.avg_salary
    FROM food_per_year f
    JOIN salary_per_year s
      ON f.year = s.year
),
growth AS (
    -- spočítáme meziroční růsty v procentech
    SELECT
        year,
        ROUND(
            (avg_food_price - LAG(avg_food_price) OVER (ORDER BY year))
            / NULLIF(LAG(avg_food_price) OVER (ORDER BY year), 0) * 100
        , 2) AS food_growth,
        ROUND(
            (avg_salary - LAG(avg_salary) OVER (ORDER BY year))
            / NULLIF(LAG(avg_salary) OVER (ORDER BY year), 0) * 100
        , 2) AS salary_growth
    FROM joined
)
SELECT
    year,
    food_growth,
    salary_growth,
    (food_growth - salary_growth) AS diff_pct_points
FROM growth
WHERE food_growth IS NOT NULL
  AND salary_growth IS NOT NULL
  AND (food_growth - salary_growth) > 10
ORDER BY diff_pct_points DESC;
