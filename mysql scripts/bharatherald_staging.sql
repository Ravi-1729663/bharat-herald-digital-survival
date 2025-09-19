/* =======================================================================
   Project: Bharat Herald Analytics – Staging Database
   Purpose:
   --------
   This script creates the **staging schema** for the Bharat Herald analytics project.
   It includes:
     - Dimension tables (city, ad categories, brand mappings)
     - Fact tables (ad revenue, print sales, digital pilot, city readiness)
   
   Why this matters:
   -----------------
   - Acts as a clean, normalized data model for analytical queries.
   - Supports business use cases like:
       * Circulation analysis (YoY, MoM trends)
       * Ad revenue contribution by category
       * Digital readiness vs. engagement analysis
       * Print efficiency leaderboards
   - Ensures referential integrity with primary/foreign key relationships.
   ======================================================================= */

-- ===============================================================
-- Create Database (if not exists) & Switch Context
-- ===============================================================
CREATE DATABASE IF NOT EXISTS BharatHerald_staging;
USE BharatHerald_staging;

-- ===============================================================
-- Dimension Tables
-- ===============================================================

-- =======================
-- 1. Ad Category Dimension
-- Stores unique ad categories and their standardized names & groups
-- =======================
CREATE TABLE IF NOT EXISTS dim_ad_category (
    ad_category_id VARCHAR(10) PRIMARY KEY,         -- Unique identifier for ad category
    standard_ad_category VARCHAR(50) NOT NULL,      -- Standardized category name
    category_group VARCHAR(50) NOT NULL             -- Category grouping for reporting
);

-- ===============================
-- 2. Ad Name to Category Mapping
-- Maps brand names to their ad categories
-- ===============================
CREATE TABLE IF NOT EXISTS dim_ad_name_category (
    id INT PRIMARY KEY,                             -- Unique row ID
    ad_category_id VARCHAR(10),                     -- FK to dim_ad_category
    brand VARCHAR(50) NOT NULL,                     -- Brand name
    FOREIGN KEY (ad_category_id) REFERENCES dim_ad_category(ad_category_id)
);

-- =======================
-- 3. City Dimension Table
-- Master data for cities and editions
-- =======================
CREATE TABLE IF NOT EXISTS dim_city (
    city_id VARCHAR(10) PRIMARY KEY,                -- Unique identifier for city
    edition_id VARCHAR(15),                         -- Edition identifier (FK to fact tables)
    city VARCHAR(50) NOT NULL,                      -- City name
    state VARCHAR(50) NOT NULL,                     -- State name
    tier VARCHAR(7) NOT NULL                        -- Tier classification (Tier-1, Tier-2, Tier-3)
);

-- ===============================================================
-- Fact Tables
-- ===============================================================

-- =======================
-- 1. Ad Revenue Fact Table
-- Tracks ad revenue by category, edition, and quarter
-- =======================
CREATE TABLE IF NOT EXISTS fact_ad_revenue (
    edition_id VARCHAR(15),                         -- Edition identifier (FK to dim_city)
    ad_category_id VARCHAR(10),                     -- FK to dim_ad_category
    quarter VARCHAR(9),                             -- Reporting quarter (YYYY-QX)
    ad_revenue_inINR DECIMAL(15,2),                 -- Revenue in INR
    FOREIGN KEY (ad_category_id) REFERENCES dim_ad_category(ad_category_id)
);

-- =========================
-- 2. City Readiness Fact
-- Captures readiness metrics like literacy, smartphone & internet penetration
-- =========================
CREATE TABLE IF NOT EXISTS fact_city_readiness (
    city_id VARCHAR(10),                            -- FK to dim_city
    quarter VARCHAR(9),                             -- Reporting quarter (YYYY-QX)
    literacy_rate DECIMAL(5,2),                     -- Literacy rate (percentage)
    smartphone_penetration DECIMAL(5,2),            -- Smartphone penetration (%)
    internet_penetration DECIMAL(5,2),              -- Internet penetration (%)
    FOREIGN KEY (city_id) REFERENCES dim_city(city_id)
);

-- =======================
-- 3. Digital Pilot Fact
-- Stores digital experiment data like users, downloads, bounce rate
-- =======================
CREATE TABLE IF NOT EXISTS fact_digital_pilot (
    ad_category_id VARCHAR(10),                     -- FK to dim_ad_category
    city_id VARCHAR(10),                            -- FK to dim_city
    platform VARCHAR(150) NOT NULL,                 -- Digital platform name
    launch_month VARCHAR(9) NOT NULL,               -- Launch month (YYYY-MM)
    dev_cost DECIMAL(15,2),                         -- Development cost
    market_cost DECIMAL(15,2),                      -- Marketing cost
    users_reached INT,                              -- Total users reached
    downloads_or_accesses INT,                      -- Downloads or accesses
    avg_bounce_rate FLOAT,                          -- Engagement metric (lower is better)
    FOREIGN KEY (ad_category_id) REFERENCES dim_ad_category(ad_category_id),
    FOREIGN KEY (city_id) REFERENCES dim_city(city_id)
);

-- ======================
-- 4. Print Sales Fact
-- Stores monthly print performance (sales, circulation, returns)
-- ======================
CREATE TABLE IF NOT EXISTS fact_print_sales (
    edition_id VARCHAR(15),                         -- Edition identifier (FK to dim_city)
    city_id VARCHAR(10),                            -- FK to dim_city
    language VARCHAR(20),                           -- Language of edition
    state VARCHAR(50),                              -- State name (for quick reporting)
    month DATE,                                     -- Month of data
    copies_sold INT,                                -- Total copies sold
    net_circulation INT,                            -- Net circulation after returns
    copies_returned INT,                            -- Returned copies
    FOREIGN KEY (city_id) REFERENCES dim_city(city_id)
);
