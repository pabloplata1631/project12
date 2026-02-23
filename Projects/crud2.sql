------CHECK TOMORROW 
SELECT 


pl.*, 

clinic.*,
prov.*,
opr.*,
p.*,
g.*,
ar.*,
dt.*,
pc.*,

    -- ====================
    -- DATE DIMENSIONS
    -- ====================
    pl.PLDATE as AdjustmentDate,
    pl.CREATEDATE as EntryDate,
    YEAR(pl.PLDATE) as AdjustmentYear,
    MONTH(pl.PLDATE) as AdjustmentMonth,
    DATENAME(MONTH, pl.PLDATE) as AdjustmentMonthName,
    DATEPART(QUARTER, pl.PLDATE) as AdjustmentQuarter,
    DATEPART(WEEK, pl.PLDATE) as AdjustmentWeek,
    DATEPART(DAYOFYEAR, pl.PLDATE) as DayOfYear,
    DATENAME(WEEKDAY, pl.PLDATE) as DayOfWeek,
    
    -- ====================
    -- TRANSACTION INFO
    -- ====================
    pl.PROC_LOGID as TransactionID,
    pl.PROC_LOGDB as TransactionDB,
    pl.AMOUNT * 0.01 as AdjustmentAmount,
    
    -- ====================
    -- ADJUSTMENT CLASSIFICATION
    -- ====================
    pl.CLASS as AdjustmentClassCode,
    CASE pl.CLASS 
        WHEN 0 THEN 'Initial Balance'
        WHEN 2 THEN 'Credit/Debit Adjustment'
        WHEN 7 THEN 'Special Adjustment'
        WHEN 9 THEN 'Charge Adjustment'
        ELSE 'Unknown'
    END as AdjustmentClass,
    
    -- ====================
    -- ADJUSTMENT TYPE - From UI dropdown "Type"
    -- ====================
    pl.ORD as AdjustmentTypeCode,
    
    -- Enhanced lookup with fallbacks
    COALESCE(
        ar.DESCRIPTION,
        dt.DESCRIPTION,
        'Type Code ' + CAST(pl.ORD AS VARCHAR(10))
    ) as AdjustmentType,
    
    -- ====================
    -- UI FIELD
    -- ====================
    pl.OperatorID as EnteredByOperatorID,
    pl.OperatorDB as EnteredByOperatorDB,
    ISNULL(opr.NAME_LAST, '') as EnteredByLastName,
    ISNULL(opr.NAME_FIRST, '') as EnteredByFirstName,
    ISNULL(opr.NAME_LAST + ', ' + opr.NAME_FIRST, 'Unknown User') as EnteredByFullName,
    ISNULL(opr.UserLoginName, '') as EnteredByUsername,
    
    -- ====================
    -- UI FIELD
    -- ====================
    pl.ClinicAppliedTo as ClinicID,
    ISNULL(clinic.RSCID, 'Unknown Office') as OfficeName,
    ISNULL(clinic.RSCID, 'Unknown Office') as CollectingClinic,  -- Alias for UI field name
    
    -- ====================
    -- UI FIELD: Encounter # (top right area)
    -- ====================
    pl.EncounterNum as EncounterNumber,
    
    -- ====================
    -- UI FIELD: Date (shown as 01/28/2026)
    -- ====================
    -- Already have pl.PLDATE as AdjustmentDate above
    
    -- ====================
    -- UI FIELD: Amount ($32.40)
    -- ====================
    -- Already have pl.AMOUNT * 0.01 as AdjustmentAmount above
    
    -- ====================
    -- UI BOTTOM GRID FIELDS
    -- ====================
    
    -- Date (in grid)
    pl.PLDATE as GridDate,
    
    -- Encounter (in grid) 
    pl.EncounterNum as GridEncounter,
    
    -- Code (D0274 shown in grid)
    pl.PROC_CODEID as ProcedureCodeID,
    pl.PROC_CODEDB as ProcedureCodeDB,
    pc.ADACode as ProcedureCode,  -- This is the "D0274" type code
   -- pc.DESCRIP as ProcedureDescription,
    
    -- Th (Tooth)
    pl.TOOTH_RANGE_START as ToothStart,
    pl.TOOTH_RANGE_END as ToothEnd,
    CASE 
        WHEN pl.TOOTH_RANGE_START = pl.TOOTH_RANGE_END THEN CAST(pl.TOOTH_RANGE_START AS VARCHAR(10))
        WHEN pl.TOOTH_RANGE_START IS NOT NULL AND pl.TOOTH_RANGE_END IS NOT NULL 
            THEN CAST(pl.TOOTH_RANGE_START AS VARCHAR(10)) + '-' + CAST(pl.TOOTH_RANGE_END AS VARCHAR(10))
        ELSE ''
    END as ToothRange,
    
    -- Surface
    pl.SURF_STRING as Surface,
    
    -- Patient (Mary Jane D...)
    pl.PATID as PatientID,
    pl.PATDB as PatientDB,
    ISNULL(p.chart, '') as PatientChartID,
    ISNULL(p.lastname, '') as PatientLastName,
    ISNULL(p.firstname, '') as PatientFirstName,
    ISNULL(p.lastname + ', ' + p.firstname, 'Unknown Patient') as PatientFullName,
    -- Shortened version for grid display
    ISNULL(
        p.firstname + ' ' + LEFT(p.lastname, 1) + '...', 
        'Unknown'
    ) as PatientShortName,
    
    -- Provider (HYGMAN...)
    pl.PROVID as ProviderID,
   -- ISNULL(prov.lastname, '') as ProviderLastName,
    --ISNULL(prov.firstname, '') as ProviderFirstName,
    --ISNULL(prov.lastname + ', ' + prov.firstname, 'No Provider') as ProviderFullName,
    --ISNULL(prov.userid, '') as ProviderUserID,  -- This might be "HYGMAN" shown in grid
    
    -- Clinic (CATSKILL in grid)
    -- Already have OfficeName/CollectingClinic above
    
    -- Pay Plan (empty in screenshot)
    -- This would be payment plan information - not typically in PROC_LOG for adjustments
    NULL as PaymentPlanID,
    
    -- Charge (101.00 - the original charge before adjustment)
    -- This is tricky - adjustments don't have a separate "charge"
    -- Might need to look up the related procedure
    CASE 
        WHEN pl.CLASS IN (2, 7, 9) THEN NULL  -- Adjustments don't have original charge here
        ELSE pl.AMOUNT * 0.01
    END as OriginalCharge,
    
    -- Other (68.60 - might be insurance payment or other amount)
    -- Could be insurance paid amount
    (ISNULL(pl.AMTPINSPAID, 0) + ISNULL(pl.AMTSINSPAID, 0)) * 0.01 as OtherPayments,
    pl.AMTPINSPAID * 0.01 as PrimaryInsurancePaid,
    pl.AMTSINSPAID * 0.01 as SecondaryInsurancePaid,
    
    -- Guar (32.40 - Guarantor responsibility)
    -- This would be calculated, but showing adjustment amount for now
    pl.AMOUNT * 0.01 as GuarantorAmount,
    
    -- Applied (32.40 - Amount applied)
    pl.AMOUNT * 0.01 as AppliedAmount,
    
    -- Balance (0.00 - Remaining balance)
    -- This would require calculation across all transactions for patient
    -- For now, just showing if this specific transaction has balance
    0.00 as RemainingBalance,  -- Placeholder
    
    -- ====================
    -- UI FIELD: Note (bottom section with green highlight)
    -- ====================
    -- Notes are stored in a separate table in Dentrix
    -- We'll include available memo fields from PROC_LOG
    pl.CHECKNUM as Note_CheckNumber,  -- Sometimes used for notes
    pl.BANKNUMBER as Note_BankNumber,  -- Sometimes used for notes
    -- Actual notes are in DDB_PROC_NOTE_BASE - would need separate join
    
    -- ====================
    -- GUARANTOR
    -- ====================
    pl.GUARID as GuarantorID,
    pl.GUARDB as GuarantorDB,
    ISNULL(g.lastname, '') as GuarantorLastName,
    ISNULL(g.firstname, '') as GuarantorFirstName,
    ISNULL(g.lastname + ', ' + g.firstname, '') as GuarantorFullName,
    
    -- ====================
    -- FLAGS & CATEGORIES
    -- ====================
    pl.INSADJFLAG as IsInsuranceAdjustment,
    CASE WHEN pl.INSADJFLAG = 1 THEN 'Insurance Adjustment' 
         ELSE 'Patient Adjustment' END as AdjustmentCategory,
    
    pl.FAMILYFLAG as ApplyToFamily,
    CASE WHEN pl.FAMILYFLAG = 1 THEN 'Family' 
         ELSE 'Individual' END as FamilyFlag,
    
    pl.AUTOALLOCATE as AutoAllocate,
    pl.DBI_FLAG as DoNotBillInsurance,
    
    -- ====================
    -- CLAIM INFO
    -- ====================
    pl.CLAIMID as ClaimID,
    pl.CLAIMDB as ClaimDB,
    
    -- ====================
    -- AUDIT FIELDS
    -- ====================
    pl.DDB_LAST_MOD as LastModifiedDate,
    
    -- ====================
    -- CALCULATED FIELDS
    -- ====================
    ABS(pl.AMOUNT * 0.01) as AdjustmentAmountAbsolute,
    
    CASE 
        WHEN pl.AMOUNT > 0 THEN 'Credit'
        WHEN pl.AMOUNT < 0 THEN 'Debit'
        ELSE 'Zero'
    END as CreditDebitIndicator,
    
    FORMAT(pl.PLDATE, 'MMM yyyy') as MonthYear,
    CONCAT('Q', DATEPART(QUARTER, pl.PLDATE), ' ', YEAR(pl.PLDATE)) as QuarterYear,
    DATEDIFF(DAY, pl.PLDATE, GETDATE()) as AdjustmentAgeInDays,
    
    CASE 
        WHEN DATEDIFF(DAY, pl.PLDATE, GETDATE()) <= 30 THEN 'Current (Last 30 Days)'
        WHEN DATEDIFF(DAY, pl.PLDATE, GETDATE()) <= 90 THEN 'Recent (31-90 Days)'
        WHEN DATEDIFF(DAY, pl.PLDATE, GETDATE()) <= 365 THEN 'This Year'
        ELSE 'Historical'
    END as AdjustmentAgeCategory

