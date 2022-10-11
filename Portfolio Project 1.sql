select * from CovidDeaths$
select * from [dbo].[_xlnm#_FilterDatabase]
/*Select data that we are going to use*/

select location,date,total_cases,new_cases,population,total_deaths
from CovidDeaths$
order by 1,2

/*Looking for total cases vs total deaths*/
/*Shows likelihhood of dying if you contract covid in your country*/
select location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 as Death_percentage
from CovidDeaths$
where location like '%states%'
order by 1,2
/*Looking at total cases vs Population*/
/*shows what percentage of population got covid*/
select location,date,total_cases,population, (total_cases/population)*100 as Infected_percentage
from CovidDeaths$
where location like '%India%'
order by 1,2
/*Looking at countries with highest infection rate compared to population*/
select location,Max(total_cases)as HighestInfectedcount,population, Max((total_cases/population))*100 as Infected_percentage
from CovidDeaths$
group by population,location
order by Infected_percentage desc
/*Showing countries with highest death count per population*/
select location,Max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is not null
group by location
order by TotalDeathCount desc
/*Lets break this by continent*/
select continent,Max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is not null
group by  continent
order by TotalDeathCount desc

select location,Max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is  null
group by location
order by TotalDeathCount desc

/*Global Numbers*/
select date, sum(new_cases) as total_cases,sum(cast(new_deaths as int)) as total_death,
(sum(cast(new_deaths as int))/sum(new_cases)*100) as Deathpercentage
from CovidDeaths$
where continent is not null
group by date
order by 1,2

select * 
from [dbo].[_xlnm#_FilterDatabase]
select *
from CovidDeaths$ d
join CovidVaccine v
on d.location=v.location
and d.date=v.date
/*Looking at total populations versus Vaccination*/

select d.continent,d.location,d.date,population,v.new_vaccinations
from CovidDeaths$ d
join CovidVaccine v
on d.location=v.location
and d.date=v.date
where d.continent is not null
order by v.new_vaccinations desc

select d.continent,d.location,d.date,population,v.new_vaccinations,
sum(convert(int, v.new_vaccinations)) over (partition by d.location order by d.location,d.date)
as RollingPeopleVaccinated
from CovidDeaths$ d
join CovidVaccine v
on d.location=v.location
and d.date=v.date
where d.continent is not null
order by v.new_vaccinations desc

--USE CTE

With PopvsVac (continent,location,date,population,new_vaccination,RollingPeopleVaccinated)
as
(
select d.continent,d.location,d.date,population,v.new_vaccinations,
sum(convert(int, v.new_vaccinations)) over (partition by d.location order by d.location,d.date)
as RollingPeopleVaccinated
from CovidDeaths$ d
join [dbo].[CovidVaccinations$] v
on d.location=v.location
and d.date=v.date
where d.continent is not null
)
select *, (RollingPeopleVaccinated/population)*100
from PopvsVac
--Temp Table
Drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
select d.continent,d.location,d.date,population,v.new_vaccinations,
sum(convert(int, v.new_vaccinations)) over (partition by d.location order by d.location,d.date)
as RollingPeopleVaccinated
from CovidDeaths$ d
join [dbo].[CovidVaccinations$] v
on d.location=v.location
and d.date=v.date
--where d.continent is not null
select *,(RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated
/*Creating view to store data for later visualization*/
Create View PercentPopulationVaccinated as 
select d.continent,d.location,d.date,population,v.new_vaccinations,
sum(convert(int, v.new_vaccinations)) over (partition by d.location order by d.location,d.date)
as RollingPeopleVaccinated
from CovidDeaths$ d
join [dbo].[CovidVaccinations$] v
on d.location=v.location
and d.date=v.date
where d.continent is not null

select * 
from PercentPopulationVaccinated