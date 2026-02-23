
-- Insurance Plan Lookup Query
-- Retrieves essential insurance plan information from Dentrix Enterprise database

SELECT 
    ins.INSCONAME AS insurance_carrier,
    ins.GROUPNAME AS plan_name,
    ins.MAXCOVPERSON AS max_coverage_per_person,
    ins.MAXCOVFAMILY AS max_coverage_per_family,
    ins.DEDPERPERSON AS deductible_per_person,
    ins.DEDPERFAMILY AS deductible_per_family,  
    ins.STREET AS address_line1,
    ins.STREET2 AS address_line2,
    ins.CITY,
    ins.STATE,
    ins.ZIP,
    ins.PHONE,
    ins.EXT AS phone_extension,
    ins.PAYERID AS electronic_payor_id,
    ins.FEESCHEDID AS fee_schedule_number,
	fee.FeeName AS fee_schedule_name,
    emp.NAME AS employer_name
FROM ddb_insurance_base ins
LEFT JOIN DDB_FEESCHED_ITEM_BASE fee 
    ON ins.FEESCHEDID = fee.FEESCHID 
    AND ins.FEESCHEDDB = fee.FEESCHID
LEFT JOIN DDB_EMP_BASE emp 
    ON ins.EMPID = emp.EMPID 
    AND ins.EMPDB = emp.EMPDB
WHERE ins.INSID > 0
--ORDER BY ins.INSCONAME, ins.GROUPNAME



Select top 199 * from DDB_FEESCHED_ITEM_BASE fee 
