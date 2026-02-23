-- ============================================================================
-- DEPOSITS IN TRANSIT REPORT
-- Replicates the file provided by Brittany Cannon
-- Shows payments posted in one year but dated in the previous year
-- ============================================================================

SELECT 
    -- ====================
    -- TRANSACTION IDENTIFIERS
    -- ====================
    pl.CHART_STATUS,
    pl.CLASS,
    pl.PROC_LOGID,
    pl.PROC_LOGDB,
    
    -- ====================
    -- DATES
    -- ====================
    pl.PLDATE as DepositDate,                    -- The "deposit date" - when payment is dated
    CAST(pl.CREATEDATE AS DATE) as PostDate,     -- Date posted (no time)
    pl.CREATEDATE as PostDateTime,               -- Full date/time posted
    GETDATE() as ReportRunTime,                  -- When report was run
    
    -- ====================
    -- PAYMENT AMOUNT
    -- ====================
    pl.AMOUNT * 0.01 as Payment,
    
    -- ====================
    -- PATIENT INFO
    -- ====================
    pl.PATID,
    pl.PATDB,
    p.lastname + ',' + p.firstname as PatName,
    p.birthdate as PatDOB,
    
    -- ====================
    -- GUARANTOR
    -- ====================
    pl.GUARID,
    pl.GUARDB,
    
    -- ====================
    -- CLAIM INFO
    -- ====================
    pl.CLAIMID,
    pl.CLAIMDB,
    
    -- ====================
    -- PAYMENT TYPE CODE
    -- ====================
    pl.ORD,  -- Payment type code (0 for most insurance, 2 for cash, etc.)
    
    -- ====================
    -- STAFF WHO POSTED
    -- ====================
    ISNULL(opr.UserLoginName, '') + '--' + 
    ISNULL(opr.NAME_LAST, '') + ',' + 
    ISNULL(opr.NAME_FIRST, '') as StaffID_Name,
    
    -- Staff title/role

    
    -- ====================
    -- CLINIC INFO
    -- ====================
    ISNULL(clinic.RSCID, '') as ClinicName,
    ISNULL(clinic.RSCID, '') as ClinicName_Group,  -- Same as ClinicName unless grouped differently
    
    -- ====================
    -- PAYMENT DESCRIPTION
    -- ====================
    CASE pl.CLASS
        WHEN 1 THEN ' Cash Payment - Thank You    '  -- Guarantor payment
        WHEN 3 THEN 'Insurance Payment'               -- Insurance payment
        ELSE 'Payment'
    END as PayDescription,
    
    -- ====================
    -- CHECK/REFERENCE NUMBER
    -- ====================
    ISNULL(pl.CHECKNUM, '') as CheckNum,
    
    -- ====================
    -- ENCOUNTER NUMBER
    -- ====================
    ISNULL(pl.EncounterNum, '') as EncounterNum,
    
    -- ====================
    -- INSURANCE COMPANY
    -- ====================
    ISNULL(ins.INSCONAME, '') as InsCONAME,
    
    -- ====================
    -- PAYMENT TYPE (EFT vs Check)
    -- ====================
    CASE 
        WHEN pl.CLASS = 1 THEN ' Cash Payment - Thank You    '
        WHEN pl.AUTH_STATUS = 1 THEN 'EFTClaim'   -- Electronic payment
        WHEN pl.AUTH_STATUS = 0 THEN 'CheckClaim' -- Check payment
        ELSE 'CheckClaim'
    END as PayType,
    
    -- ====================
    -- EFT FLAG (0x01 = EFT, 0x00 = Check)
    -- ====================
    CASE 
        WHEN pl.AUTH_STATUS = 1 THEN CONVERT(varbinary(1), 0x01)
        ELSE CONVERT(varbinary(1), 0x00)
    END as EFT

FROM DDB_PROC_LOG_BASE pl

-- Join Patient
INNER JOIN DDB_PAT_BASE p
    ON pl.PATID = p.PATID
    AND pl.PATDB = p.PATDB

-- Join Operator/Staff who posted
LEFT JOIN DDB_RSC_BASE opr
    ON pl.OperatorID = opr.URSCID
    AND pl.OperatorDB = opr.RSCDB

-- Join Clinic
LEFT JOIN DDB_RSC_BASE clinic
    ON pl.ClinicAppliedTo = clinic.URSCID
    AND clinic.RSCTYPE = 0

-- Join Claim (to get insurance info)
LEFT JOIN DDB_CLAIM_BASE claim
    ON pl.CLAIMID = claim.CLAIMID
    AND pl.CLAIMDB = claim.CLAIMDB

-- Join Insurance Company
LEFT JOIN DDB_INSURANCE_BASE ins
    ON claim.INSID = ins.INSID
    AND claim.INSDB = ins.INSDB

WHERE 
    -- Only payment transactions
    pl.CHART_STATUS = 90
    AND pl.CLASS IN (1, 3)  -- 1 = Guarantor Payment, 3 = Insurance Payment
    
    -- **CRITICAL FILTER FOR "DEPOSITS IN TRANSIT"**
    -- Deposits dated in December 2025
    AND pl.PLDATE >= '2024-12-01'
    AND pl.PLDATE < '2025-01-01'
    
    -- But posted in 2026
    AND pl.CREATEDATE >= '2025-01-01'
    
    -- Exclude zero payments
    AND pl.AMOUNT <> 0

ORDER BY 
    pl.CREATEDATE DESC,
    pl.PLDATE DESC;

-- ============================================================================
-- USAGE NOTES:
-- ============================================================================
/*
This query finds "deposits in transit" which are:
- Payments that were dated in December 2025 (DepositDate)
- But were entered into the system in January 2026+ (PostDateTime)
- These create accounting timing differences between periods

To replicate Brittany's exact file:
1. Change the date filters to match the period you need
2. The sample shows Dec 2024 deposits posted in Jan 2025
3. For Dec 2025 deposits posted in 2026, use dates shown above

Key Fields Explained:
- DepositDate (PLDATE) = When the payment is "dated" for accounting
- PostDateTime (CREATEDATE) = When staff actually entered it in Dentrix
- CheckNum = Reference/check number
- PayType = EFTClaim (electronic) or CheckClaim (paper check)
- EFT = Binary flag (0x01 = electronic, 0x00 = check)

CLASS Values:
- 1 = Guarantor/Patient payment (cash, credit card, etc.)
- 3 = Insurance payment

AUTH_STATUS (for insurance payments):
- 0 = Check payment
- 1 = Electronic payment (EFT)
*/

-- ============================================================================
-- ALTERNATIVE: For specific date range like Brittany's sample
-- ============================================================================
/*
-- For December 2024 deposits posted in 2025-2026:
WHERE 
    pl.CHART_STATUS = 90
    AND pl.CLASS IN (1, 3)
    AND pl.PLDATE >= '2024-12-01'
    AND pl.PLDATE < '2025-01-01'
    AND pl.CREATEDATE >= '2025-01-01'
    AND pl.AMOUNT <> 0
*/
