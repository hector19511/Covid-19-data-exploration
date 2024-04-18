--Covid 19 data analisis
--Hector de Leon
--2024

SELECT *
FROM PortfolioProject..CovidDeaths
where Continent is not null
ORDER BY 3,4
;


--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4
--;

-- Data I will use

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
where Continent is not null
ORDER BY 1,2;


-- Looking at Total cases vs Total Deths
-- The next query shows the likelyhood of diyng from
-- covid in Guatemala depending on the date, from feb/2020 to apr/2021
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%Guatemala%'
and Continent is not null
ORDER BY 1,2;

--Total Cases vs Population
-- Shows what percentage of the population got Covid
SELECT Location, date, population , total_cases, (total_deaths/population)*100 as InfectedPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%Guatemala%'
and Continent is not null
ORDER BY 1,2;


--Countries with highest infection rates compared to the population

SELECT Location, population , MAX(total_cases) as highestInfectionCount, MAX((total_cases/population)*100) as PercentagePopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%Guatemala%'
group by Location, Population
ORDER BY PercentagePopulationInfected desc;


--Countries with the highest death count per population

SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%Guatemala%'
where Continent is not null
group by Location
ORDER BY TotalDeathCount desc;


-- Showing continents with hihest death count

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%Guatemala%'
where continent is not null
group by continent
ORDER BY TotalDeathCount desc;

-- Global numbers

--by date
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/
SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%Guatemala%'
where continent is not null
group by date
ORDER BY 1,2;

--total
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/
SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%Guatemala%'
where continent is not null
--group by date
ORDER BY 1,2;




--Looking at total population vs vaccinations


-- Common Table Expression(CTE)

with PopvsVac (Continent, location, date, population, New_Vaccinations,TotalVaxPeople )
as
(
Select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int)) OVER (Partition by deaths.location Order by deaths.location,
deaths.date) as TotalVaxPeople
from PortfolioProject..CovidDeaths deaths
join PortfolioProject..CovidVaccinations vac
	on deaths.location = vac.location
	and deaths.date = vac.date
where deaths.continent is not null
--order by 2,3
)
Select *, (TotalVaxPeople/population)*100
From PopvsVac

--Creating a vew to store data for later visualizations
Create view PercentPopulationVaccinated as
Select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int)) OVER (Partition by deaths.location Order by deaths.location,
deaths.date) as TotalVaxPeople
from PortfolioProject..CovidDeaths deaths
join PortfolioProject..CovidVaccinations vac
	on deaths.location = vac.location
	and deaths.date = vac.date
where deaths.continent is not null
--order by 2,3

Select * 
From PercentPopulationVaccinated

