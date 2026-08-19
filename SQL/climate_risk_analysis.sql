CREATE DATABASE climate_risk_analysis;
USE climate_risk_analysis;

-------------------------------------------------
-- 1. Create dim_country table 
CREATE TABLE dim_country (
    country_id INT PRIMARY KEY AUTO_INCREMENT,
    country_name VARCHAR(100) NOT NULL,
    continent VARCHAR(50) NOT NULL,
    region VARCHAR(50),
    gdp_usd_trillion DECIMAL(10,2),
    population BIGINT
);

-- Insert into dim_country
INSERT INTO dim_country
(country_name, continent, region, gdp_usd_trillion, population)
VALUES
('India', 'Asia', 'South Asia', 3.94, 1430000000),
('United States', 'North America', 'North America', 29.18, 340000000),
('China', 'Asia', 'East Asia', 18.80, 1410000000),
('Germany', 'Europe', 'Western Europe', 4.70, 84000000),
('Brazil', 'South America', 'South America', 2.30, 216000000),
('Australia', 'Oceania', 'Australia', 1.80, 27000000),
('Japan', 'Asia', 'East Asia', 4.10, 124000000),
('Canada', 'North America', 'North America', 2.20, 41000000),
('United Kingdom', 'Europe', 'Northern Europe', 3.60, 69000000),
('South Africa', 'Africa', 'Southern Africa', 0.40, 63000000);

-------------------------------------------------------------

-- 2. Create disaster table
CREATE TABLE dim_disaster (
    disaster_id INT PRIMARY KEY AUTO_INCREMENT,
    disaster_name VARCHAR(100) NOT NULL UNIQUE
);
desc dim_disaster;
INSERT INTO dim_disaster (disaster_name)
VALUES
('Flood'),
('Wildfire'),
('Heatwave'),
('Drought'),
('Cyclone'),
('Landslide'),
('Extreme Rainfall'),
('Cold Wave');
-----------------------------------------------------

-- 3.create date table 
CREATE TABLE dim_date (
    date_id INT PRIMARY KEY AUTO_INCREMENT,
    full_date DATE NOT NULL,
    day INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter VARCHAR(5) NOT NULL,
    year INT NOT NULL
);
SET SESSION cte_max_recursion_depth = 3000;

INSERT INTO dim_date (full_date, day, month, month_name, quarter, year)
WITH RECURSIVE date_series AS (
    SELECT DATE('2020-01-01') AS dt

    UNION ALL

    SELECT DATE_ADD(dt, INTERVAL 1 DAY)
    FROM date_series
    WHERE dt < '2025-12-31'
)

SELECT
    dt,
    DAY(dt),
    MONTH(dt),
    MONTHNAME(dt),
    CONCAT('Q', QUARTER(dt)),
    YEAR(dt)
FROM date_series;


-------------------------------------------------------------
-- 4.Create industry table 
CREATE TABLE dim_industry (
    industry_id INT PRIMARY KEY AUTO_INCREMENT,
    industry_name VARCHAR(100) NOT NULL UNIQUE
);

INSERT INTO dim_industry (industry_name)
VALUES
('Agriculture'),
('Manufacturing'),
('Energy'),
('Transportation'),
('Healthcare'),
('Retail'),
('Tourism'),
('Technology');

--------------------------------------------------------------
-- 5. create weather table 
CREATE TABLE dim_weather (
    weather_id INT PRIMARY KEY AUTO_INCREMENT,
    weather_type VARCHAR(50) NOT NULL,
    temperature_category VARCHAR(30) NOT NULL,
    rainfall_category VARCHAR(30) NOT NULL
);
INSERT INTO dim_weather
(weather_type, temperature_category, rainfall_category)
VALUES
('Sunny', 'Hot', 'Low'),
('Cloudy', 'Moderate', 'Medium'),
('Rainy', 'Moderate', 'High'),
('Storm', 'Hot', 'Extreme'),
('Snow', 'Cold', 'Low'),
('Fog', 'Cold', 'Medium'),
('Thunderstorm', 'Hot', 'Extreme'),
('Windy', 'Moderate', 'Low');


--------------------------------------------------------------
-- 6. create risk_level table 
CREATE TABLE dim_risk_level (
    risk_id INT PRIMARY KEY AUTO_INCREMENT,
    risk_level VARCHAR(30) NOT NULL UNIQUE,
    risk_score INT NOT NULL
);
INSERT INTO dim_risk_level (risk_level, risk_score)
VALUES
('Low',1),
('Moderate',2),
('High',3),
('Extreme',4);

