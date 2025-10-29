-- 03_question_1.sql
-- Růst mezd ve všech odvětvích podle czechia_payroll

WITH payroll_industry AS (
    SELECT
        payroll_year AS year,
        industry_branch_code,
        ROUND(AVG(value)::numeric, 2) AS avg_salary
    FROM czechia_payroll
    WHERE calculation_code = 100 AND value_type_code = 5958
    GROUP BY payroll_year, industry_branch_code
),
with_names AS (
    SELECT
        p.year,
        i.name AS industry_name,
        p.avg_salary
    FROM payroll_industry p
    JOIN czechia_payroll_industry_branch i ON p.industry_branch_code = i.code
),
first_last AS (
    SELECT
        industry_name,
        MIN(year) AS first_year,
        MAX(year) AS last_year
    FROM with_names
    GROUP BY industry_name
)
SELECT
    w1.industry_name,
    w1.year AS first_year,
    w1.avg_salary AS salary_first,
    w2.year AS last_year,
    w2.avg_salary AS salary_last,
    ROUND(w2.avg_salary - w1.avg_salary, 2) AS abs_change,
    ROUND((w2.avg_salary - w1.avg_salary) / NULLIF(w1.avg_salary,0) * 100, 2) AS pct_change
FROM with_names w1
JOIN with_names w2
  ON w1.industry_name = w2.industry_name
 AND w1.year = (SELECT MIN(year) FROM with_names)
 AND w2.year = (SELECT MAX(year) FROM with_names)
ORDER BY pct_change DESC;
