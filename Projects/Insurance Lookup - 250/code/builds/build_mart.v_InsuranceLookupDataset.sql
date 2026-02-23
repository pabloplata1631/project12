--================================================================
--use to build the Insurance Lookup Dataset view in the mart schema
--Pablo Plata
--2/5/2026
--================================================================

USE [smilist_data_warehouse]
GO

-- Drop the view if it exists
IF OBJECT_ID('mart.v_InsuranceLookupDataset', 'V') IS NOT NULL
    DROP VIEW mart.v_InsuranceLookupDataset;
GO

-- Create the view
CREATE VIEW mart.v_InsuranceLookupDataset
AS

 -- ====================
-- CTE 1 BaseInsurance 
-- ====================

WITH BaseInsurance AS (
    SELECT 
        INSID,
        INSCONAME,
        GROUPNAME,
        GROUPNUM,
        MAXCOVPERSON,
        MAXCOVFAMILY,
        DEDPERPERSON,
        DEDPERPERSON2,
        DEDPERPERSON3,
        DEDPERPERSONLT,
        DEDPERPERSON2LT,
        DEDPERPERSON3LT,
        DEDPERFAMILY2,
        DEDPERFAMILY3,
        STREET,
        STREET2,
        CITY,
        STATE,
        ZIP,
        PHONE,
        EXT,
        PAYERID,
        FEESCHEDID,
        FEESCHEDDB,
        EMPID,
        EMPDB
    FROM dentrix.dbo.ddb_insurance_base
    WHERE INSID > 0
),

-- ====================
-- CTE 2: FeeSchedules Data
-- ====================
FeeSchedules AS (
    SELECT 
        FEESCHID,
        FEESCHDB,
        FeeName
    FROM dentrix.dbo.DDB_FEESCHED_ITEM_BASE
    WHERE PROC_CODEID = 0  -- Fee schedule name records
),
-- ====================
-- CTE 2: Employers Data
-- ====================
Employers AS (
    SELECT 
        EMPID,
        EMPDB,
        NAME
    FROM dentrix.dbo.DDB_EMP_BASE
)



-- ================================================================================================================================================================
-- MAIN SELECT
-- ================================================================================================================================================================

SELECT 
    ins.INSID,
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
    -- Fee Schedule Name (e.g., Delta PPO)
    fee.FeeName AS fee_schedule_name
FROM BaseInsurance ins
LEFT JOIN FeeSchedules fee 
    ON ins.FEESCHEDID = fee.FEESCHID 
    AND ins.FEESCHEDDB = fee.FEESCHDB
LEFT JOIN Employers emp 
    ON ins.EMPID = emp.EMPID 
    AND ins.EMPDB = emp.EMPDB

	
GO
---and GROUPNUM = '5384577'
 ---and GROUPNAME = 'NJ-PDP-000001-024659';
---AND ins.INSDB = 2