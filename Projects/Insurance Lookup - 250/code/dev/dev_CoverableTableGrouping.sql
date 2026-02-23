
-- ==========================================
-- QUERY 2 UPDATED: COVERAGE TABLES GROUPED BY CATEGORY
-- ==========================================
-- This groups coverage entries by procedure code category
-- to dramatically reduce the number of rows (from 11M to manageable)
--
-- Instead of one row per procedure code range (D0100-D0209, D0210-D0210, etc.),
-- you'll get one row per category (Diagnostic, Preventive, etc.)

SELECT 
    cov.INSID AS insurance_id,
    cov.INSDB AS insurance_db_id,
    
    -- Insurance plan details
    ins.INSCONAME AS insurance_carrier,
    ins.GROUPNAME AS plan_name,
    ins.GROUPNUM AS group_number,
    
    -- Category from procedure codes (this is the key grouping)
    pc.CATEGORY AS procedure_category_id,
    
    -- Summary statistics for this category
    MIN(cov.BEGPROC) AS first_procedure_code,
    MAX(cov.ENDPROC) AS last_procedure_code,
    COUNT(*) AS num_coverage_entries,
    
    -- Most common coverage percentage for this category
    -- (using MAX since there might be variations)
    MAX(cov.PERCENTPAY) AS max_percent_covered,
    MIN(cov.PERCENTPAY) AS min_percent_covered,
    
    -- Most common copayment
    MAX(cov.COPAYMENT) AS max_copayment,
    MIN(cov.COPAYMENT) AS min_copayment,
    
    -- Check if any require pre-auth
    MAX(cov.PREAUTHREQ) AS any_preauth_required

FROM DDB_INSTABLE_BASE cov

INNER JOIN ddb_insurance_base ins
    ON cov.INSID = ins.INSID
    AND cov.INSDB = ins.INSDB

-- Join to procedure codes to get the category
LEFT JOIN DDB_PROC_CODE_BASE pc
    ON pc.ADACODE = cov.BEGPROC
    AND pc.PROC_CODEDB = cov.INSDB

WHERE cov.UINSTABID > 0
and GROUPNUM = '5384577'
 and GROUPNAME = 'NJ-PDP-000001-024659'

GROUP BY 
    cov.INSID,
    cov.INSDB,
    ins.INSCONAME,
    ins.GROUPNAME,
    ins.GROUPNUM,
    pc.CATEGORY

ORDER BY 
    cov.INSID, 
    cov.INSDB, 
    pc.CATEGORY;


-- ==========================================
-- ALTERNATIVE: WITH CATEGORY NAMES
-- ==========================================
-- If you have a lookup table for category names, use this version
-- Category IDs typically map to:
-- 0 = Diagnostic
-- 1 = Preventive  
-- 2 = Restorative
-- 3 = Endodontics
-- 4 = Periodontics
-- 5 = Prosthodontics, Removable
-- 6 = Maxillofacial Prosthetics
-- 7 = Implant Services
-- 8 = Prosthodontics, Fixed
-- 9 = Oral Surgery
-- 10 = Orthodontics
-- 11 = Adjunctive Services
-- (these are typical mappings but verify with your system)

SELECT 
    cov.INSID AS insurance_id,
    cov.INSDB AS insurance_db_id,
    
    -- Insurance plan details
    ins.INSCONAME AS insurance_carrier,
    ins.GROUPNAME AS plan_name,
    ins.GROUPNUM AS group_number,
    
    -- Category
    pc.CATEGORY AS category_id,
    CASE pc.CATEGORY
        WHEN 0 THEN 'Diagnostic'
        WHEN 1 THEN 'Preventive'
        WHEN 2 THEN 'Restorative'
        WHEN 3 THEN 'Endodontics'
        WHEN 4 THEN 'Periodontics'
        WHEN 5 THEN 'Prosth, remov'
        WHEN 6 THEN 'Maxillo Prosth'
        WHEN 7 THEN 'Implant Serv'
        WHEN 8 THEN 'Prostho, Fixed'
        WHEN 9 THEN 'Oral Surgery'
        WHEN 10 THEN 'Orthodontics'
        WHEN 11 THEN 'Adjunct Serv'
        WHEN 999 THEN 'MultiCode'
        ELSE 'Other'
    END AS category_name,
    
    -- Procedure code range
    MIN(cov.BEGPROC) AS first_procedure_code,
    MAX(cov.ENDPROC) AS last_procedure_code,
    
    -- Count of individual coverage entries
    COUNT(*) AS num_coverage_entries,
    
    -- Coverage percentages (show range if varies)
    MAX(cov.PERCENTPAY) AS max_percent_covered,
    MIN(cov.PERCENTPAY) AS min_percent_covered,
    AVG(CAST(cov.PERCENTPAY AS FLOAT)) AS avg_percent_covered,
    
    -- Copayments (show range if varies)
    MAX(cov.COPAYMENT) AS max_copayment,
    MIN(cov.COPAYMENT) AS min_copayment,
    
    -- Pre-authorization
    MAX(cov.PREAUTHREQ) AS any_preauth_required,
    
    -- Show if coverage varies within category
    CASE 
        WHEN MAX(cov.PERCENTPAY) = MIN(cov.PERCENTPAY) THEN 'Uniform'
        ELSE 'Varies'
    END AS coverage_consistency

