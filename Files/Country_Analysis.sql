##### Country Analysis Project
# 

## Table of Contents
# 0. Define Question
# 1. Data Import
# 2. Data Cleaning
# 3. Data Exploration

-- --------------------------------------------------------------------------------------------------------------
##### 0. Define Question
# This analysis will focus on answering the following questions:
-- 

-- --------------------------------------------------------------------------------------------------------------
##### 1. Data Import

CREATE database country_analysis;

# Using the Table Data Import Wizard, we import our three CSV files.alter
DESCRIBE `world-data-2023`;
DESCRIBE `quality_of_life`;
DESCRIBE `world_rankings`;

# Fix table name formatting.
ALTER TABLE `world-data-2023` RENAME to `world_data_2023`;

# Reviewed data in CSV file for our `world_rankings` table.
# Dataset bloated and irrelevant, only imported 50 rows out of over 800.
DROP TABLE world_rankings;

# Innitial glance at data.
SELECT * FROM quality_of_life;
SELECT * FROM world_data_2023;

-- --------------------------------------------------------------------------------------------------------------
##### 2. Data Cleaning

### A. Create backup tables for our RAW data. 
# Upload CSV files again, naming new tables with "_staging" suffix.
# Check data integrity & column names. All looks good.
DESCRIBE quality_of_life_staging;
DESCRIBE world_data_2023_staging;
SELECT * FROM quality_of_life_staging;
SELECT * FROM world_data_2023_staging;

### B. Find Duplicates (two alternate methods).
SELECT country, count(country)
FROM quality_of_life
GROUP BY country
HAVING count(country) > 1;

SELECT *
FROM (SELECT country, ROW_NUMBER() OVER(PARTITION BY country) row_num
	FROM world_data_2023) duplicates_check
WHERE row_num > 1;

# If we had duplicates, we could filter them out using this method:
DELETE FROM quality_of_life
WHERE country IN (
	SELECT country, count(country)
	FROM quality_of_life
	GROUP BY country
	HAVING count(country) > 1
);

### C. Standardizing Data (Quality_of_Life Table)
SELECT * FROM quality_of_life;
DESCRIBE quality_of_life;

# Notes:
-- Looks like there are no blank values.
-- `Property Price to Income Value` has a few values longer than 2 decimals. (Will Round)
-- `Climate Value` for Mongolia is -3.54 , unsure why. (Will remove for this analysis)
-- `Quality of Life Value` values contain ': ' when not 0.0. (Will Update)
-- 0s that represent missing data should be NULLS (Will Update)

# `Property Price to Income Value` Rounding
UPDATE quality_of_life
SET `Property Price to Income Value` = ROUND(`Property Price to Income Value`, 2);

# `Quality of Life Category` Cleaning & Updating Data Type
UPDATE quality_of_life
SET `Quality of Life Value` = TRIM(Replace(`Quality of Life Value`, ': ', ''))
WHERE `Quality of Life Value` LIKE ': %';

# `Climate Value` removal for Mongolia
UPDATE quality_of_life
SET `Climate Value` = NULL
WHERE Country = 'Mongolia';

UPDATE quality_of_life
SET `Climate Category` = 'None'
WHERE `Climate Value` IS NULL;

# Replacing 0s with NULLs for more accurate analysis
UPDATE quality_of_life
SET `Purchasing Power Value` = NULL
WHERE `Purchasing Power Value` = 0;

UPDATE quality_of_life
SET `Safety Value` = NULL
WHERE `Safety Value` = 0;

UPDATE quality_of_life
SET `Health Care Value` = NULL
WHERE `Health Care Value` = 0;

UPDATE quality_of_life
SET `Climate Value` = NULL
WHERE `Climate Value` = 0;

UPDATE quality_of_life
SET `Cost of Living Value` = NULL
WHERE `Cost of Living Value` = 0;

UPDATE quality_of_life
SET `Property Price to Income Value` = NULL
WHERE `Property Price to Income Value` = 0;

UPDATE quality_of_life
SET `Traffic Commute Time Value` = NULL
WHERE `Traffic Commute Time Value` = 0;

UPDATE quality_of_life
SET `Pollution Value` = NULL
WHERE `Pollution Value` = 0;

UPDATE quality_of_life
SET `Quality of Life Value` = NULL
WHERE `Quality of Life Value` = 0.0;

SELECT * FROM quality_of_life;

# Updating "Category" fields to align with NULLs.
UPDATE quality_of_life
SET `Property Price to Income Category` = 'None'
WHERE `Property Price to Income Value` IS NULL;

UPDATE quality_of_life
SET `Traffic Commute Time Category` = 'None'
WHERE `Traffic Commute Time Value` IS NULL;

UPDATE quality_of_life
SET `Quality of Life Category` = 'None'
WHERE `Quality of Life Value` IS NULL;

# Changing Data Type for `Quality of Life Value`
ALTER TABLE quality_of_life
MODIFY COLUMN `Quality of Life Value` DOUBLE;

SELECT * FROM quality_of_life;
DESCRIBE quality_of_life;
-- This table looks ready to use now.


### D. Standardizing Data (World_Data_2023 Table)
SELECT * FROM world_data_2023;
DESCRIBE world_data_2023;

