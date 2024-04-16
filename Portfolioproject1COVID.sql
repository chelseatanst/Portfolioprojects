-- Select Data to be used
SELECT *
FROM PortfolioProject..CovidDeaths$

select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths$
where continent is not null
order by 1,2

--Observing Total cases versus Total Deaths
-- This shows the likelihood of dying if you contract COVID in your country
select Location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 as PercentageofDeaths
from PortfolioProject..CovidDeaths$
where location = 'Singapore'
order by 1,2

-- Total cases versus Population
-- Shows the proportion of the Population who contracted COVID
select Location,date,total_cases,population, (total_cases/population)*100 as Proportionofcases
from PortfolioProject..CovidDeaths$
where location = 'Singapore'
order by 1,2

-- What countries have the highest infection rate (compared to Population)?
select Location,max(total_cases) as HighestInfectionCount,population, max((total_cases/population))*100 as Proportionofcases
from PortfolioProject..CovidDeaths$
where continent is not null
group by location,population
order by Proportionofcases DESC

-- What countries have the highest death count (per population)?
select Location, MAX(cast (total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null
group by location
order by TotalDeathCount desc

-- View by CONTINENT
select continent, MAX(cast (total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null
group by continent
order by TotalDeathCount desc

-- Showing continents with the highest death count per population
select continent, MAX(cast (total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null
group by continent
order by TotalDeathCount desc

-- Showing continents with the highest infection rate per population
select continent,max(total_cases) as HighestInfectionCount
from PortfolioProject..CovidDeaths$
where continent is not null
group by continent

-- GLOBAL NUMBERS 
SELECT date, SUM(new_cases) as Totalcases, SUM(CAST(new_deaths as int)) as Totaldeaths, SUM(CAST(new_deaths as int))/SUM(new_cases) *100 as DeathPercentage
from PortfolioProject..CovidDeaths$
where continent is not null
group by date
order by 1,2

--GLOBAL NUMBERS (overall without date)
SELECT SUM(new_cases) as Totalcases, SUM(CAST(new_deaths as int)) as Totaldeaths, SUM(CAST(new_deaths as int))/SUM(new_cases) *100 as DeathPercentage
from PortfolioProject..CovidDeaths$
where continent is not null
order by 1,2


-- Viewing COVID Deaths and Vaccination rate side by side (JOIN)
-- What's the total population versus vaccination like?
select dea.continent,dea.location,dea.date,dea.population,vax.new_vaccinations, 
SUM(cast (new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location,dea.date) as RollingpeopleVaccinated
from PortfolioProject..CovidDeaths$ dea JOIN PortfolioProject..CovidVaccinations$ vax
on dea.location = vax.location and dea.date = vax.date
where dea.continent is not null
order by 2,3

-- Because UNLIKE BIGQUERY, ssms doesnt allow you to use a column that you've just created
-- So we need to create a TEMPTABLE or CTE
-- CTE
-- If the number of columns in the CTE is not the same as the columns specified below, it'll give an error

With popsvsvax (continent,location,date,population,new_vaccinations,RollingpeopleVaccinated)
as
(
select dea.continent,dea.location,dea.date,dea.population,vax.new_vaccinations, 
SUM(cast (new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location,dea.date) as RollingpeopleVaccinated
from PortfolioProject..CovidDeaths$ dea JOIN PortfolioProject..CovidVaccinations$ vax
on dea.location = vax.location and dea.date = vax.date
where dea.continent is not null
)

select *, (RollingpeopleVaccinated/population)*100 as RollingPercentage
from popsvsvax

-- TEMP TABLE method
drop table if exists percentpopulationvaxxed
create table percentpopulationvaxxed
(
Continent varchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingpeopleVaccinated numeric
)

Insert into percentpopulationvaxxed
select dea.continent,dea.location,dea.date,dea.population,vax.new_vaccinations, 
SUM(cast (new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location,dea.date) as RollingpeopleVaccinated
from PortfolioProject..CovidDeaths$ dea JOIN PortfolioProject..CovidVaccinations$ vax
on dea.location = vax.location and dea.date = vax.date

select *, (RollingpeopleVaccinated/population)*100 as RollingPercentage
from percentpopulationvaxxed

--Create Views for later reference
create view Percentpopulationvaccinated as
select dea.continent,dea.location,dea.date,dea.population,vax.new_vaccinations, 
SUM(cast (new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location,dea.date) as RollingpeopleVaccinated
from PortfolioProject..CovidDeaths$ dea JOIN PortfolioProject..CovidVaccinations$ vax
on dea.location = vax.location and dea.date = vax.date
where dea.continent is not null

-- View for total case versus total deaths
create view SGdeathsvscases as
select Location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 as PercentageofDeaths
from PortfolioProject..CovidDeaths$
where location = 'Singapore'

-- View for total cases versus total population
create view SGpopvscases as
select Location,date,total_cases,population, (total_cases/population)*100 as Proportionofcases
from PortfolioProject..CovidDeaths$
where location = 'Singapore'