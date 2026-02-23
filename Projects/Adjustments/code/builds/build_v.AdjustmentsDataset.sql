--================================================================
--use to build the Adjustments Dataset View
--Pablo Plata
--2/3/2026
--================================================================

USE [smilist_data_warehouse]
GO

-- Drop the view if it exists
IF OBJECT_ID('mart.v_AdjustmentsDataset', 'V') IS NOT NULL
    DROP VIEW mart.v_AdjustmentsDataset;
GO

-- Create the view
CREATE VIEW mart.v_AdjustmentsDataset
AS

WITH 
-- ====================
-- CTE 1: Base Adjustments (2025 forward
-- ====================
BaseAdjustments AS (
    SELECT 
        PLDATE,
        CREATEDATE,
        PROC_LOGID,
        PROC_LOGDB,
        AMOUNT,
        CLASS,
        ORD,
        OperatorID,
        OperatorDB,
        ClinicAppliedTo,
        EncounterNum,
        PROC_CODEID,
        PROC_CODEDB,
        TOOTH_RANGE_START,
        TOOTH_RANGE_END,
        SURF_STRING,
        PATID,
        PATDB,
        PROVID,
        CHECKNUM,
        BANKNUMBER,
        GUARID,
        GUARDB,
        INSADJFLAG,
        FAMILYFLAG,
        AUTOALLOCATE,
        DBI_FLAG,
        CLAIMID,
        CLAIMDB,
        DDB_LAST_MOD,
        AMTPINSPAID,
        AMTSINSPAID
    FROM dentrix.dbo.DDB_PROC_LOG_BASE
    WHERE 
        CHART_STATUS = 90
        AND CLASS IN (0, 2, 7, 9)
        AND PLDATE >= DATEADD(YEAR, -1, GETDATE())
		AND PLDATE <= DATEADD(YEAR, 1, GETDATE())
),

-- ====================
-- CTE 2: Clinic Data
-- ====================
ClinicData AS (
    SELECT DISTINCT
        URSCID,
        RSCID
    FROM dentrix.dbo.DDB_RSC_BASE
    WHERE RSCTYPE = 0
),

-- ====================
-- CTE 3: Provider Data
-- ====================
ProviderData AS (
    SELECT DISTINCT
        URSCID,
        RSCDB
    FROM dentrix.dbo.DDB_RSC_BASE
    WHERE RSCTYPE = 1
),

-- ====================
-- CTE 4: Operator Data
-- ====================
OperatorData AS (
    SELECT DISTINCT
        URSCID,
        RSCDB,
        NAME_LAST,
        NAME_FIRST,
        UserLoginName
    FROM dentrix.dbo.DDB_RSC_BASE
    WHERE RSCTYPE IN (1, 2, 3, 4, 5)
),

-- ====================
-- CTE 5: Patient Data
-- ====================
PatientData AS (
    SELECT 
        PATID,
        PATDB,
        chart,
        lastname,
        firstname
    FROM dentrix.dbo.DDB_PAT_BASE
    WHERE EXISTS (
        SELECT 1 
        FROM BaseAdjustments ba 
        WHERE ba.PATID = DDB_PAT_BASE.PATID 
        AND ba.PATDB = DDB_PAT_BASE.PATDB
    )
),

-- ====================
-- CTE 6: Guarantor Data
-- ====================
GuarantorData AS (
    SELECT 
        PATID,
        PATDB,
        lastname,
        firstname
    FROM dentrix.dbo.DDB_PAT_BASE
    WHERE EXISTS (
        SELECT 1 
        FROM BaseAdjustments ba 
        WHERE ba.GUARID = DDB_PAT_BASE.PATID 
        AND ba.GUARDB = DDB_PAT_BASE.PATDB
    )
),

-- ====================
-- CTE 7: Adjustment Type Definitions
-- ====================
AdjustmentTypeDef AS (
    SELECT 
        UDEFID,
        DESCRIPTION
    FROM dentrix.dbo.DDB_DEF_BASE
    WHERE TYPE = 9
),

-- ====================
-- CTE 8: Adjustment Type Text (backup)
-- ====================
AdjustmentTypeText AS (
    SELECT 
        DEFID,
        DESCRIPTION
    FROM dentrix.dbo.DDB_DEF_TEXT
    WHERE TYPE = 9
),

-- ====================
-- CTE 9: Procedure Codes
-- ====================
ProcedureCodes AS (
    SELECT 
        PROC_CODEID,
        PROC_CODEDB,
        ADACode
    FROM dentrix.dbo.DDB_PROC_CODE_BASE
    WHERE EXISTS (
        SELECT 1 
        FROM BaseAdjustments ba 
        WHERE ba.PROC_CODEID = DDB_PROC_CODE_BASE.PROC_CODEID 
        AND ba.PROC_CODEDB = DDB_PROC_CODE_BASE.PROC_CODEDB
    )
)

-- ================================================================================================================================================================
-- MAIN SELECT
-- ================================================================================================================================================================
SELECT 
	 -- ====================
    -- DATE DIMENSIONS
    -- ====================
    pl.PLDATE as AdjustmentDate,
    pl.CREATEDATE as EntryDate,
	/*
	  YEAR(pl.PLDATE) as AdjustmentYear,
    MONTH(pl.PLDATE) as AdjustmentMonth,
    DATENAME(MONTH, pl.PLDATE) as AdjustmentMonthName,
    DATEPART(QUARTER, pl.PLDATE) as AdjustmentQuarter,
    DATEPART(WEEK, pl.PLDATE) as AdjustmentWeek,
    DATEPART(DAYOFYEAR, pl.PLDATE) as DayOfYear,
    DATENAME(WEEKDAY, pl.PLDATE) as DayOfWeek,
    */
    -- ====================
    -- TRANSACTION INFO
    -- ====================
    pl.PROC_LOGID as TransactionID,
    pl.PROC_LOGDB as TransactionDB,
	-- Composite unique key for counting
	CAST(pl.PROC_LOGID AS VARCHAR(20)) + '|' + CAST(pl.PROC_LOGDB AS VARCHAR(20)) as UniqueAdjustmentID, --- Use for counts
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
    -- ADJUSTMENT TYPE
    -- ====================
    pl.ORD as AdjustmentTypeCode,
    COALESCE(
        ar.DESCRIPTION,
        dt.DESCRIPTION,
        'Type Code ' + CAST(pl.ORD AS VARCHAR(10))
    ) as AdjustmentType,
    
    -- ====================
    -- OPERATOR/USER INFO
    -- ====================
    pl.OperatorID as EnteredByOperatorID,
    pl.OperatorDB as EnteredByOperatorDB,
    ISNULL(opr.NAME_LAST, '') as EnteredByLastName,
    ISNULL(opr.NAME_FIRST, '') as EnteredByFirstName,
    ISNULL(opr.NAME_LAST + ', ' + opr.NAME_FIRST, 'Unknown User') as EnteredByFullName,
    ISNULL(opr.UserLoginName, '') as EnteredByUsername,
    
    -- ====================
    -- CLINIC INFO
    -- ====================
    pl.ClinicAppliedTo as ClinicID,
    ISNULL(clinic.RSCID, 'Unknown Office') as OfficeName,
    ISNULL(clinic.RSCID, 'Unknown Office') as CollectingClinic,
    
    -- ====================
    -- ENCOUNTER INFO
    -- ====================
    pl.EncounterNum as EncounterNumber,
    
    -- ====================
    -- GRID FIELDS From Micele Snapshot 
    -- ====================
    pl.PLDATE as GridDate,
    pl.EncounterNum as GridEncounter,
    
    -- Procedure Code Info --- To check with Michele
    pl.PROC_CODEID as ProcedureCodeID,
    pl.PROC_CODEDB as ProcedureCodeDB,
    pc.ADACode as ProcedureCode,
    
    -- Tooth Info
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
    
    -- ====================
    -- PATIENT INFO
    -- ====================
    pl.PATID as PatientID,
    pl.PATDB as PatientDB,
    ISNULL(p.chart, '') as PatientChartID,
    ISNULL(p.lastname, '') as PatientLastName,
    ISNULL(p.firstname, '') as PatientFirstName,
    ISNULL(p.lastname + ', ' + p.firstname, 'Unknown Patient') as PatientFullName,
    ISNULL(
        p.firstname + ' ' + LEFT(p.lastname, 1) + '...', 
        'Unknown'
    ) as PatientShortName,
    
    -- ====================
    -- PROVIDER INFO
    -- ====================
    pl.PROVID as ProviderID,
    
    -- ====================
    -- PAYMENT INFO
    -- ====================
    NULL as PaymentPlanID,
    
    CASE 
        WHEN pl.CLASS IN (2, 7, 9) THEN NULL
        ELSE pl.AMOUNT * 0.01
    END as OriginalCharge,
    
    (ISNULL(pl.AMTPINSPAID, 0) + ISNULL(pl.AMTSINSPAID, 0)) * 0.01 as OtherPayments,
    pl.AMTPINSPAID * 0.01 as PrimaryInsurancePaid,
    pl.AMTSINSPAID * 0.01 as SecondaryInsurancePaid,
    
    pl.AMOUNT * 0.01 as GuarantorAmount,
    pl.AMOUNT * 0.01 as AppliedAmount,
    0.00 as RemainingBalance,
    
    -- ====================
    -- NOTES
    -- ====================
    --pl.CHECKNUM as Note_CheckNumber,
   -- pl.BANKNUMBER as Note_BankNumber,
    
    -- ====================
    -- GUARANTOR INFO
    -- ====================
    pl.GUARID as GuarantorID,
    pl.GUARDB as GuarantorDB,
    ISNULL(g.lastname, '') as GuarantorLastName,
    ISNULL(g.firstname, '') as GuarantorFirstName,
    ISNULL(g.lastname + ', ' + g.firstname, '') as GuarantorFullName,
    
    -- ====================
    -- FLAGS & CATEGORIES
    
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
    -- CALCULATED FIELDS ---Exta stuff 
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

FROM BaseAdjustments pl

-- Join CTEs instead of base tables
LEFT JOIN ClinicData clinic
    ON pl.ClinicAppliedTo = clinic.URSCID

LEFT JOIN OperatorData opr
    ON pl.OperatorID = opr.URSCID
    AND pl.OperatorDB = opr.RSCDB

INNER JOIN PatientData p
    ON pl.PATID = p.PATID
    AND pl.PATDB = p.PATDB

LEFT JOIN GuarantorData g
    ON pl.GUARID = g.PATID
    AND pl.GUARDB = g.PATDB

LEFT JOIN AdjustmentTypeDef ar
    ON pl.ORD = ar.UDEFID

LEFT JOIN AdjustmentTypeText dt
    ON pl.ORD = dt.DEFID

LEFT JOIN ProcedureCodes pc
    ON pl.PROC_CODEID = pc.PROC_CODEID
    AND pl.PROC_CODEDB = pc.PROC_CODEDB

GO