# Notes:
-- There are blanks in many columns. (Will set to NULL)
-- Many of our numeric columns use the TEXT type. (Will Modify)
-- `Capital/Major City` and `Largest city` have some values containing 'ï¿½'. (Will Update)

# Populating Abbreviations
UPDATE world_data_2023
SET Abbreviation = 
CASE 
	WHEN country = 'Republic of the Congo' THEN 'CG'
    WHEN country = 'Republic of Ireland' THEN 'IE'
    WHEN country = 'Namibia' THEN 'NA'
    ELSE abbreviation
END;

# Forgot "Else abbreviation" in the above case statement. Repopulated data and ran again.
-- UPDATE world_data_2023 w
-- JOIN world_data_2023_staging s
-- ON w.country = s.country
-- SET w.Abbreviation = s.abbreviation;

# Updating City Names
Select Country, `Capital/Major City`, `Largest city`
FROM world_data_2023
WHERE `Capital/Major City` LIKE '%ï¿½%' OR `Capital/Major City` = '' 
OR `Largest city` LIKE '%ï¿½%' OR `Largest city` = ''
ORDER BY Country;

CREATE TEMPORARY TABLE temp_city_updates (
	country VARCHAR(50),
    `Capital/Major City` VARCHAR(50),
    `Largest city` VARCHAR(50)
);

INSERT INTO temp_city_updates VALUES
('Brazil', 'Brasília', 'São Paulo'),
('Brunei', 'Bandar Seri Begawan', 'Bandar Seri Begawan'),
('Cameroon', 'Yaoundé', 'Douala'),
('Colombia', 'Bogotá', 'Bogotá'),
('Costa Rica', 'San José', 'San José'),
('Cyprus', 'Nicosia', 'Nicosia'),
('Iceland', 'Reykjavík', 'Reykjavík'),
('Libya', 'Tripoli', 'Tripoli'),
('Moldova', 'Chișinău', 'Chișinău'),
('Paraguay', 'Asunción', 'Asunción'),
('Sweden', 'Stockholm', 'Stockholm'),
('Switzerland', 'Bern', 'Zürich'),
('Togo', 'Lomé', 'Lomé'),
('Tonga', 'Nukuʻalofa', 'Nukuʻalofa');

SELECT * FROM temp_city_updates;

UPDATE world_data_2023 w
JOIN temp_city_updates t
	ON t.country = w.country
SET w.`Capital/Major City` = t.`Capital/Major City`,
    w.`Largest city` = t.`Largest city`;

SELECT Country, `Capital/Major City`, `Largest city`
FROM world_data_2023;



# Updating Currency Codes
SELECT `country`, `currency-code`
FROM world_data_2023
WHERE `currency-code` = '';

CREATE TEMPORARY TABLE temp_currency_codes (
	country VARCHAR(50),
    currency_code VARCHAR(3)
);

INSERT INTO temp_currency_codes VALUES
('The Bahamas', 'BSD'),
('Bhutan', 'BTN'),
('Cambodia', 'KHR'),
('Central African Republic', 'XAF'),
('El Salvador', 'USD'),
('Japan', 'JPY'),
('Lesotho', 'LSL'),
('Liberia', 'LRD'),
('Namibia', 'NAD'),
('Netherlands', 'EUR'),
('Panama', 'PAB'),
('Zimbabwe', 'ZWL');

SELECT * FROM temp_currency_codes;

UPDATE world_data_2023 w
JOIN temp_currency_codes t
USING(country)
SET w.`currency-code` = t.currency_code;

SELECT Country, `currency-code` FROM world_data_2023;



## Standardizing Data, changing Data Types, and inserting NULLs
SELECT * FROM world_data_2023;
DESCRIBE world_data_2023;

# Need to change Percent % and Money $ columns to a format that calculations can be ran on.

# `Agricultural Land( %)`
SELECT TRIM('%' FROM `Agricultural Land( %)`) agricultural_land_no_percent
FROM world_data_2023;
UPDATE world_data_2023
SET `Agricultural Land( %)` = TRIM('%' FROM `Agricultural Land( %)`);
ALTER TABLE world_data_2023
CHANGE COLUMN `Agricultural Land( %)` `Agricultural Land(%)` INT;
-- Fixed Data Type as well as removing space before %

# `Land Area(Km2)`
UPDATE world_data_2023
SET `Land Area(Km2)` = TRIM(',' FROM `Land Area(Km2)`);
-- Did not work as intended. Trying a different method using REGEXP_REPLACE:
SELECT REGEXP_REPLACE(`Land Area(Km2)`, '[,]', '')
FROM world_data_2023;

UPDATE world_data_2023
SET `Land Area(Km2)` = REGEXP_REPLACE(`Land Area(Km2)`, '[,]', '');
ALTER TABLE world_data_2023
MODIFY COLUMN `Land Area(Km2)` INT;

# `Armed Forces Size`
UPDATE world_data_2023
SET `Armed Forces size` = NULLIF(`Armed Forces size`, '');
-- Not replacing 0s with NULL as these values could actually be 0.
UPDATE world_data_2023
SET `Armed Forces size` = REGEXP_REPLACE(`Armed Forces size`, '[,]', '');
ALTER TABLE world_data_2023
MODIFY COLUMN `Armed Forces size` INT;

