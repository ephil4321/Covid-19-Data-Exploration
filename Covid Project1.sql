/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
Dataset: Our World in Data COVID-19 dataset (https://ourworldindata.org/covid-deaths)
*/

--Sample of data

SELECT location, date, total_cases, new_cases, total_deaths, population
  FROM [CovidProject].[dbo].[CovidDeaths$]
 ORDER BY location, date;

--Total Cases vs Total Deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
  FROM [CovidProject].[dbo].[CovidDeaths$]
 WHERE location = 'United States'
 ORDER BY location, date;

--Total Cases vs Population

SELECT location, date, population, total_cases, (total_cases/population)*100 AS Cases_v_Population
  FROM [CovidProject].[dbo].[CovidDeaths$]
 WHERE location = 'United States'
 ORDER BY location, date;

--Countries with highest cases per population

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)*100) AS max_infection_v_pop
  FROM [CovidProject].[dbo].[CovidDeaths$]
 GROUP BY location, population
 ORDER BY max_infection_v_pop DESC;

--Countries with highest total deaths

SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
  FROM [CovidProject].[dbo].[CovidDeaths$]
 WHERE continent IS NOT NULL
 GROUP BY location
 ORDER BY total_death_count DESC;

-- Death totals by continent

 SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
  FROM [CovidProject].[dbo].[CovidDeaths$]
 WHERE location IN ('Europe', 'North America', 'South America', 'Africa', 'Oceania', 'Asia')
 GROUP BY location
 ORDER BY total_death_count DESC;

 -- Global Numbers 

  SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/NULLIF(SUM(new_cases)*100, 0)*100 AS DeathPercentage
    FROM [CovidProject].[dbo].[CovidDeaths$]
   WHERE location IN ('Europe', 'North America', 'South America', 'Africa', 'Oceania', 'Asia')
   GROUP BY date
   ORDER BY 1,2;

  SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/NULLIF(SUM(new_cases)*100, 0)*100 AS DeathPercentage
    FROM [CovidProject].[dbo].[CovidDeaths$]
   WHERE location IN ('Europe', 'North America', 'South America', 'Africa', 'Oceania', 'Asia')
   ORDER BY 1,2;

SELECT *
  FROM [CovidProject].[dbo].[CovidDeaths$] dea
  JOIN [CovidProject].[dbo].[CovidVaccinations$] vac
    ON dea.location = vac.location
   AND dea.date = vac.date;

--Total Population vs Vaccinations -- rolling vaccination count

SELECT dea.continent, dea.location, dea.date, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, 
	dea.date) AS rolling_vac_count
  FROM [CovidProject].[dbo].[CovidDeaths$] dea
  JOIN [CovidProject].[dbo].[CovidVaccinations$] vac
    ON dea.location = vac.location
 WHERE dea.continent IS NOT NULL
   AND dea.date = vac.date
 ORDER BY location, date;

 --CTE

 WITH pop_v_vac (continent, location, date, population, new_vaccinations, rolling_vac_count)
   AS
 (
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, 
	dea.date) AS rolling_vac_count
  FROM [CovidProject].[dbo].[CovidDeaths$] dea
  JOIN [CovidProject].[dbo].[CovidVaccinations$] vac
    ON dea.location = vac.location
 WHERE dea.continent IS NOT NULL
   AND dea.date = vac.date
 )
 SELECT *, (rolling_vac_count/population)*100
   FROM pop_v_vac;

-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated --allows modification of temp table, good to always include
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
rolling_vac_count numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, 
	dea.date) AS rolling_vac_count
  FROM [CovidProject].[dbo].[CovidDeaths$] dea
  JOIN [CovidProject].[dbo].[CovidVaccinations$] vac
    ON dea.location = vac.location
 WHERE dea.continent IS NOT NULL
   AND dea.date = vac.date

SELECT *, (rolling_vac_count/population)*100
  FROM #PercentPopulationVaccinated;

--Create view for later visualization 

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, 
	dea.date) AS rolling_vac_count
  FROM [CovidProject].[dbo].[CovidDeaths$] dea
  JOIN [CovidProject].[dbo].[CovidVaccinations$] vac
    ON dea.location = vac.location
 WHERE dea.continent IS NOT NULL
   AND dea.date = vac.date;

