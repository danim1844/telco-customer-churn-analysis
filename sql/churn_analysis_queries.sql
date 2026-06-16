-- ============================================================
-- TELCO CUSTOMER CHURN ANALYSIS
-- Author: Daniel Mandisen
-- Tool: Google BigQuery
-- Date: June 2026
-- Dataset: IBM Telco Customer Churn (Kaggle)
-- ============================================================


-- ============================================================
-- QUERY 1 — Overall Churn Rate
-- Intent: Establish the baseline churn rate across all customers
-- to define the scope of the business problem.
-- ============================================================

SELECT 
  `Churn Label`,
  COUNT(*) AS total_customers,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM `our-signal-496317-q7.telco_churn.customer_data`
GROUP BY `Churn Label`;

-- Result: 26.54% of customers have churned (1,869 out of 7,043)


-- ============================================================
-- QUERY 2 — Churn by Contract Type
-- Intent: Determine whether contract type is a predictor of churn.
-- Hypothesis: customers with less commitment churn more frequently.
-- ============================================================

SELECT 
  Contract,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN `Churn Label` = true THEN 1 ELSE 0 END) AS churned_customers,
  ROUND(SUM(CASE WHEN `Churn Label` = true THEN 1 ELSE 0 END) 
    * 100.0 / COUNT(*), 2) AS churn_rate
FROM `our-signal-496317-q7.telco_churn.customer_data`
GROUP BY Contract
ORDER BY churn_rate DESC;

-- Result: Month-to-month 42.71% | One year 11.27% | Two year 2.83%
-- Finding: Contract type is the strongest single predictor of churn


-- ============================================================
-- QUERY 3 — Churn by Tenure Group
-- Intent: Identify which stage of the customer lifecycle carries
-- the highest churn risk using CASE WHEN binning.
-- ============================================================

SELECT 
  CASE 
    WHEN `Tenure Months` <= 12 THEN '0-12 Months (New)'
    WHEN `Tenure Months` <= 24 THEN '13-24 Months (Developing)'
    WHEN `Tenure Months` <= 48 THEN '25-48 Months (Established)'
    ELSE '49+ Months (Loyal)'
  END AS tenure_group,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN `Churn Label` = true THEN 1 ELSE 0 END) AS churned_customers,
  ROUND(SUM(CASE WHEN `Churn Label` = true THEN 1 ELSE 0 END) 
    * 100.0 / COUNT(*), 2) AS churn_rate
FROM `our-signal-496317-q7.telco_churn.customer_data`
GROUP BY tenure_group
ORDER BY churn_rate DESC;

-- Result: New 47.44% | Developing 28.71% | Established 20.39% | Loyal 9.51%
-- Finding: First 12 months is the highest risk window for churn


-- ============================================================
-- QUERY 4 — Churn by Monthly Charges
-- Intent: Investigate whether pricing level drives customer
-- departure using four pricing tiers.
-- ============================================================

SELECT 
  CASE 
    WHEN `Monthly Charges` <= 35 THEN 'Low ($0-$35)'
    WHEN `Monthly Charges` <= 65 THEN 'Medium ($36-$65)'
    WHEN `Monthly Charges` <= 85 THEN 'High ($66-$85)'
    ELSE 'Very High ($86+)'
  END AS charge_group,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN `Churn Label` = true THEN 1 ELSE 0 END) AS churned_customers,
  ROUND(SUM(CASE WHEN `Churn Label` = true THEN 1 ELSE 0 END) 
    * 100.0 / COUNT(*), 2) AS churn_rate
FROM `our-signal-496317-q7.telco_churn.customer_data`
GROUP BY charge_group
ORDER BY churn_rate DESC;

-- Result: High 35.89% | Very High 33.82% | Medium 23.14% | Low 10.89%
-- Finding: $66-$85 tier has highest churn suggesting price-value mismatch


-- ============================================================
-- QUERY 5 — Top 10 Churn Reasons
-- Intent: Analyze the qualitative churn reason column to identify
-- dominant themes driving customer departure.
-- WHERE filter isolates only churned customers with recorded reasons.
-- ============================================================

SELECT 
  `Churn Reason`,
  COUNT(*) AS total_customers,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM `our-signal-496317-q7.telco_churn.customer_data`
WHERE `Churn Label` = true
  AND `Churn Reason` IS NOT NULL
GROUP BY `Churn Reason`
ORDER BY total_customers DESC
LIMIT 10;

-- Result: Attitude of support person 10.27% | Competitor speeds 10.11%
-- Finding: Service attitude is #1 individual reason; competition drives ~43% combined


-- ============================================================
-- QUERY 6 — High Risk Customer Profile
-- Intent: Build a definitive high-risk profile by combining
-- contract type, tenure, and monthly charges simultaneously.
-- Multi-dimensional analysis to pinpoint the exact customer
-- combination most likely to churn.
-- ============================================================

SELECT 
  Contract,
  CASE 
    WHEN `Tenure Months` <= 12 THEN '0-12 Months (New)'
    WHEN `Tenure Months` <= 24 THEN '13-24 Months (Developing)'
    WHEN `Tenure Months` <= 48 THEN '25-48 Months (Established)'
    ELSE '49+ Months (Loyal)'
  END AS tenure_group,
  CASE 
    WHEN `Monthly Charges` <= 35 THEN 'Low ($0-$35)'
    WHEN `Monthly Charges` <= 65 THEN 'Medium ($36-$65)'
    WHEN `Monthly Charges` <= 85 THEN 'High ($66-$85)'
    ELSE 'Very High ($86+)'
  END AS charge_group,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN `Churn Label` = true THEN 1 ELSE 0 END) AS churned_customers,
  ROUND(SUM(CASE WHEN `Churn Label` = true THEN 1 ELSE 0 END) 
    * 100.0 / COUNT(*), 2) AS churn_rate
FROM `our-signal-496317-q7.telco_churn.customer_data`
GROUP BY Contract, tenure_group, charge_group
ORDER BY churn_rate DESC
LIMIT 10;

-- Result: New month-to-month customers paying $86+ churn at 74.92%
-- Finding: All top 10 highest risk combinations are month-to-month contracts
-- Action: Flag new month-to-month customers paying $66+ for immediate intervention
