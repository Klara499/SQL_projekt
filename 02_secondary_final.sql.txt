-- 02_secondary_final.sql
-- Vytvoření finální tabulky t_klara_klimova_project_SQL_secondary_final
-- Obsah: evropské státy, HDP, GINI a populace
-- Použité období = roky, které existují v primární tabulce pro ČR

CREATE TABLE t_klara_klimova_project_SQL_secondary_final AS
SELECT
    e.year,
    c.country AS country_name,
    e.gdp,
    e.gini,
    e.population
FROM economies e
JOIN countries c 
    ON e.country = c.country
WHERE c.continent = 'Europe'
  AND e.year IN (
        SELECT DISTINCT year
        FROM t_klara_klimova_project_SQL_primary_final
      );