# `Co2-Emissions`
UPDATE world_data_2023
SET `Co2-Emissions` = REGEXP_REPLACE(`Co2-Emissions`, '[,]', '');
UPDATE world_data_2023
SET `Co2-Emissions` = NULLIF(`Co2-Emissions`, '');
ALTER TABLE world_data_2023
MODIFY COLUMN `Co2-Emissions` INT;

# `CPI`
UPDATE world_data_2023
SET `CPI` = REGEXP_REPLACE(`CPI`, '[,]', '');
UPDATE world_data_2023
SET `CPI` = NULLIF(`CPI`, '');
ALTER TABLE world_data_2023
MODIFY COLUMN `CPI` DECIMAL(6, 2);

# Updating `CPI Change (%)` using CAST() and REPLACE()
UPDATE world_data_2023
SET `CPI Change (%)` = CAST(REPLACE(`CPI Change (%)`, '%', '') AS DOUBLE);
-- Tried "AS DECIMAL(5, 2)" but received an error. Switched to DOUBLE for this step.

# Made an error in the query below, making all values NULL. Repopulated the column using staging table.
-- UPDATE world_data_2023
-- SET `CPI Change (%)` = CAST(REPLACE(`CPI Change (%)`, '0', NULL) AS DECIMAL(5, 2));
UPDATE world_data_2023 w
JOIN world_data_2023_staging s
ON w.country = s.country
SET w.`CPI Change (%)` = s.`CPI Change (%)`;

# Data Type can not be changed using CAST(), used ALTER TABLE instead.
-- UPDATE world_data_2023
-- SET `CPI Change (%)` = CAST(REPLACE(`CPI Change (%)`, '%', '') AS DOUBLE);
-- UPDATE world_data_2023
-- SET `CPI Change (%)` = CAST(`CPI Change (%)` AS DECIMAL(5, 2));
UPDATE world_data_2023
SET `CPI Change (%)` = NULLIF(`CPI Change (%)`, '');
ALTER TABLE world_data_2023
MODIFY COLUMN `CPI Change (%)` DECIMAL(5, 2);
-- MUST insert NULLs BEFORE altering the table. This value can be equal to 0, and changing the Data Type to DECIMAL replaces blanks with 0s.

SELECT `CPI Change (%)` FROM world_data_2023;
SELECT `CPI Change (%)` FROM world_data_2023_staging;
-- Looks great!

# `Forested Area (%)`
UPDATE world_data_2023
SET `Forested Area (%)` = CAST(REPLACE(`Forested Area (%)`, '%', '') AS DECIMAL(5, 2));
UPDATE world_data_2023
SET `Forested Area (%)` = NULLIF(`Forested Area (%)`, '0.00');
ALTER TABLE world_data_2023
MODIFY COLUMN `Forested Area (%)` DECIMAL(5, 2);

# `Gasoline Price`
UPDATE world_data_2023
SET `Gasoline Price` = CAST(REPLACE(`Gasoline Price`, '$', '') AS DECIMAL(5, 2));
UPDATE world_data_2023
SET `Gasoline Price` = NULLIF(`Gasoline Price`, '0.00');
ALTER TABLE world_data_2023
MODIFY COLUMN `Gasoline Price` DECIMAL(5, 2);

# `GDP`
UPDATE world_data_2023
SET `GDP` = REGEXP_REPLACE(`GDP`, '[^0-9.]', '');
UPDATE world_data_2023
SET `GDP` = NULLIF(`GDP`, '0');
ALTER TABLE world_data_2023
MODIFY COLUMN `GDP` BIGINT;
-- Used REGEXP_REPLACE to remove all characters that were not (^) '0-9' or '.'
-- CAST() would not allow me to change the datatype to INTEGER or BIGINT. Used ALTER TABLE instead.

# `Gross primary education enrollment (%)`
UPDATE world_data_2023
SET `Gross primary education enrollment (%)` = REGEXP_REPLACE(`Gross primary education enrollment (%)`, '[^0-9.]', '');
UPDATE world_data_2023
SET `Gross primary education enrollment (%)` = NULLIF(`Gross primary education enrollment (%)`, '');
ALTER TABLE world_data_2023
MODIFY COLUMN `Gross primary education enrollment (%)` DECIMAL(5, 2);

# `Gross tertiary education enrollment (%)`
UPDATE world_data_2023
SET `Gross tertiary education enrollment (%)` = REGEXP_REPLACE(`Gross tertiary education enrollment (%)`, '[^0-9.]', '');
UPDATE world_data_2023
SET `Gross tertiary education enrollment (%)` = NULLIF(`Gross tertiary education enrollment (%)`, '');
ALTER TABLE world_data_2023
MODIFY COLUMN `Gross tertiary education enrollment (%)` DECIMAL(5, 2);

# `Life expectancy`
UPDATE world_data_2023
SET `Life expectancy` = NULLIF(`Life expectancy`, '');
ALTER TABLE world_data_2023
MODIFY COLUMN `Life expectancy` DECIMAL(5, 2);