FROM DDB_PROC_LOG_BASE pl

-- Join Clinic/Office
LEFT JOIN DDB_RSC_BASE clinic
    ON pl.ClinicAppliedTo = clinic.URSCID
    AND clinic.RSCTYPE = 0

-- Join Provider
LEFT JOIN DDB_RSC_BASE prov
    ON pl.PROVID = prov.URSCID
    AND pl.PROVDB = prov.RSCDB
    AND prov.RSCTYPE = 1

-- Join Operator/User
LEFT JOIN DDB_RSC_BASE opr
    ON pl.OperatorID = opr.URSCID
    AND pl.OperatorDB = opr.RSCDB
    AND opr.RSCTYPE IN (1, 2, 3, 4, 5)

-- Join Patient
INNER JOIN DDB_PAT_BASE p
    ON pl.PATID = p.PATID
    AND pl.PATDB = p.PATDB

-- Join Guarantor
LEFT JOIN DDB_PAT_BASE g
    ON pl.GUARID = g.PATID
    AND pl.GUARDB = g.PATDB

-- Join Adjustment Type - DDB_DEF_BASE
LEFT JOIN DDB_DEF_BASE ar
    ON pl.ORD = ar.UDEFID
    AND ar.TYPE = 9

-- Join Adjustment Type - DDB_DEF_TEXT (backup)
LEFT JOIN DDB_DEF_TEXT dt
    ON pl.ORD = dt.DEFID
    AND dt.TYPE = 9

-- Join Procedure Code (for the "Code" column in grid - D0274, etc.)
LEFT JOIN DDB_PROC_CODE_BASE pc
    ON pl.PROC_CODEID = pc.PROC_CODEID
    AND pl.PROC_CODEDB = pc.PROC_CODEDB

-- Optional: Join for actual notes if needed
-- LEFT JOIN DDB_PROC_NOTE_BASE notes
--     ON pl.PROC_LOGID = notes.PROC_LOGID
--     AND pl.PROC_LOGDB = notes.PROC_LOGDB

WHERE 
    pl.CHART_STATUS = 90
    AND pl.CLASS IN (0, 2, 7, 9)
    AND pl.PLDATE >= DATEADD(YEAR, -2, GETDATE())
	and opr.UserLoginName = 'MALVAREZ'
	and pl.PLDATE = '1/28/2026'



pl.*, 

clinic.*,
prov.*,
opr.*,
p.*,
g.*,
ar.*,
dt.*,
pc.*,

-- LEFT JOIN DDB_PROC_NOTE_BASE notes
--     ON pl.PROC_LOGID = notes.PROC_LOGID
--     AND pl.PROC_LOGDB = notes.PROC_LOGDB




282172
29927