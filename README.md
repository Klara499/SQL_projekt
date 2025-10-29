# SQL_projekt

Tento projekt vznikl jako součást zadání kurzu SQL. Cílem je:

1. vytvořit sjednocený dataset pro Českou republiku, kde jsou po jednotlivých letech spojené
   - průměrné mzdy,
   - průměrné ceny potravin;
2. vytvořit dataset evropských zemí se základními socioekonomickými ukazateli (HDP, GINI, populace);
3. zodpovědět výzkumné otázky ohledně vývoje cen potravin, mezd a vlivu HDP.

---

## 1. Příprava dat

Nejprve jsem si pomocí jednoduchých dotazů `SELECT * FROM ... LIMIT ...` prohlédla strukturu zdrojových tabulek (`czechia_payroll`, `czechia_price`, `czechia_price_category`, `economies`, `countries`).  
To mi umožnilo:
- pochopit význam jednotlivých sloupců,
- ověřit existenci klíčových sloupců (rok, cena, název potraviny, typ mzdy),
- zkontrolovat, jak jsou data časově pokrytá.

Na základě toho jsem vytvořila dvě finální tabulky:
- `t_klara_klimova_project_SQL_primary_final` – Česká republika, mzdy + ceny potravin po letech,
- `t_klara_klimova_project_SQL_secondary_final` – evropské státy, makroekonomické ukazatele po letech.

---

## 2. Obsah souborů

### 01_primary_final.sql

Tento skript vytváří pomocné pohledy a následně finální tabulku  
`t_klara_klimova_project_SQL_primary_final`, která obsahuje pro Českou republiku:

- `year` – rok,
- `avg_salary_overall` – průměrnou mzdu (filtrováno na `calculation_code = 100` = průměr a `value_type_code = 5958` = přepočtený počet zaměstnanců),
- `food_name` – název potraviny,
- `avg_price_item` – průměrnou cenu této potraviny v daném roce.

#### Validace po vytvoření tabulky

Po vytvoření `t_klara_klimova_project_SQL_primary_final` jsem ověřila kvalitu dat těmito testovacími dotazy:

1. Náhled dat:
```sql
SELECT *
FROM t_klara_klimova_project_SQL_primary_final
ORDER BY year, food_name
LIMIT 20;
```

2. Počet řádků
```sql
   SELECT COUNT(*) AS pocet_radku
FROM t_klara_klimova_project_SQL_primary_final;
```
3. Časové pokrytí
```
SELECT 
    MIN(year) AS prvni_rok,
    MAX(year) AS posledni_rok,
    COUNT(DISTINCT year) AS pocet_let
FROM t_klara_klimova_project_SQL_primary_final;
```

4. Kolik různých potravin sledujeme
```
SELECT 
    COUNT(DISTINCT food_name) AS pocet_potravin
FROM t_klara_klimova_project_SQL_primary_final;
```
```
SELECT DISTINCT food_name
FROM t_klara_klimova_project_SQL_primary_final
ORDER BY food_name;
```

5. Kontrola ekonomické interpretace – kolik jednotek dané potraviny lze koupit z průměrné mzdy v posledním dostupném roce
Abych ověřila, že výsledná tabulka `t_klara_klimova_project_SQL_primary_final` dává ekonomicky smysl, spočítala jsem pro poslední dostupný rok, kolik jednotek dané potraviny je možné koupit z průměrné mzdy.

Postup:
- pro každý řádek (potravina v daném roce) jsem vzala `avg_salary_overall` (průměrná mzda),
- vydělila jsem ji `avg_price_item` (průměrná cena dané potraviny),
- vznikl ukazatel `kolik_mohu_koupit`, tedy kolik litrů/kg/kusů dané potraviny odpovídá jedné průměrné hrubé mzdě.

