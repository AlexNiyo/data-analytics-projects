--looking at data from the netire table of COVID deaths

SELECT *
FROM CovidDeaths
where continent is not null

--looking at data from th e entire table of COVID vaccinations

SELECT *
FROM CovidVaccinations

--selecct data we are going to play with
select location, date, total_cases, new_cases, population, icu_patients, total_tests
from CovidDeaths
order by 1,2

--looking at total cases vs population in Uganda

select location, date, total_cases, population
from CovidDeaths
where location like '%Uganda'
order by 1,2

--looking at total cases vs people hospitalized in icu

select location, date, total_cases, icu_patients
from CovidDeaths
order by 1,2

--looking at the percentage of icu patients vs total cases 

select location, date, total_cases, icu_patients, (cast(icu_patients as float)/ cast(total_cases as float))*100 as CriticalPercentage
from CovidDeaths
where icu_patients <> 0 and total_cases <> 0
order by 1,2

--looking at coutries with the highest percentage of icu patients compared to total cases

select location, total_cases, icu_patients, MAX(cast(icu_patients as float)/ cast(total_cases as float))*100 as MaxCriticalPercentage
from CovidDeaths
where icu_patients <> 0 and total_cases <> 0
group by location, total_cases, icu_patients
order by MaxCriticalPercentage

--looking at coutries with the highest infection rate compared to population
--shows what percentage of each country's population that got COVID in descending  order of highest infection percentage

select location, population, max(total_cases) as HighestInfectionCount, max((cast (total_cases as float)/population)*100) as PercentPopulationInfected
from CovidDeaths
--On exploring the data I discovered entire continents ae also losted in the column name of location. These corrupt the data where we need only countries
where location <> 'Europe' and location <> 'Africa' and location <> 'ASia'
group by location, population
order by PercentPopulationInfected DESC

--let's break this down by continent 

select continent, max(cast(total_cases as float)) as TotalCasesCount
from CovidDeaths
where continent is not null
group by continent
order by TotalCasesCount desc


-- the data returned by this query has some column rows looking corrupted since I imported a csv file and not worksheet format

select location, max(cast(total_cases as float)) as TotalCasesCount
from CovidDeaths
where location is not null
group by location
order by TotalCasesCount desc

--GLOBAL NUMBERS 
--Looking at accumulated deaths and cases by the day. The column for total deaths failed to be convereted to csv hence wasn't imported

select date, sum(cast (new_cases as bigint)) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, sum(cast(new_deaths as float))/sum(cast(new_cases as float))*100 as DeathPercentage
from CovidDeaths
where new_deaths <> 0 --since diving an integer by zero is incorrect algebra (not maths :-D)
group by date
order by 1,2

-- Considering table 2 of the vaccinations

select*
from CovidVaccinations

--Looking at total population vs vaccinations
--Joining the two tables based on rows with similar data
--using columnns of continent, location, date and population from the CovidDeaths table and new vaccination column from the CovidVaccinations table
--computing the cumulative sum of vaccinations and partitioning that by countries

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum (convert(float, vac.new_vaccinations)) 
	over (partition by dea.location order by dea.location, dea.date) as CumulativeVaccinations
from CovidDeaths as dea
join CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
order by 2,3

--using a CTE because we want to perform calculations on the newly generated column of CumulativeVaccinations;
--CumulativeVaccinations is a temporary column which will only be functional in this particular subquery 

with PopvsVac (continent, location, date, population, new_vaccinations, CumulativeVaccinations)
as
(

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum (convert(float, vac.new_vaccinations)) 
	over (partition by dea.location order by dea.location, dea.date) as CumulativeVaccinations
from CovidDeaths as dea
join CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
--order by 2,3
)
select*, (CumulativeVaccinations/population)*100
from PopvsVac

--TEMP TABLE

Drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations float,
CumulativeVaccinations numeric
)


Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum (convert(float, vac.new_vaccinations)) 
	over (partition by dea.location order by dea.location, dea.date) as CumulativeVaccinations
from CovidDeaths as dea
join CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
--order by 2,3

select*, (CumulativeVaccinations/population)*100
from #PercentPopulationVaccinated


--creating view to store data for later visualizations

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum (convert(float, vac.new_vaccinations)) 
	over (partition by dea.location order by dea.location, dea.date) as CumulativeVaccinations
from CovidDeaths as dea
join CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
--order by 2,3

select*
from PercentPopulationVaccinated