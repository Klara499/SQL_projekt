WITH cz_economy AS (
    SELECT year, gdp
    FROM economies
    WHERE country ILIKE 'Czech%'   
),

cz_prices AS (
    SELECT
        year,
        AVG(avg_price_item) AS avg_food_price,
        AVG(avg_salary_overall) AS avg_salary
    FROM t_klara_klimova_project_SQL_primary_final
    GROUP BY year
),

joined AS (
    SELECT
        p.year,
        p.avg_food_price,
        p.avg_salary,
        e.gdp,
        LAG(e.gdp) OVER (ORDER BY p.year) AS prev_gdp,
        LAG(p.avg_salary) OVER (ORDER BY p.year) AS prev_salary,
        LAG(p.avg_food_price) OVER (ORDER BY p.year) AS prev_price
    FROM cz_prices p
    JOIN cz_economy e
      ON p.year = e.year
),

growth AS (
    SELECT
        year,

        -- meziroční růst HDP v %
        (
            (gdp - prev_gdp)
            / NULLIF(prev_gdp, 0) * 100
        ) AS gdp_growth_raw,

        -- meziroční růst mezd v %
        (
            (avg_salary - prev_salary)
            / NULLIF(prev_salary, 0) * 100
        ) AS salary_growth_raw,

        -- meziroční růst cen jídla v %
        (
            (avg_food_price - prev_price)
            / NULLIF(prev_price, 0) * 100
        ) AS food_growth_raw
    FROM joined
)

SELECT
    year,
    ROUND(gdp_growth_raw::numeric, 2)     AS gdp_growth_pct,
    ROUND(salary_growth_raw::numeric, 2)  AS salary_growth_pct,
    ROUND(food_growth_raw::numeric, 2)    AS food_price_growth_pct
FROM growth
WHERE gdp_growth_raw IS NOT NULL
ORDER BY year;