# `Maternal mortality ratio`
UPDATE world_data_2023
SET `Maternal mortality ratio` = NULLIF(`Maternal mortality ratio`, '');
ALTER TABLE world_data_2023
MODIFY COLUMN `Maternal mortality ratio` INT;

# `Minimum wage`
UPDATE world_data_2023
SET `Minimum wage` = REGEXP_REPLACE(`Minimum wage`, '[^0-9.]', '');
UPDATE world_data_2023
SET `Minimum wage` = NULLIF(`Minimum wage`, '');
ALTER TABLE world_data_2023
MODIFY COLUMN `Minimum wage` DECIMAL(5,2);

# `Out of pocket health expenditure`
UPDATE world_data_2023
SET `Out of pocket health expenditure` = REGEXP_REPLACE(`Out of pocket health expenditure`, '[^0-9.]', '');
UPDATE world_data_2023
SET `Out of pocket health expenditure` = NULLIF(`Out of pocket health expenditure`, '');
ALTER TABLE world_data_2023
CHANGE COLUMN `Out of pocket health expenditure` `Out of pocket health expenditure (%)` DECIMAL(5,2);
-- Renamed with (%) for clarity.

# `Physicians per thousand`
ALTER TABLE world_data_2023
MODIFY COLUMN `Physicians per thousand` DECIMAL(5,2);

# `Population`
UPDATE world_data_2023
SET `Population` = REGEXP_REPLACE(`Population`, '[^0-9.]', '');
UPDATE world_data_2023
SET `Population` = NULLIF(`Population`, '');
ALTER TABLE world_data_2023
MODIFY COLUMN `Population` INT;

# `Population: Labor force participation (%)`
UPDATE world_data_2023
SET `Population: Labor force participation (%)` = REGEXP_REPLACE(`Population: Labor force participation (%)`, '[^0-9.]', '');
UPDATE world_data_2023
SET `Population: Labor force participation (%)` = NULLIF(`Population: Labor force participation (%)`, '');
ALTER TABLE world_data_2023
MODIFY COLUMN `Population: Labor force participation (%)` DECIMAL(5,2);

# `Tax revenue (%)`
UPDATE world_data_2023
SET `Tax revenue (%)` = REGEXP_REPLACE(`Tax revenue (%)`, '[^0-9.]', '');
UPDATE world_data_2023
SET `Tax revenue (%)` = NULLIF(`Tax revenue (%)`, '');
ALTER TABLE world_data_2023
MODIFY COLUMN `Tax revenue (%)` DECIMAL(5,2);

# `Total tax rate`
UPDATE world_data_2023
SET `Total tax rate` = REGEXP_REPLACE(`Total tax rate`, '[^0-9.]', '');
UPDATE world_data_2023
SET `Total tax rate` = NULLIF(`Total tax rate`, '');
ALTER TABLE world_data_2023
CHANGE COLUMN `Total tax rate` `Total tax rate (%)` DECIMAL(5,2);
-- Renamed with (%) for clarity.

# `Unemployment rate`
UPDATE world_data_2023
SET `Unemployment rate` = REGEXP_REPLACE(`Unemployment rate`, '[^0-9.]', '');
UPDATE world_data_2023
SET `Unemployment rate` = NULLIF(`Unemployment rate`, '');
ALTER TABLE world_data_2023
CHANGE COLUMN `Unemployment rate` `Unemployment rate (%)` DECIMAL(5,2);
-- Renamed with (%) for clarity.

# `Urban_population`
UPDATE world_data_2023
SET `Urban_population` = REGEXP_REPLACE(`Urban_population`, '[^0-9.]', '');
UPDATE world_data_2023
SET `Urban_population` = NULLIF(`Urban_population`, '');
ALTER TABLE world_data_2023
MODIFY COLUMN `Urban_population` INT;

# Review
SELECT * FROM world_data_2023;
DESCRIBE world_data_2023;


### E. Creating Joining Table
SELECT ROW_NUMBER() OVER() row_num,
w.country, w.abbreviation
FROM world_data_2023 w
LEFT JOIN quality_of_life q
USING(country);

SELECT ROW_NUMBER() OVER() row_num,
q.country, w.abbreviation
FROM world_data_2023 w
RIGHT JOIN quality_of_life q
USING(country)
ORDER BY q.country;

CREATE TABLE countries (
id INT PRIMARY KEY AUTO_INCREMENT,
country VARCHAR(50) NOT NULL,
abbreviation VARCHAR(3) NOT NULL
);

SELECT * FROM countries;
DESCRIBE countries;

WITH cte_countries (country, abbreviation) AS (
SELECT q.country, w.abbreviation
FROM world_data_2023 w
RIGHT JOIN quality_of_life q
USING(country)
ORDER BY q.country) 
INSERT INTO countries (country, abbreviation)
SELECT country, abbreviation FROM cte_countries
;
-- INSERT does not work after a CTE in this version of MySQL. Will use a subquery instead.

ALTER TABLE countries
MODIFY COLUMN abbreviation VARCHAR(2);
-- Could not insert NULLs into `abbreviation`, will change back after repopulating.

INSERT INTO countries (country, abbreviation)
SELECT country, abbreviation 
FROM (
	SELECT q.country, w.abbreviation
	FROM world_data_2023 w
	RIGHT JOIN quality_of_life q
	USING(country)
	ORDER BY q.country
) sub_countries;

