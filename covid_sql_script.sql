SELECT * FROM covid_death;

ALTER TABLE covid_death
MODIFY COLUMN population BIGINT,
MODIFY COLUMN total_cases int,
MODIFY COLUMN new_cases int,
MODIFY COLUMN total_deaths int,
MODIFY COLUMN new_deaths int;

DESCRIBE covid_death;


UPDATE covid_death
SET	`date` = STR_TO_DATE(`date`, '%d-%m-%Y');

ALTER TABLE covid_death
MODIFY COLUMN `date` DATE;

#-------

SELECT * FROM covid_vac;

DESCRIBE covid_vac;


UPDATE covid_vac
SET	`date` = STR_TO_DATE(`date`, '%d-%m-%Y');

ALTER TABLE covid_vac
MODIFY COLUMN `date` DATE;

##---Select data that we are going to be using

SELECT			location, date, total_cases, new_cases, total_deaths, population
FROM			covid_death
ORDER BY		1,2;

# Looking at Total Cases vs Total Deaths
# Shows likelihood of dying if you contract covid in your country

SELECT			location, date, total_cases, total_deaths, population, (total_deaths/total_cases)*100 as death_percentage
FROM			covid_death
WHERE			location like '%india%'
ORDER BY		1,2;

# Looking at total cases vs population
# Shows what percentage of population got covid

SELECT			location, date, total_cases, total_deaths, population, (total_cases/population)*100 as infection_rate
FROM			covid_death
WHERE			location like '%india%'
ORDER BY		1,2;

# Looking at countries with highest infection rate compared to population

WITH ranked_data as (
	SELECT			ROW_NUMBER() OVER(PARTITION BY location ORDER BY total_cases/population*100 desc) as rankk, location, population, total_cases, total_cases/population*100 as `infection_rate(%)`
	FROM			covid_death
    WHERE			continent IS NOT NULL
)
SELECT			location, total_cases, population, `infection_rate(%)`
FROM			ranked_data
WHERE			rankk = 1
ORDER BY		4 desc;

# Countries with highest death count per population

WITH ranked_data as (
	SELECT			ROW_NUMBER() OVER(PARTITION BY location ORDER BY total_deaths/population*100 desc) as rankk, location, population, total_deaths, total_deaths/population*100 as `mortality_rate(%)`
	FROM			covid_death
    WHERE			continent IS NOT NULL
)
SELECT			location, total_deaths, population, `mortality_rate(%)`
FROM			ranked_data
WHERE			rankk = 1
ORDER BY		4 desc;

# Countries with absolute highest death counts

SELECT			location, MAX(total_deaths) as total_death_count
FROM			covid_death
WHERE			continent IS NOT NULL
GROUP BY		1
ORDER BY		2 desc;

# Continent wise death count

SELECT			location, MAX(total_deaths) as total_death_count
FROM			covid_death
WHERE			continent IS NULL
GROUP BY		1
ORDER BY		2 desc;

# or

SELECT			continent, SUM(new_deaths) as total_death_count
FROM			covid_death
WHERE			continent IS NOT NULL
GROUP BY		1
ORDER BY		2 desc;

# Day by day death rate(percentage) if you contact covid

SELECT			date, SUM(new_deaths) as deaths, SUM(new_cases) as no_of_cases, (SUM(new_deaths)/SUM(new_cases))*100 as `death_rate(%)`
FROM			covid_death
GROUP BY		1
ORDER BY		1;

# Joining Death and Vaccination tables

SELECT			*
FROM			covid_death d
JOIN			covid_vac v
ON				d.date = v.date and d.location = v.location;

# Total Population vs vaccination

With cuml_vaccination as
(
SELECT			d.continent, d.location, d.date, d.population, v.new_vaccinations,
				SUM(v.new_vaccinations) OVER(PARTITION BY location ORDER BY d.location, d.date) as cumulative_vaccinations_by_country                
FROM			covid_death d
JOIN			covid_vac v
ON				d.date = v.date and d.location = v.location
WHERE			d.continent IS NOT NULL
)
SELECT			*, (cumulative_vaccinations_by_country/population)*100 as `vaccination_rate(%)`
FROM			cuml_vaccination
#WHERE			location = 'United States'  # If we need to filter just in case
#HAVING			`vaccination_rate(%)` IS NOT NULL  # If we want to see from vaccination starting date
ORDER BY		1,2,3;

# Creating View to store data for visualizations
CREATE VIEW Vaccinated_pop_percent
as
(
With cuml_vaccination as
(
SELECT			d.continent, d.location, d.date, d.population, v.new_vaccinations,
				SUM(v.new_vaccinations) OVER(PARTITION BY location ORDER BY d.location, d.date) as cumulative_vaccinations_by_country                
FROM			covid_death d
JOIN			covid_vac v
ON				d.date = v.date and d.location = v.location
WHERE			d.continent IS NOT NULL
)
SELECT			*, (cumulative_vaccinations_by_country/population)*100 as `vaccination_rate(%)`
FROM			cuml_vaccination
#WHERE			location = 'United States'  # If we need to filter just in case
#HAVING			`vaccination_rate(%)` IS NOT NULL  # If we want to see from vaccination starting date
ORDER BY		1,2,3
);

SELECT * FROM Vaccinated_pop_percent