FROM DDB_INSTABLE_BASE cov

INNER JOIN ddb_insurance_base ins
    ON cov.INSID = ins.INSID
    AND cov.INSDB = ins.INSDB

-- Join to procedure codes to get the category
LEFT JOIN DDB_PROC_CODE_BASE pc
    ON pc.ADACODE = cov.BEGPROC
    AND pc.PROC_CODEDB = cov.INSDB

WHERE cov.UINSTABID > 0
and GROUPNUM = '5384577'
 and GROUPNAME = 'NJ-PDP-000001-024659'

GROUP BY 
    cov.INSID,
    cov.INSDB,
    ins.INSCONAME,
    ins.GROUPNAME,
    ins.GROUPNUM,
    pc.CATEGORY

ORDER BY 
    cov.INSID, 
    cov.INSDB, 
    pc.CATEGORY;


-- ==========================================
-- SIMPLIFIED VERSION: JUST SHOW WHAT YOU NEED
-- ==========================================
-- This gives you a clean summary per insurance plan per category

SELECT 
    ins.INSCONAME AS insurance_carrier,
    ins.GROUPNAME AS plan_name,
    ins.GROUPNUM AS group_number,
    
    -- Category
    CASE pc.CATEGORY
        WHEN 0 THEN 'Diagnostic'
        WHEN 1 THEN 'Preventive'
        WHEN 2 THEN 'Restorative'
        WHEN 3 THEN 'Endodontics'
        WHEN 4 THEN 'Periodontics'
        WHEN 5 THEN 'Prosth, remov'
        WHEN 6 THEN 'Maxillo Prosth'
        WHEN 7 THEN 'Implant Serv'
        WHEN 8 THEN 'Prostho, Fixed'
        WHEN 9 THEN 'Oral Surgery'
        WHEN 10 THEN 'Orthodontics'
        WHEN 11 THEN 'Adjunct Serv'
        ELSE 'Other'
    END AS category_name,
    
    -- Coverage summary (assuming it's uniform within category)
    -- If it varies, this will show the max
    MAX(cov.PERCENTPAY) AS percent_covered,
    MAX(cov.COPAYMENT) AS copayment,
    MAX(cov.PREAUTHREQ) AS preauth_required

FROM DDB_INSTABLE_BASE cov

INNER JOIN ddb_insurance_base ins
    ON cov.INSID = ins.INSID
    AND cov.INSDB = ins.INSDB

LEFT JOIN DDB_PROC_CODE_BASE pc
    ON pc.ADACODE = cov.BEGPROC
    AND pc.PROC_CODEDB = cov.INSDB

WHERE cov.UINSTABID > 0
  -- Optional: filter to specific insurance plan
  -- AND cov.INSID = 1177533
  -- AND cov.INSDB = 2
  and GROUPNUM = '5384577'
 and GROUPNAME = 'NJ-PDP-000001-024659'

GROUP BY 
    cov.INSID,
    cov.INSDB,
    ins.INSCONAME,
    ins.GROUPNAME,
    ins.GROUPNUM,
    pc.CATEGORY

ORDER BY 
    ins.INSCONAME,
    ins.GROUPNAME,
    pc.CATEGORY;


-- ==========================================
-- EXPLANATION
-- ==========================================
-- Your 11 million records are because you have:
-- - Many insurance plans
-- - Each with many detailed procedure code ranges
--
-- By grouping by CATEGORY, you reduce:
--   77 detailed entries → ~12 category summaries (per plan)
--   11 million entries → ~140,000 category summaries (rough estimate)
--
-- This is much more manageable and matches how the UI shows data!