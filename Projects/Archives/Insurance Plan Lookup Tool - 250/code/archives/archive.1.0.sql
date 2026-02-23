
SELECT 
    -- Insurance Carrier
    ins.INSCONAME AS insurance_carrier,
    -- Plan Name
    ins.GROUPNAME AS plan_name,
    -- Coverage
    ins.MAXCOVPERSON AS max_coverage_per_person,
    ins.MAXCOVFAMILY AS max_coverage_per_family,
    -- Deductibles
    ins.DEDPERPERSON AS deductible_per_person,
    ins.DEDPERFAMILY AS deductible_per_family,  
    -- Address/Phone (for Insurance)
    ins.STREET AS address_line1,
    ins.STREET2 AS address_line2,
    ins.CITY,
    ins.STATE,
    ins.ZIP,
    ins.PHONE,
    ins.EXT AS phone_extension,
    -- Electronic Payor ID
    ins.PAYERID AS electronic_payor_id,
    -- Fee Schedule Number
    ins.FEESCHEDID AS fee_schedule_number,
    -- Fee Schedule Name
	fee.FeeName AS fee_schedule_name,
       -- Employer Name
    emp.NAME AS employer_name

FROM Dentrix.dbo.ddb_insurance_base ins
-- Join to Fee Schedule for fee schedule name
LEFT JOIN Dentrix.dbo.DDB_FEESCHED_ITEM_BASE fee 
    ON ins.FEESCHEDID = fee.FEESCHID 
    AND ins.FEESCHEDDB = fee.FEESCHID
-- Join to Employer for employer name
LEFT JOIN Dentrix.dbo.DDB_EMP_BASE emp 
    ON ins.EMPID = emp.EMPID 
    AND ins.EMPDB = emp.EMPDB
-- Filter out deleted/invalid records
WHERE ins.INSID > 0
ORDER BY ins.INSCONAME, ins.GROUPNAME;