SELECT * FROM countries;
SELECT * FROM countries
WHERE abbreviation IS NULL;

# Populate missing Abbreviations.
CREATE TEMPORARY TABLE temp_abbreviations (
	country VARCHAR(50),
    abbreviation VARCHAR(3)
);

INSERT INTO temp_abbreviations VALUES
('Aland Islands', 'AX'),
('Alderney', 'GG'),
('American Samoa', 'AS'),
('Anguilla', 'AI'),
('Aruba', 'AW'),
('Bahamas', 'BS'),
('Bahrain', 'BH'),
('Bangladesh', 'BD'),
('Bermuda', 'BM'),
('Bonaire', 'BQ'),
('British Virgin Islands', 'VG'),
('Cayman Islands', 'KY'),
('Cook Islands', 'CK'),
('Curaçao', 'CW'),
('Eswatini', 'SZ'),
('Falkland Islands', 'FK'),
('Faroe Islands', 'FO'),
('French Guiana', 'GF'),
('French Polynesia', 'PF'),
('French Southern Territories', 'TF'),
('Gambia', 'GM'),
('Gibraltar', 'GI'),
('Greenland', 'GL'),
('Guadeloupe', 'GP'),
('Guam', 'GU'),
('Guernsey', 'GG'),
('Hong Kong (China)', 'HK'),
('Ireland', 'IE'),
('Isle of Man', 'IM'),
('Jersey', 'JE'),
('Kosovo (Disputed Territory)', 'XK'),
('Liechtenstein', 'LI'),
('Macao (China)', 'MO'),
('Maldives', 'MV'),
('Malta', 'MT'),
('Martinique', 'MQ'),
('Micronesia', 'FM'),
('Monaco', 'MC'),
('Montserrat', 'MS'),
('Nauru', 'NR'),
('New Caledonia', 'NC'),
('Niue', 'NU'),
('North Macedonia', 'MK'),
('Northern Mariana Islands', 'MP'),
('Palestine', 'PS'),
('Puerto Rico', 'PR'),
('Reunion', 'RE'),
('Saint Helena', 'SH'),
('Saint-Pierre and Miquelon', 'PM'),
('Sao Tome and Principe', 'ST'),
('Singapore', 'SG'),
('Sint Maarten', 'SX'),
('South Sudan', 'SS'),
('Taiwan', 'TW'),
('Timor-Leste', 'TL'),
('Turks and Caicos Islands', 'TC'),
('Tuvalu', 'TV'),
('US Virgin Islands', 'VI'),
('Vatican City', 'VA'),
('Wallis and Futuna', 'WF'),
('Western Sahara', 'EH');

SELECT COUNT(country) FROM countries
WHERE abbreviation IS NULL;
-- Same number of NULLs as records in the temp table.

# Insert new Abbreviations into Countries table.
UPDATE countries c
JOIN temp_abbreviations t
ON c.country = t.country
SET c.abbreviation = t.abbreviation;

SELECT * FROM countries;
SELECT * FROM countries
WHERE abbreviation IS NULL;

# Reset Abbreviations "NOT NULL"
ALTER TABLE countries
MODIFY COLUMN abbreviation VARCHAR(2) NOT NULL;

DESCRIBE countries;

### F. Creating ID columns
SELECT c.id, c.country, q.country, w.country
FROM countries c
LEFT JOIN quality_of_life q
USING(country)
LEFT JOIN world_data_2023 w
USING(country);

## Creating ID & Foreign Key Columns
# quality_of_life
ALTER TABLE quality_of_life
ADD country_id INT,
ADD id INT PRIMARY KEY AUTO_INCREMENT FIRST;
-- ADD CONSTRAINT FK_countries_quality FOREIGN KEY (country_id) REFERENCES countries(id);
-- Did not run properly. Will populate column then add FOREIGN KEY.

UPDATE quality_of_life q
JOIN countries c
USING(country)
SET q.country_id = c.id;

ALTER TABLE quality_of_life
MODIFY COLUMN country_id INT NOT NULL,
ADD CONSTRAINT FK_countries_quality FOREIGN KEY (country_id) REFERENCES countries(id);

SELECT id, country, country_id
FROM quality_of_life
ORDER by country;

SELECT * FROM quality_of_life;

# world_data_2023
ALTER TABLE world_data_2023
ADD country_id INT FIRST,
ADD id INT PRIMARY KEY AUTO_INCREMENT FIRST;

UPDATE world_data_2023 w
JOIN countries c
USING(country)
SET w.country_id = c.id;

ALTER TABLE world_data_2023
MODIFY COLUMN country_id INT NOT NULL,
ADD CONSTRAINT FK_countries_world FOREIGN KEY (country_id) REFERENCES countries(id);
-- Did not work as it seems certain countries are missing from the `Countries` table.

SELECT * FROM world_data_2023;
-- Several NULLs present.

SELECT DISTINCT w.country 
FROM world_data_2023 w
LEFT JOIN countries c ON w.country = c.country
WHERE c.id IS NULL
ORDER BY w.country;

