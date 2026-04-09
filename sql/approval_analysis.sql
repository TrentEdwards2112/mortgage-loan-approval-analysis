-- =========================================
-- Mortgage Loan Approval Analysis
-- Author: Trent Edwards
-- =========================================

-- =========================================
-- 1. Create Database
-- =========================================
CREATE DATABASE mortgage_project2;
USE mortgage_project2;

-- =========================================
-- 2. Load Raw Data
-- =========================================
LOAD DATA LOCAL INFILE 'mortgage_loans_project2_raw.csv'
INTO TABLE mortgage_loans_imported
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- =========================================
-- 3. Data Cleaning
-- =========================================
CREATE TABLE mortgage_loans_clean AS
SELECT
    loan_id,
    origination_date,

    -- Standardize state
    CASE
        WHEN UPPER(TRIM(state)) IN ('CA', 'CALIFORNIA') THEN 'CA'
        WHEN UPPER(TRIM(state)) IN ('TX', 'TEXAS') THEN 'TX'
        WHEN UPPER(TRIM(state)) IN ('FL', 'FLORIDA') THEN 'FL'
        WHEN UPPER(TRIM(state)) IN ('AZ', 'ARIZONA') THEN 'AZ'
        WHEN UPPER(TRIM(state)) IN ('WA', 'WASHINGTON') THEN 'WA'
        WHEN UPPER(TRIM(state)) IN ('OH', 'OHIO') THEN 'OH'
        WHEN UPPER(TRIM(state)) IN ('IL', 'ILLINOIS') THEN 'IL'
        WHEN UPPER(TRIM(state)) IN ('GA', 'GEORGIA') THEN 'GA'
        WHEN UPPER(TRIM(state)) IN ('PA', 'PENNSYLVANIA') THEN 'PA'
        WHEN UPPER(TRIM(state)) IN ('NY', 'NEW YORK') THEN 'NY'
        ELSE UPPER(TRIM(state))
    END AS state,

    region,

    -- Standardize employment status
    CASE
        WHEN LOWER(TRIM(employment_status)) LIKE '%self%' THEN 'Self-Employed'
        WHEN LOWER(TRIM(employment_status)) LIKE '%part%' THEN 'Part-Time'
        WHEN LOWER(TRIM(employment_status)) LIKE '%full%' THEN 'Full-Time'
        ELSE TRIM(employment_status)
    END AS employment_status,

    income,
    credit_score,
    debt_to_income,
    loan_purpose,
    loan_type,
    loan_term,
    property_value,
    loan_to_value,
    loan_amount,
    interest_rate,

    -- Standardize loan status
    CASE
        WHEN LOWER(TRIM(loan_status)) = 'approved' THEN 'Approved'
        WHEN LOWER(TRIM(loan_status)) = 'denied' THEN 'Denied'
        WHEN LOWER(TRIM(loan_status)) = 'pending' THEN 'Pending'
        ELSE TRIM(loan_status)
    END AS loan_status,

    default_risk
FROM mortgage_loans_imported;

-- =========================================
-- 4. Feature Engineering
-- =========================================
CREATE TABLE mortgage_loans_enhanced AS
SELECT
    *,

    -- Approval flag
    CASE 
        WHEN loan_status = 'Approved' THEN 1
        ELSE 0
    END AS approval_flag,

    -- Loan size band
    CASE
        WHEN loan_amount < 100000 THEN 'Small'
        WHEN loan_amount BETWEEN 100000 AND 300000 THEN 'Medium'
        WHEN loan_amount BETWEEN 300000 AND 600000 THEN 'Large'
        ELSE 'Very Large'
    END AS loan_size_band,

    -- Income band
    CASE
        WHEN income < 50000 THEN 'Low'
        WHEN income BETWEEN 50000 AND 100000 THEN 'Middle'
        ELSE 'High'
    END AS income_band,

    YEAR(origination_date) AS origination_year,
    MONTH(origination_date) AS origination_month

FROM mortgage_loans_clean;

-- =========================================
-- 5. Analysis
-- =========================================

-- Overall Approval Rate
SELECT 
    COUNT(*) AS total_loans,
    SUM(approval_flag) AS approved_loans,
    ROUND(SUM(approval_flag) * 100.0 / COUNT(*), 2) AS approval_rate_pct
FROM mortgage_loans_enhanced;

-- Approval Rate by Loan Size
SELECT 
    loan_size_band,
    COUNT(*) AS total_loans,
    SUM(approval_flag) AS approved_loans,
    ROUND(SUM(approval_flag) * 100.0 / COUNT(*), 2) AS approval_rate_pct
FROM mortgage_loans_enhanced
GROUP BY loan_size_band
ORDER BY approval_rate_pct DESC;

-- Approval Rate by Income Band
SELECT
    income_band,
    COUNT(*) AS total_loans,
    SUM(approval_flag) AS approved_loans,
    ROUND(SUM(approval_flag) * 100.0 / COUNT(*), 2) AS approval_rate_pct
FROM mortgage_loans_enhanced
GROUP BY income_band
ORDER BY approval_rate_pct DESC;

-- Approval Rate by Region
SELECT 
    region,
    COUNT(*) AS total_loans,
    SUM(approval_flag) AS approved_loans,
    ROUND(SUM(approval_flag) * 100.0 / COUNT(*), 2) AS approval_rate_pct
FROM mortgage_loans_enhanced
GROUP BY region
ORDER BY approval_rate_pct DESC;

-- Monthly Trend
SELECT
    origination_year,
    origination_month,
    COUNT(*) AS total_loans,
    SUM(approval_flag) AS approved_loans,
    ROUND(SUM(approval_flag) * 100.0 / COUNT(*), 2) AS approval_rate_pct
FROM mortgage_loans_enhanced
GROUP BY origination_year, origination_month
ORDER BY origination_year, origination_month;

-- Loan Size + Income
SELECT
    loan_size_band,
    income_band,
    COUNT(*) AS total_loans,
    SUM(approval_flag) AS approved_loans,
    ROUND(SUM(approval_flag) * 100.0 / COUNT(*), 2) AS approval_rate_pct
FROM mortgage_loans_enhanced
GROUP BY loan_size_band, income_band
ORDER BY loan_size_band, approval_rate_pct DESC;
