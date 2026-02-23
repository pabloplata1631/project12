-- ==========================================
-- QUERY 1: FIXED - No Duplicates
-- ==========================================
-- Removed fee schedule join to eliminate duplicates
-- Fee schedule can be queried separately if needed

SELECT 
    -- Insurance Carrier
    ins.INSCONAME AS insurance_carrier,
    
    -- Plan Name
    ins.GROUPNAME AS plan_name,
    
    -- Group Number
    ins.GROUPNUM AS group_number,
    
    -- Coverage (per person and per family)
    ins.MAXCOVPERSON AS max_coverage_per_person,
    ins.MAXCOVFAMILY AS max_coverage_per_family,
    
    -- Annual Deductibles by Category (Per Person)
    ins.DEDPERPERSON AS annual_ded_per_person_diag_prev,
    ins.DEDPERPERSON2 AS annual_ded_per_person_standard,
    ins.DEDPERPERSON3 AS annual_ded_per_person_preventive,
    ins.DEDPERPERSONLT AS annual_ded_per_person_other,
    
    -- Lifetime Deductibles by Category (Per Person)
    ins.DEDPERPERSON2LT AS lifetime_ded_per_person_standard,
    ins.DEDPERPERSON3LT AS lifetime_ded_per_person_preventive,
    
    -- Annual Deductibles by Category (Per Family)
    ins.DEDPERFAMILY2 AS annual_ded_per_family_standard,
    ins.DEDPERFAMILY3 AS annual_ded_per_family_preventive,
    
    -- Employer Name
    emp.NAME AS employer_name,
    
    -- Address/Phone (for Insurance)
    ins.STREET AS address_line1,
    ins.STREET2 AS address_line2,
    ins.CITY,
    ins.STATE,
    ins.ZIP,
    ins.PHONE,
    ins.EXT AS phone_extension,
    
    -- Electronic Payor ID (tells clearinghouse where to send claim)
    ins.PAYERID AS electronic_payor_id,
    
    -- Fee Schedule Number (tells us what they're going to pay)
    ins.FEESCHEDID AS fee_schedule_number,
    
    -- Insurance IDs (for joining to coverage tables)
    ins.INSID AS insurance_id,
    ins.INSDB AS insurance_db_id

FROM ddb_insurance_base ins

LEFT JOIN DDB_EMP_BASE emp 
    ON ins.EMPID = emp.EMPID 
    AND ins.EMPDB = emp.EMPDB

-- Filter out deleted/invalid records
WHERE ins.INSID > 0;


-- ==========================================
-- QUERY 2: COVERAGE TABLES - FIXED
-- ==========================================
-- Now you can filter by specific insurance_db_id if needed
-- Based on your data, it looks like insurance_db_id = 2 has the 77 records you want

SELECT 
    cov.INSID AS insurance_id,
    cov.INSDB AS insurance_db_id,
    cov.NAME AS coverage_table_name,
    cov.BEGPROC AS beginning_procedure_code,
    cov.ENDPROC AS ending_procedure_code,
    cov.COPAYMENT AS copayment,
    cov.PERCENTPAY AS percent_covered_by_insurance,
    cov.PREAUTHREQ AS preauth_required,
    
    -- Insurance plan details
    ins.INSCONAME AS insurance_carrier,
    ins.GROUPNAME AS plan_name,
    ins.GROUPNUM AS group_number
    
FROM DDB_INSTABLE_BASE cov

INNER JOIN ddb_insurance_base ins
    ON cov.INSID = ins.INSID
    AND cov.INSDB = ins.INSDB

WHERE cov.UINSTABID > 0  -- Filter out deleted/invalid records
  -- OPTIONAL: Add this filter if you only want the 77 records from insurance_db_id = 2
   AND cov.INSDB = 2

ORDER BY cov.INSID, cov.INSDB, cov.BEGPROC;


-- ==========================================
-- QUERY 3: COMBINED VIEW - FIXED
-- ==========================================
-- This will now show one row per unique insurance plan
-- (unique by INSID + INSDB combination)

SELECT 
    -- Insurance Carrier
    ins.INSCONAME AS insurance_carrier,
    
    -- Plan Name
    ins.GROUPNAME AS plan_name,
    
    -- Group Number
    ins.GROUPNUM AS group_number,
    
    -- Coverage limits
    ins.MAXCOVPERSON AS max_coverage_per_person,
    ins.MAXCOVFAMILY AS max_coverage_per_family,
    
    -- Annual Deductibles by Category (Per Person)
    ins.DEDPERPERSON AS annual_ded_per_person_diag_prev,
    ins.DEDPERPERSON2 AS annual_ded_per_person_standard,
    ins.DEDPERPERSON3 AS annual_ded_per_person_preventive,
    ins.DEDPERPERSONLT AS annual_ded_per_person_other,
    
    -- Lifetime Deductibles by Category (Per Person)
    ins.DEDPERPERSON2LT AS lifetime_ded_per_person_standard,
    ins.DEDPERPERSON3LT AS lifetime_ded_per_person_preventive,
    
    -- Annual Deductibles by Category (Per Family)
    ins.DEDPERFAMILY2 AS annual_ded_per_family_standard,
    ins.DEDPERFAMILY3 AS annual_ded_per_family_preventive,
    
    -- Employer Name
    emp.NAME AS employer_name,
    
    -- Address/Phone
    ins.STREET AS address_line1,
    ins.STREET2 AS address_line2,
    ins.CITY,
    ins.STATE,
    ins.ZIP,
    ins.PHONE,
    ins.EXT AS phone_extension,
    
    -- Electronic Payor ID
    ins.PAYERID AS electronic_payor_id,
    
    -- Fee Schedule
    ins.FEESCHEDID AS fee_schedule_number,
    
    -- Insurance IDs
    ins.INSID AS insurance_id,
    ins.INSDB AS insurance_db_id,
    
    -- Coverage table count
    COUNT(cov.UINSTABID) AS num_coverage_table_entries

FROM ddb_insurance_base ins

LEFT JOIN DDB_EMP_BASE emp 
    ON ins.EMPID = emp.EMPID 
    AND ins.EMPDB = emp.EMPDB

-- Join to coverage tables
LEFT JOIN DDB_INSTABLE_BASE cov
    ON ins.INSID = cov.INSID
    AND ins.INSDB = cov.INSDB

WHERE ins.INSID > 0

GROUP BY 
    ins.INSID,
    ins.INSDB,
    ins.INSCONAME,
    ins.GROUPNAME,
    ins.GROUPNUM,
    ins.MAXCOVPERSON,
    ins.MAXCOVFAMILY,
    ins.DEDPERPERSON,
    ins.DEDPERPERSON2,
    ins.DEDPERPERSON3,
    ins.DEDPERPERSONLT,
    ins.DEDPERPERSON2LT,
    ins.DEDPERPERSON3LT,
    ins.DEDPERFAMILY2,
    ins.DEDPERFAMILY3,
    emp.NAME,
    ins.STREET,
    ins.STREET2,
    ins.CITY,
    ins.STATE,
    ins.ZIP,
    ins.PHONE,
    ins.EXT,
    ins.PAYERID,
    ins.FEESCHEDID;


-- ==========================================
-- OPTIONAL: Fee Schedule Lookup Query
-- ==========================================
-- If you need fee schedule names, query them separately
-- This avoids the duplication issue in the main query

SELECT 
    ins.INSID AS insurance_id,
    ins.INSDB AS insurance_db_id,
    ins.INSCONAME AS insurance_carrier,
    ins.GROUPNAME AS plan_name,
    ins.FEESCHEDID AS fee_schedule_number,
    fee.FeeName AS fee_schedule_name
FROM ddb_insurance_base ins
LEFT JOIN DDB_FEESCHED_ITEM_BASE fee 
    ON ins.FEESCHEDID = fee.FEESCHID 
    AND ins.FEESCHEDDB = fee.FEESCHDB
    AND fee.PROC_CODEID = 0
WHERE ins.INSID > 0
GROUP BY 
    ins.INSID,
    ins.INSDB,
    ins.INSCONAME,
    ins.GROUPNAME,
    ins.FEESCHEDID,
    fee.FeeName;


-- ==========================================
-- UNDERSTANDING YOUR DATA
-- ==========================================
-- Based on your results, here's what's happening:
--
-- For insurance plan "NJ-PDP-000001-024659":
--   INSID = 1177533 or 1238651 or 1255086 (same plan, different IDs?)
--   INSDB = 2, 1004451, 1004392 (three different database instances)
--
-- Each combination of INSID + INSDB represents a unique instance
-- of the insurance plan, possibly in different practice databases.
--
-- Your coverage table data shows:
--   - INSID=1177533, INSDB=2:        77 coverage entries
--   - INSID=1238651, INSDB=1004451: 154 coverage entries (same as below)
--   - INSID=1255086, INSDB=1004392: 154 coverage entries (duplicate structure)
--
-- The 77 vs 154 difference might be because:
--   1. Different versions of the same plan
--   2. One is more detailed/granular
--   3. Different effective dates/configurations
--
-- To get ONLY the 77 records, add this to Query 2:
--   AND cov.INSDB = 2
--   AND cov.INSID = 1177533