SELECT * FROM countries
WHERE country IN (
	'East Timor',
	'Federated States of Micronesia',
	'Niger',
	'Republic of Ireland',
	'Solomon Islands',
	'The Bahamas',
	'The Gambia',
	'Uganda'
);

SELECT country
FROM countries
WHERE country LIKE '%Ireland%';
-- Some countries are already here under a different name.

# Find diverged country names
CREATE TEMPORARY TABLE temp_countries_check (
  country_check VARCHAR(50)
);

INSERT INTO temp_countries_check VALUES 
('%Timor%'),
('%Micronesia%'),
('%Niger%'),
('%Ireland%'),
('%Solomon%'),
('%Bahamas%'),
('%Gambia%'),
('%Uganda%');

SELECT c.country, t.country_check
FROM countries c
RIGHT JOIN temp_countries_check t 
ON (c.country LIKE t.country_check)
ORDER BY country;
-- Two countries were left out of the Countries Table. 
-- Did not verify if all 180 countries in world_data_2023 were present in the 233 countries in quality_of_life.

-- --------------------------------------------------------------------------------------------------------------

### X. Error Fixing
# While creating the Countries table, no AUTO_INCREMENT was set for ID.
# Cannot modify ID column as it is both a Primary Key and a Foreign Key. Must remove these first.
# Have since gone back and re-written SQL to reflect proper structuring for table creation.

ALTER TABLE countries
MODIFY id INT PRIMARY KEY AUTO_INCREMENT FIRST;
-- Must first remove Foreign Key constraint.

SELECT * FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE REFERENCED_TABLE_NAME = 'countries';

# Remake Primary Key with Auto Increment
ALTER TABLE quality_of_life
DROP FOREIGN KEY FK_countries_quality;

ALTER TABLE countries
DROP PRIMARY KEY,
MODIFY id INT PRIMARY KEY AUTO_INCREMENT FIRST;

SELECT * FROM countries;
DESCRIBE countries;

# Recreate Foreign Key
ALTER TABLE quality_of_life
ADD CONSTRAINT FK_countries_quality FOREIGN KEY (country_id) REFERENCES countries(id);

SELECT country, country_id
FROM quality_of_life;
DESCRIBE quality_of_life;
-- Looks good!

-- --------------------------------------------------------------------------------------------------------------

### F. (Creating ID columns - Continued)
# Populate Missing Countries
INSERT INTO countries (country, abbreviation) VALUES 
('Solomon Islands', 'SB'),
('Uganda', 'UG');

SELECT * FROM countries
WHERE country IN ('Solomon Islands', 'Uganda');

SELECT c.country, w.country
FROM countries c
RIGHT JOIN world_data_2023 w 
USING(country)
WHERE w.country NOT IN (SELECT country from countries)
ORDER BY c.country;
-- These two are fixed.

# Rename Countries in world_data_2023 to match countries table
SELECT DISTINCT w.country 
FROM world_data_2023 w
LEFT JOIN countries c ON w.country = c.country
WHERE c.id IS NULL
ORDER BY w.country;

SELECT c.country, t.country_check
FROM countries c
RIGHT JOIN temp_countries_check t 
ON (c.country LIKE t.country_check)
ORDER BY country;

UPDATE world_data_2023
SET country = (CASE
	WHEN country = 'Federated States of Micronesia' THEN 'Micronesia'
    WHEN country = 'The Bahamas' THEN 'Bahamas'
	WHEN country = 'East Timor' THEN 'Timor-Leste'
	WHEN country = 'The Gambia' THEN 'Gambia'
	WHEN country = 'Republic of Ireland' THEN 'Ireland'
	WHEN country = 'Niger' THEN 'Nigeria'
    ELSE country
END);

# Finish world_data_2023 id columns
UPDATE world_data_2023 w
JOIN countries c
USING(country)
SET w.country_id = c.id;

ALTER TABLE world_data_2023
MODIFY COLUMN country_id INT NOT NULL,
ADD CONSTRAINT FK_countries_world FOREIGN KEY (country_id) REFERENCES countries(id);

DESCRIBE world_data_2023;

SELECT id, country, country_id
FROM world_data_2023
ORDER by country;
-- Looks great!

### G. Removing Redundant Data
# Make backup of quality_of_life_changed and world_data_2023_changed now that there will be no shared column between our eploration and staging tables.

CREATE TABLE quality_of_life_cleaned
SELECT * FROM quality_of_life;
SELECT * FROM quality_of_life_cleaned;

CREATE TABLE world_data_2023_cleaned
SELECT * FROM world_data_2023;
SELECT * FROM world_data_2023_cleaned;

ALTER TABLE quality_of_life
DROP COLUMN country;
ALTER TABLE world_data_2023
DROP country,
DROP abbreviation;

DESCRIBE quality_of_life;
DESCRIBE world_data_2023;
-- Perfect! Cleaning & Table prep complete.

-- --------------------------------------------------------------------------------------------------------------

##### 2.5. Combining Datasets
# Took a little bit of time away from this project, and decided upon coming back to merge the data into one table.

DESCRIBE countries;
DESCRIBE quality_of_life;
DESCRIBE world_data_2023;

SELECT `Density
(P/Km2)` FROM world_data_2023 LIMIT 5;

