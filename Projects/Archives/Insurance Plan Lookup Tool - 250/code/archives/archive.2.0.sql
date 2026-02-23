-- Insurance Plan Lookup Query - CORRECTED
-- Retrieves essential insurance plan information from Dentrix Enterprise database

SELECT 
    -- Insurance Carrier
    ins.INSCONAME AS insurance_carrier,
    
    -- Plan Name
    ins.GROUPNAME AS plan_name,
    
    -- Coverage (per person and per family)
    ins.MAXCOVPERSON AS max_coverage_per_person,
    ins.MAXCOVFAMILY AS max_coverage_per_family,
    
    -- Deductibles (per person and per family)
    ins.DEDPERPERSON AS deductible_per_person,
    ins.DEDPERFAMILY AS deductible_per_family,
    
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

FROM ddb_insurance_base ins

-- Join to Fee Schedule for fee schedule name
-- CORRECTED: Join on FEESCHID (not UFEESCHID) and match FEESCHEDDB on both sides
LEFT JOIN DDB_FEESCHED_ITEM_BASE fee 
    ON ins.FEESCHEDID = fee.FEESCHID 
    AND   ins.FEESCHEDDB = fee.FEESCHDB
    AND fee.PROC_CODEID = 0  -- Fee schedule name records have PROC_CODEID = 0

-- Join to Employer for employer name
LEFT JOIN DDB_EMP_BASE emp 
    ON ins.EMPID = emp.EMPID 
    AND ins.EMPDB = emp.EMPDB

-- Filter out deleted/invalid records
WHERE ins.INSID > 0

ORDER BY ins.INSCONAME, ins.GROUPNAME;