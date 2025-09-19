/* =======================================================================
   Project: Bharat Herald Analytics – Production Database
   Purpose:
   --------
   This script creates the **production schema** for Bharat Herald analytics.
   It includes:
     - Dimension tables (ad category, city, brand mapping)
     - Fact tables (ad revenue, city readiness, digital pilot, print sales)

   Why this matters:
   -----------------
   - This is the **main production data model** used for analytics & reporting.
   - Supports dashboards, ad revenue analysis, readiness index scoring, 
     and print vs digital strategy decision-making.
   - Ensures referential integrity with foreign keys for trusted data joins.

   Notes:
   ------
   - Staging schema should be loaded first, then ETL scripts populate this 
     production schema.
   - Data here is clean, deduplicated, and ready for analytics.
   ======================================================================= */

-- ===============================================================
-- Create Database (if not exists) & Switch Context
-- ===============================================================
CREATE DATABASE IF NOT EXISTS BharatHerald;
USE BharatHerald;

-- ===============================================================
-- Dimension Tables
-- ===============================================================

-- =======================
-- 1. Ad Category Dimension
-- Stores master list of ad categories and their groupings
-- =======================
CREATE TABLE IF NOT EXISTS dim_ad_category (
    ad_category_id VARCHAR(10) PRIMARY KEY,         -- Unique identifier
    standard_ad_category VARCHAR(50) NOT NULL,      -- Cleaned category name
    category_group VARCHAR(50) NOT NULL             -- Grouping for analytics
);

-- ===============================
-- 2. Ad Name to Category Mapping
-- Maps brands to their corresponding ad categories
-- ===============================
CREATE TABLE IF NOT EXISTS dim_ad_name_category (
    id INT PRIMARY KEY,                             -- Unique row identifier
    ad_category_id VARCHAR(10),                     -- FK to dim_ad_category
    brand VARCHAR(50) NOT NULL,                     -- Brand name
    FOREIGN KEY (ad_category_id) REFERENCES dim_ad_category(ad_category_id)
);

-- =======================
-- 3. City Dimension Table
-- Stores city-level master data with edition and tier classification
-- =======================
CREATE TABLE IF NOT EXISTS dim_city (
    city_id VARCHAR(10) PRIMARY KEY,                -- Unique city identifier
    edition_id VARCHAR(15),                         -- Edition reference (if any)
    city VARCHAR(50) NOT NULL,                      -- City name
    state VARCHAR(50) NOT NULL,                     -- State name
    tier VARCHAR(7) NOT NULL                        -- Tier (e.g., Tier-1, Tier-2)
);

-- ===============================================================
-- Fact Tables
-- ===============================================================

-- =======================
-- 1. Ad Revenue Fact Table
-- Stores quarterly ad revenue per city and category
-- =======================
CREATE TABLE IF NOT EXISTS fact_ad_revenue (
    city_id VARCHAR(10),                            -- FK to dim_city
    ad_category_id VARCHAR(10),                     -- FK to dim_ad_category
    quarter VARCHAR(9),                             -- Quarter (YYYY-QX)
    ad_revenue_inINR DECIMAL(15,6),                 -- Revenue in INR (precise)
    FOREIGN KEY (city_id) REFERENCES dim_city(city_id),
    FOREIGN KEY (ad_category_id) REFERENCES dim_ad_category(ad_category_id)
);

-- =========================
-- 2. City Readiness Fact
-- Tracks literacy, smartphone & internet penetration per quarter
-- =========================
CREATE TABLE IF NOT EXISTS fact_city_readiness (
    city_id VARCHAR(10),                            -- FK to dim_city
    quarter VARCHAR(9),                             -- Quarter (YYYY-QX)
    literacy_rate DECIMAL(6,3),                     -- Literacy rate (%)
    smartphone_penetration DECIMAL(15,3),           -- Smartphone penetration (%)
    internet_penetration DECIMAL(15,3),             -- Internet penetration (%)
    FOREIGN KEY (city_id) REFERENCES dim_city(city_id)
);

-- =======================
-- 3. Digital Pilot Fact
-- Stores experimental digital campaign data and engagement metrics
-- =======================
CREATE TABLE IF NOT EXISTS fact_digital_pilot (
    ad_category_id VARCHAR(10),                     -- FK to dim_ad_category
    city_id VARCHAR(10),                            -- FK to dim_city
    platform VARCHAR(150) NOT NULL,                 -- Platform name
    launch_month VARCHAR(9) NOT NULL,               -- Launch month (YYYY-MM)
    dev_cost DECIMAL(15,2),                         -- Development cost
    market_cost DECIMAL(15,2),                      -- Marketing cost
    users_reached INT,                              -- Users reached
    downloads_or_accesses INT,                      -- Downloads / accesses
    avg_bounce_rate FLOAT,                          -- Bounce rate (lower = better)
    FOREIGN KEY (city_id) REFERENCES dim_city(city_id),
    FOREIGN KEY (ad_category_id) REFERENCES dim_ad_category(ad_category_id)
);

-- ======================
-- 4. Print Sales Fact
-- Tracks monthly print circulation, sales, and returns
-- ======================
CREATE TABLE IF NOT EXISTS fact_print_sales (
    city_id VARCHAR(10),                            -- FK to dim_city
    language VARCHAR(20),                           -- Language of edition
    state VARCHAR(50),                              -- State (for reporting)
    month DATE,                                     -- Reporting month
    copies_sold INT,                                -- Copies sold
    net_circulation INT,                            -- Net circulation
    copies_returned INT,                            -- Returned copies
    FOREIGN KEY (city_id) REFERENCES dim_city(city_id)
);