### A. Cleanup
# Upon loading these tables into Jupyter Notebooks to test them with Pandas, it became clear that some Column Names were problematic in the CSV files.
ALTER TABLE world_data_2023
RENAME COLUMN `Density
(P/Km2)` to `density_p_km2`,
RENAME COLUMN `Agricultural Land(%)` to `agricultural_land_percent`,
RENAME COLUMN `Land Area(Km2)` to `land_area_km2`,
RENAME COLUMN `Armed Forces size` to `armed_forces_size`,
RENAME COLUMN `Birth Rate` to `birth_rate`,
RENAME COLUMN `Calling Code` to `calling_code`,
RENAME COLUMN `Capital/Major City` to `capital_major_city`,
RENAME COLUMN `Co2-Emissions` to `co2_emissions`,
RENAME COLUMN `CPI` to `cpi`,
RENAME COLUMN `CPI Change (%)` to `cpi_change_percent`,
RENAME COLUMN `Currency-Code` to `currency_code`,
RENAME COLUMN `Fertility Rate` to `fertility_rate`,
RENAME COLUMN `Forested Area (%)` to `forested_area_percent`,
RENAME COLUMN `Gasoline Price` to `gasoline_price`,
RENAME COLUMN `GDP` to `gdp`,
RENAME COLUMN `Gross primary education enrollment (%)` to `gross_primary_education_enrollment_percent`,
RENAME COLUMN `Gross tertiary education enrollment (%)` to `gross_tertiary_education_enrollment_percent`,
RENAME COLUMN `Infant mortality` to `infant_mortality`,
RENAME COLUMN `Largest city` to `largest_city`,
RENAME COLUMN `Life expectancy` to `life_expectancy`,
RENAME COLUMN `Maternal mortality ratio` to `maternal_mortality_ratio`,
RENAME COLUMN `Minimum wage` to `minimum_wage`,
RENAME COLUMN `Official language` to `official_language`,
RENAME COLUMN `Out of pocket health expenditure (%)` to `out_of_pocket_health_expenditure_percent`,
RENAME COLUMN `Physicians per thousand` to `physicians_per_thousand`,
RENAME COLUMN `Population` to `population`,
RENAME COLUMN `Population: Labor force participation (%)` to `labor_force_participation_percent`,
RENAME COLUMN `Tax revenue (%)` to `tax_revenue_percent`,
RENAME COLUMN `Total tax rate (%)` to `total_tax_rate_percent`,
RENAME COLUMN `Unemployment rate (%)` to `unemployment_rate_percent`,
RENAME COLUMN `Urban_population` to `urban_population`,
RENAME COLUMN `Latitude` to `latitude`,
RENAME COLUMN `Longitude` to `longitude`;

### B. Prioritization
# Removing less necessary data for simplified analysis.

DESCRIBE countries;
DESCRIBE quality_of_life;
DESCRIBE world_data_2023;

SELECT *
FROM countries c
LEFT JOIN quality_of_life q
ON c.id = q.country_id
LEFT JOIN world_data_2023 w
ON c.id = w.country_id;

# Creating new master table.
CREATE TABLE country_analysis AS
SELECT
	c.*,
    q.`Purchasing Power Value`,
	q.`Purchasing Power Category`,
	q.`Safety Value`,
	q.`Safety Category`,
	q.`Health Care Value`,
	q.`Health Care Category`,
	q.`Climate Value`,
	q.`Climate Category`,
	q.`Cost of Living Value`,
	q.`Cost of Living Category`,
	q.`Property Price to Income Value`,
	q.`Property Price to Income Category`,
	q.`Traffic Commute Time Value`,
	q.`Traffic Commute Time Category`,
	q.`Pollution Value`,
	q.`Pollution Category`,
	q.`Quality of Life Value`,
	q.`Quality of Life Category`,
	w.`density_p_km2`,
	w.`agricultural_land_percent`,
	w.`land_area_km2`,
	w.`armed_forces_size`,
	w.`birth_rate`,
	w.`calling_code`,
	w.`capital_major_city`,
	w.`co2_emissions`,
	w.`cpi`,
	w.`cpi_change_percent`,
	w.`currency_code`,
	w.`fertility_rate`,
	w.`forested_area_percent`,
	w.`gasoline_price`,
	w.`gdp`,
	w.`gross_primary_education_enrollment_percent`,
	w.`gross_tertiary_education_enrollment_percent`,
	w.`infant_mortality`,
	w.`largest_city`,
	w.`life_expectancy`,
	w.`maternal_mortality_ratio`,
	w.`minimum_wage`,
	w.`official_language`,
	w.`out_of_pocket_health_expenditure_percent`,
	w.`physicians_per_thousand`,
	w.`population`,
	w.`labor_force_participation_percent`,
	w.`tax_revenue_percent`,
	w.`total_tax_rate_percent`,
	w.`unemployment_rate_percent`,
	w.`urban_population`,
	w.`latitude`,
	w.`longitude`
FROM countries c
LEFT JOIN quality_of_life q
ON c.id = q.country_id
LEFT JOIN world_data_2023 w
ON c.id = w.country_id;

DESCRIBE country_analysis;
SELECT * FROM country_analysis;

