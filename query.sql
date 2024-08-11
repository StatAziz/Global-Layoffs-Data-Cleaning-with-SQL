-- SQL project:Worldwide-Layoffs Data cleaning

-- take a look at the dataset
SELECT *
FROM layoffs;
 
-- now when we are data cleaning we usually follow a few steps
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values or blank values 
-- 4. remove any columns and rows that are not necessary - few ways

-- steps: 
-- first thing we want to do is create a staging table. 
-- This is the one we will work in and clean the data. 
-- We want a table with the raw data intact in case something happens.


-- creating staging table
CREATE TABLE layoffs_staging
LIKE layoffs;

-- inserting values in the staging table
INSERT layoffs_staging
SELECT * 
FROM layoffs;

-- querying all row in staging table
SELECT *
FROM layoffs_staging;

-- total number of distinct companies
SELECT count(DISTINCT company)
FROM layoffs_staging_new;

-- check the values in the staging table
SELECT *
FROM layoffs_staging;

-- Remove duplicates
-- check for duplicates:
-- step-1: create row number over partitioned by all columns
-- step-2: query the rows where row number greater than 1

-- Finding duplicates
WITH duplicate_cte AS(
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte 
WHERE row_num>1;

SELECT *
FROM layoffs_staging
WHERE company = 'Hibob';

-- we cannot delete the duplicate using delete statement (like update) in mysql unlike sql server or postgres

-- with cte as(
-- select *, row_number() over ( partition by company, location, industry, total_laid_off, 
-- percentage_laid_off, `date`, stage, country, funds_raised_millions) row_num
-- from layoffs_staging)

-- delete
-- from cte 
-- where row_num>1

-- creating new working table layoffs_staging_new
CREATE TABLE `layoffs_staging_new` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
 
-- inserting value in the new table layoffs_staging_new
INSERT layoffs_staging_new
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) row_num
FROM layoffs_staging;

-- check the duplicates
SELECT *
FROM layoffs_staging_new
WHERE row_num>1;

-- now delete the duplicates
DELETE
FROM layoffs_staging_new
WHERE row_num>1;

-- check after deleting
SELECT *
FROM layoffs_staging_new
WHERE row_num>1;

-- standardizing the data
-- first check if there is any white space before and after the word
-- begin with column company
SELECT DISTINCT company
FROM layoffs_staging_new;

-- we notice there is a space before word
-- use trim and see the difference
SELECT company, trim(company)
FROM layoffs_staging_new;

-- update the table by replacing the column with trimmed column
UPDATE layoffs_staging_new
SET company = trim(company);

-- now see the column industry
SELECT DISTINCT industry
FROM layoffs_staging_new
ORDER BY 1;

-- crypto, crypto-currecny should be labelled same
-- lets examine more

-- compare the count of crypto vs crypto%
SELECT count(*)
FROM layoffs_staging_new
WHERE industry LIKE 'crypto%'
UNION ALL
SELECT count(*)
FROM layoffs_staging_new
WHERE industry = 'crypto';

-- update all crypto% replacing with crypto
UPDATE layoffs_staging_new
SET industry = 'Crypto'
WHERE industry LIKE 'crypto%';

-- now see after updating
SELECT DISTINCT industry
FROM layoffs_staging_new;

-- check column location
SELECT DISTINCT location
FROM layoffs_staging_new    
ORDER BY  1;

-- check column country
SELECT DISTINCT country
FROM layoffs_staging_new
ORDER BY 1;

-- findings : United States. vs United States 
-- . needs to be removed
SELECT *
FROM layoffs_staging2
WHERE country LIKE 'united%.'; 
-- there are fours like this

-- removing the period
SELECT DISTINCT country, trim(TRAILING '.' FROM country)
FROM layoffs_staging_new
ORDER BY 1;