--------------------------------------------------------

-- 7.create company_sector  table 
CREATE TABLE dim_company_sector (
    sector_id INT PRIMARY KEY AUTO_INCREMENT,
    sector_name VARCHAR(100) NOT NULL UNIQUE
);
INSERT INTO dim_company_sector (sector_name)
VALUES
('Agriculture'),
('Banking'),
('Insurance'),
('Energy'),
('Healthcare'),
('Manufacturing'),
('Retail'),
('Technology');


------------------------------------------------------------------
CREATE TABLE fact_climate_events (

    event_id INT PRIMARY KEY AUTO_INCREMENT,

    country_id INT NOT NULL,
    disaster_id INT NOT NULL,
    date_id INT NOT NULL,
    industry_id INT NOT NULL,
    weather_id INT NOT NULL,
    risk_id INT NOT NULL,
    sector_id INT NOT NULL,

    affected_population INT,
    deaths INT,
    economic_loss_usd DECIMAL(15,2),
    insurance_loss_usd DECIMAL(15,2),
    carbon_emission_mt DECIMAL(10,2),
    avg_temperature DECIMAL(5,2),
    rainfall_mm DECIMAL(10,2),
    severity_score DECIMAL(3,1),

    CONSTRAINT fk_country
        FOREIGN KEY (country_id)
        REFERENCES dim_country(country_id),

    CONSTRAINT fk_disaster
        FOREIGN KEY (disaster_id)
        REFERENCES dim_disaster(disaster_id),

    CONSTRAINT fk_date
        FOREIGN KEY (date_id)
        REFERENCES dim_date(date_id),

    CONSTRAINT fk_industry
        FOREIGN KEY (industry_id)
        REFERENCES dim_industry(industry_id),

    CONSTRAINT fk_weather
        FOREIGN KEY (weather_id)
        REFERENCES dim_weather(weather_id),

    CONSTRAINT fk_risk
        FOREIGN KEY (risk_id)
        REFERENCES dim_risk_level(risk_id),

    CONSTRAINT fk_sector
        FOREIGN KEY (sector_id)
        REFERENCES dim_company_sector(sector_id)
);

----------------------------------------------------------
DROP TABLE IF EXISTS fact_climate_staging;

CREATE TABLE fact_climate_staging (
    country_id VARCHAR(20),
    disaster_id VARCHAR(20),
    date_id VARCHAR(20),
    industry_id VARCHAR(20),
    weather_id VARCHAR(20),
    risk_id VARCHAR(20),
    sector_id VARCHAR(20),
    affected_population VARCHAR(30),
    deaths VARCHAR(30),
    severity_score VARCHAR(30),
    economic_loss_usd VARCHAR(50),
    insurance_loss_usd VARCHAR(50),
    carbon_emission_mt VARCHAR(30),
    avg_temperature VARCHAR(30),
    rainfall_mm VARCHAR(30)
);

SELECT COUNT(*) AS staging_records
FROM fact_climate_staging;

INSERT INTO fact_climate_events (
    country_id,
    disaster_id,
    date_id,
    industry_id,
    weather_id,
    risk_id,
    sector_id,
    affected_population,
    deaths,
    economic_loss_usd,
    insurance_loss_usd,
    carbon_emission_mt,
    avg_temperature,
    rainfall_mm,
    severity_score
)
SELECT
    CAST(country_id AS UNSIGNED),
    CAST(disaster_id AS UNSIGNED),
    CAST(date_id AS UNSIGNED),
    CAST(industry_id AS UNSIGNED),
    CAST(weather_id AS UNSIGNED),
    CAST(risk_id AS UNSIGNED),
    CAST(sector_id AS UNSIGNED),
    CAST(affected_population AS UNSIGNED),
    CAST(deaths AS UNSIGNED),
    CAST(economic_loss_usd AS DECIMAL(15,2)),
    NULLIF(insurance_loss_usd, ''),
    CAST(carbon_emission_mt AS DECIMAL(10,2)),
    NULLIF(avg_temperature, ''),
    NULLIF(rainfall_mm, ''),
    CAST(severity_score AS DECIMAL(3,1))
FROM fact_climate_staging;

SELECT COUNT(*) AS total_records
FROM fact_climate_events;
--------------------------------------------------------