# Check for discrepancies and inconsistencies.
SELECT ca.country, ca.`safety value`, q.`safety value`
FROM country_analysis ca
JOIN quality_of_life q
ON ca.id = q.country_id
WHERE ca.`safety value` != q.`safety value`;

SELECT ca.country, ca.`currency_code`, w.`currency_code`
FROM country_analysis ca
JOIN world_data_2023 w
ON ca.id = w.country_id
WHERE ca.`currency_code` != w.`currency_code`;
-- Stumbled upon two entries for Nigeria.

SELECT country
FROM country_analysis
GROUP BY country
HAVING count(*) > 1;

SELECT *
FROM country_analysis
WHERE country = 'Nigeria';
-- Same ID. WIll check for more duplicates.
-- Data discrepancies within world_data_2023 columns. Will check for original data.

SELECT id
FROM country_analysis
GROUP BY id
HAVING count(*) > 1;
-- No more duplicates.

SELECT country_id, land_area_km2
FROM world_data_2023
WHERE land_area_km2 = 923768;

SELECT country_id, land_area_km2
FROM world_data_2023
WHERE land_area_km2 = 1267000;
-- Issue likely stems from original data set or a previous transformation.

DESCRIBE world_data_2023_staging;

SELECT *
FROM world_data_2023_staging
WHERE `currency-code` IN ('NGN', 'XOF');
-- Looks like Niger and Nigeria both got renamed to Nigeria during transformations. Will update country name and ID.

SELECT *
FROM quality_of_life_staging
WHERE country IN ('Nigeria', 'Niger');
-- No entry for Niger. Will set columns to NULLs.

SELECT *
FROM country_analysis
WHERE country = 'Nigeria';

UPDATE country_analysis
SET id = 236, country = 'Niger', abbreviation = 'NE'
WHERE country = 'Nigeria' AND currency_code = 'XOF';

UPDATE country_analysis
SET `Purchasing Power Value` = NULL, 
	`Purchasing Power Category` = NULL,
	`Safety Value` = NULL,
	`Safety Category` = NULL,
	`Health Care Value` = NULL,
	`Health Care Category` = NULL,
	`Climate Value` = NULL,
	`Climate Category` = NULL,
	`Cost of Living Value` = NULL,
	`Cost of Living Category` = NULL,
	`Property Price to Income Value` = NULL,
	`Property Price to Income Category` = NULL,
	`Traffic Commute Time Value` = NULL,
	`Traffic Commute Time Category` = NULL,
	`Pollution Value` = NULL,
	`Pollution Category` = NULL,
	`Quality of Life Value` = NULL,
	`Quality of Life Category` = NULL
WHERE country = 'Niger';

SELECT *
FROM country_analysis
WHERE country = 'Niger';

DESCRIBE country_analysis;
SELECT * FROM country_analysis;
-- The table is complete

### C. Export to CSV
SELECT * 
FROM country_analysis
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Country_Analysis_Mastertable.csv'
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n';

SHOW VARIABLES LIKE 'secure_file_priv';

-- --------------------------------------------------------------------------------------------------------------

##### 3. Exploratory Analysis


































-- --------------------------------------------------------------------------------------------------------------

SELECT Country, `Co2-Emissions`, (SELECT ROUND(AVG(`Co2-Emissions`), 2) FROM world_data_2023) Average_Co2_Emissions
FROM world_data_2023
ORDER BY `Co2-Emissions`;

SELECT c.country, 
`Armed Forces size`,
(SELECT ROUND(AVG(`Armed Forces size`), -2) FROM world_data_2023) 'AVG Armed Forces Size',
CASE
	WHEN `Armed Forces size` >= (SELECT ROUND(AVG(`Armed Forces size`), -2) FROM world_data_2023) THEN 'Above Average'
    ELSE 'Below Average'
END Category,
(SELECT MAX(`Armed Forces size`) FROM world_data_2023) 'Max Armed Forces Size',
(SELECT MIN(`Armed Forces size`) FROM world_data_2023) 'Min Armed Forces Size'
FROM world_data_2023 w
JOIN countries c
	ON c.id = w.country_id
ORDER BY `Armed Forces size` DESC;


SELECT MAX(`Armed Forces size`), MIN(`Armed Forces size`), AVG(`Armed Forces size`)
FROM world_data_2023;
SELECT * FROM world_data_2023;



UPDATE world_data_2023 w
JOIN world_data_2023_staging ws
USING(abbreviation)
SET w.country = ws.country;

SELECT * FROM world_data_2023
WHERE country IS NULL;

UPDATE world_data_2023
SET country = 
CASE 
	WHEN Abbreviation = 'CG' THEN 'Republic of the Congo'
    WHEN Abbreviation = 'IE' THEN 'Republic of Ireland'
    WHEN Abbreviation = 'NA' THEN 'Namibia'
    ELSE country
END;


DESCRIBE quality_of_life;
DESCRIBE world_data_2023;

SELECT AVG(`Total tax rate (%)`) Mean,
MEDIAN(`Total tax rate (%)`) Median, 
STDDEV(`Total tax rate (%)`) 'Standard Deviation',
MIN(`Total tax rate (%)`) 'Min', 
MAX(`Total tax rate (%)`) 'Max'
FROM world_data_2023
GROUP BY country_id;