-- update the table
UPDATE layoffs_staging_new
SET country = trim(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- see the updated table
SELECT DISTINCT country
FROM layoffs_staging_new
ORDER BY 1;

-- check the data type
-- date datatype is text which needs to be changed to date

-- check column date
SELECT `date`
FROM layoffs_staging_new;

-- change the date format m-d-y to standard format y-m-d 
SELECT `date`, str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging_new;

-- update date column
UPDATE layoffs_staging_new
SET `date` = str_to_date(`date`, '%m/%d/%Y');

-- fix the datatype of date from text to date
ALTER TABLE layoffs_staging_new
MODIFY COLUMN `date` DATE;

-- Now let's work with null and blank cells
-- checking null in one column -- total_laid_off

SELECT *
FROM layoffs_staging_new
WHERE total_laid_off IS NULL; 

-- null in multiple columns: total_laid_off and percentage_laid_off
SELECT *
FROM layoffs_staging_new
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL; 

-- check if there is any null or blank in industry column
SELECT *
FROM layoffs_staging_new
WHERE industry IS NULL 
OR industry = '';

SELECT *
FROM layoffs_staging_new
WHERE company ='Airbnb';

-- fill out / populate blanks for industries from other rows with same attributes for other columns
SELECT t1.industry, t2.industry
FROM layoffs_staging_new t1
JOIN layoffs_staging_new t2
ON t1.company = t2.company -- and t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry ='') AND (t2.industry IS NOT NULL OR t2.industry != '');

-- populate blanks for industries from other rows with same attributes for other columns
SELECT t1.industry, t2.industry
FROM layoffs_staging_new t1
JOIN layoffs_staging_new t2
ON t1.company = t2.company -- and t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry ='') AND (t2.industry != '');

-- update table with populting industry name in blanks
UPDATE layoffs_staging_new t1
JOIN layoffs_staging_new t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry ='') AND (t2.industry != '');

-- update layoffs_staging2
-- set industry = null
-- where industry = '';

-- check after updating table with populating industry
SELECT *
FROM layoffs_staging_new
WHERE industry IS NULL OR industry = '';

-- check how many bally's company
SELECT *
FROM layoffs_staging_new
WHERE company LIKE 'bally%';

-- dropping column or row unnecessary
-- deleting rows where both total_laid_off and percentage_laid_off null

SELECT *
FROM layoffs_staging_new
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging_new
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- dropping column row_num
ALTER TABLE layoffs_staging_new
DROP COLUMN row_num;

-- drop table layoffs_staging_new

select count(*)
from layoffs_staging_new
--where company = 'Included Health';

--- check the medians
 SELECT
        Company, Industry,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_laid_off) 
		OVER (PARTITION BY industry) AS median_total_laid_off,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY percentage_laid_off) 
		OVER (PARTITION BY industry) AS median_percentage_laid_off,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY funds_raised_millions) 
		OVER (PARTITION BY industry) AS median_funds_raised_millions
 FROM layoffs_staging_new;

-- update table by replacing nulls with medians
 WITH industry_medians AS (
    SELECT 
        industry,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_laid_off) 
		OVER (PARTITION BY industry) AS median_total_laid_off,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY percentage_laid_off) 
		OVER (PARTITION BY industry) AS median_percentage_laid_off,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY funds_raised_millions) 
		OVER (PARTITION BY industry) AS median_funds_raised_millions
    FROM layoffs_staging_new
)
UPDATE lsn
SET 
    lsn.total_laid_off = COALESCE(lsn.total_laid_off, im.median_total_laid_off),
    lsn.percentage_laid_off = COALESCE(lsn.percentage_laid_off, im.median_percentage_laid_off),
    lsn.funds_raised_millions = COALESCE(lsn.funds_raised_millions, im.median_funds_raised_millions)
FROM layoffs_staging_new lsn
JOIN industry_medians im
ON lsn.industry = im.industry;


-- check if there is null in the theree columns
SELECT company, industry, total_laid_off, percentage_laid_off, funds_raised_millions
FROM layoffs_staging_new
WHERE total_laid_off IS NULL OR percentage_laid_off IS NULL OR funds_raised_millions IS NULL;


-- see the final table
SELECT *
FROM layoffs_staging_new;

