-- Hector de Leon
-- Data Cleaning project
-- 2024


select *
from layoffs;

/*
Steps:
1.Remove Duplicates
2.Standardize the data
3. Null values or blank values
4. Remove any columns
*/

-- creating a staging table, which is a copy of the raw table, to avoid editing the raw in a way that might create problems 
create table layoffs_staging
like layoffs;

select *
from layoffs_staging; -- All columns ready, now its time to import data

insert layoffs_staging
select * 
from layoffs;-- done

select *
from layoffs_staging;

-- 1.Remove Duplicates
-- the table doesnt have id, so lets make a column to give them IDs
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
/*
the partition realizes the row_number the table regarding every key. that way it will asign a number 2 or more to all repeated data
*/
from layoffs_staging;

-- lets make it a cte
with duplicate_cte as
(
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging
)
select*
from duplicate_cte
where row_num > 1; -- this cte returns all the duplicated data( all the data with a row_num > 1), we need to get rid of that

/*
companies with repeated rows according to the cte:
casper
cazoo
hibob
wildlife studios
yahoo
*/

-- lets check if the cte did its job well
select* 
from layoffs_staging
where company = 'casper';

-- casper has a duplicate, we need to delete just the duplicate
-- but lets use the cte to delete all companies duplicates
/*
with duplicate_cte as
(
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging
)
delete
from duplicate_cte
where row_num > 1; 
--didnt work
*/ 

-- create statement copied from layoffs_staging table right clicking on it and selecting copy to clipboard create statement:
USE `world_layoffs`;
DROP event IF EXISTS `layoffs_staging2`;
CREATE TABLE `layoffs_staging2` ( -- new name
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int -- new column
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select *
from layoffs_staging2; -- table created, now lets add the rows

insert into layoffs_staging2
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging;

select *
from layoffs_staging2
where row_num > 1; -- shows the duplicates, lets delete them

SET SQL_SAFE_UPDATES = 0; -- we need to disable safe updates temporarily
show variables like 'event%'; -- lets check

delete -- neede to uncheck the safe update in order to delete it
from layoffs_staging2
where row_num > 1;


SET SQL_SAFE_UPDATES = 1; -- lets enable safe updates again
show variables like 'event%';

select *
from layoffs_staging2
where row_num > 1; -- repeated values where deleated

select *
from layoffs_staging2; -- table without repeated values, now we dont need the row_number column

/*
this whole process would have been way easier if the table had an ID column in it
*/


-- 2.Standardize the data
-- finding issues in the data and fixing it

select distinct(trim(company)) -- get rid of the empty spaces
from layoffs_staging2;

-- that looks better, so lets update the table

SET SQL_SAFE_UPDATES = 0; 
show variables like 'event%'; 

update layoffs_staging2
set company = trim(company);

SET SQL_SAFE_UPDATES = 1; 
show variables like 'event%';

-- lets check
select distinct(company) -- success
from layoffs_staging2;

-- lets keep checking the columns
select distinct(industry) --
from layoffs_staging2
order by 1; 

/*
So ther are some industry names which are the same but written differently, the crypto currency indusry for example
lets update that
*/

select *
from layoffs_staging2
where industry like '%Crypto%';

SET SQL_SAFE_UPDATES = 0; 
show variables like 'event%'; 

update layoffs_staging2
set industry = 'Crypto'
where industry like '%Crypto%';

SET SQL_SAFE_UPDATES = 1; 
show variables like 'event%';

select *
from layoffs_staging2
where industry like '%Crypto%'; -- done

select distinct country
from layoffs_staging2
order by 1
;

-- Lets fix the country column
select distinct country, trim(trailing '.' from country)
from layoffs_staging2
order by 1;

SET SQL_SAFE_UPDATES = 0; 
show variables like 'event%'; 

update layoffs_staging2
set country = trim(trailing '.' from country)
where country like 'United States%';

SET SQL_SAFE_UPDATES = 1; 
show variables like 'event%';

select distinct country, trim(trailing '.' from country)
from layoffs_staging2
order by 1;

-- country column fixed

select *
from layoffs_staging2;

/*
lets fix the date format
*/

select `date`,
str_to_date(`date`, '%m/%d/%Y') -- formating the date
from layoffs_staging2;

SET SQL_SAFE_UPDATES = 0; 
show variables like 'event%'; -- lets just keep the safe update down for this project

update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');

select `date`
from layoffs_staging2;-- date updated

alter table layoffs_staging2 -- lets change the column type
modify column `date` date;

select *
from layoffs_staging2;


-- 3. Null values or blank values

select*
from layoffs_staging2
where total_laid_off is null -- it doesnt work with the = sign
and percentage_laid_off is null;

update layoffs_staging2
set industry = null
where industry = '';

select *
from layoffs_staging2
where industry is null
or industry = '';

select *
from layoffs_staging2
where company = 'Airbnb';

select t1.industry, t2.industry
from layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

update layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
set t1.industry = t2.industry
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;    

select *
from layoffs_staging2;



-- 4. Remove any columns we dont need

select*
from layoffs_staging2
where total_laid_off is null 
and percentage_laid_off is null; -- lets delete these columns

delete 
from layoffs_staging2
where total_laid_off is null 
and percentage_laid_off is null; 

select *
from layoffs_staging2;

-- lets delete the row_num column with a drop

alter table layoffs_staging2
drop column row_num;

-- end of project

SET SQL_SAFE_UPDATES = 1; 
show variables like 'event%'; -- lets return the safe update