To slouží jako sanity check:
- pokud mi vyjdou hodnoty v řádu stovek nebo tisíc kusů (např. kolik bochníků chleba lze koupit z průměrné mzdy), je to realistické,
- pokud by vycházely extrémně nízké nebo extrémně vysoké hodnoty (např. 0.01 kusu nebo 1 000 000 kusů), znamenalo by to chybu v ceně, v mzdě nebo v jednotkách měření.

Použitý SQL dotaz:
```sql
WITH posledni_rok AS (
    SELECT MAX(year) AS y
    FROM t_klara_klimova_project_SQL_primary_final
)
SELECT
    t.year,
    t.food_name,
    t.avg_salary_overall,
    t.avg_price_item,
    ROUND(t.avg_salary_overall / t.avg_price_item, 2) AS kolik_mohu_koupit
FROM t_klara_klimova_project_SQL_primary_final t
JOIN posledni_rok p ON t.year = p.y
ORDER BY kolik_mohu_koupit DESC
LIMIT 20;
WITH posledni_rok AS (
    SELECT MAX(year) AS y
    FROM t_klara_klimova_project_SQL_primary_final
)
SELECT
    t.year,
    t.food_name,
    t.avg_salary_overall,
    t.avg_price_item,
    ROUND(t.avg_salary_overall / t.avg_price_item, 2) AS kolik_mohu_koupit
FROM t_klara_klimova_project_SQL_primary_final t
JOIN posledni_rok p ON t.year = p.y
ORDER BY kolik_mohu_koupit DESC
LIMIT 20;
```
6. Kontrola chybějících hodnot
 ```
SELECT
    SUM(CASE WHEN year IS NULL THEN 1 ELSE 0 END) AS nul_year,
    SUM(CASE WHEN avg_salary_overall IS NULL THEN 1 ELSE 0 END) AS nul_salary,
    SUM(CASE WHEN food_name IS NULL THEN 1 ELSE 0 END) AS nul_food,
    SUM(CASE WHEN avg_price_item IS NULL THEN 1 ELSE 0 END) AS nul_price
FROM t_klara_klimova_project_SQL_primary_final;
```
7. Kontrola chybějících hodnot
```
SELECT DISTINCT year
FROM t_klara_klimova_project_SQL_primary_final
ORDER BY year;
```

Výsledná tabulka obsahuje 342 řádků. Sledujeme období od 2006 do 2018. Sledujeme celekem 27 potravin. Pro otázku 2 ("mléko" a "chléb") zjišťuji přesný text názvu, takže když to pak bude třeba Chléb konzumní kmínový místo jen chléb, upravíme si ILIKE '%chléb%' podle reality.

##### Poznámky a metodika

Zdrojová data z tabulek (czechia_payroll, czechia_price, czechia_price_category, economies, countries) nejsou nijak upravována. Vytvářím pouze nové pohledy a tabulky.
Agregace mezd používá:
calculation_code = 100 → průměr,
value_type_code = 5958 → přepočtený počet zaměstnanců (tj. mzda na FTE).
Ceny potravin jsou průměrné roční ceny spočítané z tabulky czechia_price, zprůměrované podle kategorie potraviny.
Obě výstupní tabulky (t_klara_klimova_project_SQL_primary_final a t_klara_klimova_project_SQL_secondary_final) jsou podkladem pro analýzy.

###### Výzkumné otázky

1) Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
  Mzdy od roku 2000 do roku 2021 rostly ve všech odvětvích, žádný sektor neklesl.
  Největší relativní růst mezd se odehrál v sektorech veřejných služeb (zdravotnictví, školství, sociální oblast), tedy tam, kde byly výchozí mzdy nejnižší.
  Nejmenší růst byl v těžbě a některých tradičních odvětvích.
  IT, energetika a finance mají výrazně nejvyšší přírůstky i v absolutních částkách, což odráží ekonomický vývoj směrem k technologiím, energetické infrastruktuře a znalostním službám.

2) Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
  Pro výpočet jsem vzala průměrnou mzdu v daném roce a vydělila ji průměrnou cenou dané potraviny (chléb, mléko). Tím dostaneme, kolik kilogramů chleba nebo litrů mléka je možné si teoreticky koupit z jedné průměrné mzdy.
  Výsledky ukazují:
  Chléb konzumní kmínový
  2006: z průměrné mzdy šlo koupit ~1257 kg chleba
  2018: z průměrné mzdy šlo koupit ~1317 kg chleba
  změna: +4,8 %
  
  Mléko polotučné pasterované
  2006: z průměrné mzdy šlo koupit ~1404 litrů mléka
  2018: z průměrné mzdy šlo koupit ~1611 litrů mléka
  změna: +14,8 %
  
3) Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
  Pro každou potravinu byl spočítán meziroční procentní nárůst ceny:
    vezme se průměrná cena potraviny v roce t,
    porovná se s průměrnou cenou v roce t-1,
    vypočítá se meziroční růst v %.
  Tyto meziroční růsty se pak zprůměrovaly napříč všemi roky, které máme k dispozici. Dostaneme tak ukazatel avg_yoy_growth = “typický meziroční růst ceny” u dané potraviny.

  TOP 5 potravin s nejnižším (nejpomalejším) růstem cen:
    Cukr krystalový: průměrná změna ceny −1,92 % ročně
    Rajská jablka červená kulatá: −0,74 % ročně
    Banány žluté: +0,81 % ročně
    Vepřová pečeně s kostí: +0,99 % ročně
    Přírodní minerální voda uhličitá: +1,02 % ročně
   
4) Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
Postup výpočtu:
  Nejprve jsem pro každý rok spočítala:
    průměrnou cenu „košíku potravin“ (průměrná cena všech sledovaných potravin v daném roce),
    průměrnou mzdu za daný rok.
  Následně jsem spočítala meziroční procentní růst obou veličin:
    food_growth = procentní růst cen potravin oproti předchozímu roku,
    salary_growth = procentní růst průměrné mzdy oproti předchozímu roku.
  Do finálního kroku jsem zahrnula jen ty roky, kde platí
    (food_growth - salary_growth) > 10,
    tedy situace, kdy ceny potravin zdražily aspoň o 10 procentních bodů rychleji než mzdy.
  Výsledek dotazu nevrátil žádný řádek.

5) Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
  gdp_growth_pct = meziroční růst HDP (%)
  salary_growth_pct = meziroční růst průměrné mzdy (%)
  food_price_growth_pct = meziroční růst průměrné ceny potravinového koše (%)
Pro Českou republiku jsem pro jednotlivé roky spočítala meziroční růst tří veličin:
  HDP (gdp_growth_pct),
  průměrné mzdy (salary_growth_pct),
  průměrné ceny potravinového koše (food_price_growth_pct).
Vztah mezi HDP a mzdami je poměrně těsný: silnější růst HDP většinou znamená rychlejší růst mezd, případně aspoň nezáporný růst mezd.
Vztah mezi HDP a cenami potravin je slabší a méně stabilní. Ceny potravin někdy rostou i v letech, kdy ekonomika stagnuje nebo klesá (např. 2012), a někdy naopak klesají i v krizi (2009).
To znamená, že růst HDP se promítá spíš do růstu mezd než přímo do cen potravin. Dopad na kupní sílu domácností tak závisí na dvou věcech zároveň: jak rychle rostou mzdy a jak rychle zdražují potraviny.

####### Shrnutí

Projekt propojil data z několika veřejných datasetů a umožnil kvantitativně zhodnotit:
  dlouhodobý růst mezd ve všech odvětvích,
  vývoj kupní síly vůči základním potravinám,
  cenovou stabilitu potravin,
  vztah mezi ekonomickým růstem a výdaji domácností.
Výsledky ukazují, že česká ekonomika mezi lety 2000–2018 zaznamenala růst mezd napříč všemi sektory a současně zlepšení dostupnosti základních potravin.


