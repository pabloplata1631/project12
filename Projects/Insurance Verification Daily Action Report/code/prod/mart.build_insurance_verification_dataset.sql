USE [smilist_data_warehouse]
GO
/****** Object:  StoredProcedure [mart].[build_insurance_verification_dataset]    Script Date: 1/27/2026 6:06:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [mart].[build_insurance_verification_dataset](
      @start_date  datetime = NULL
    , @end_date    datetime = NULL
    , @days_ahead  int      = 4          -- used only if @end_date is NULL
    , @exclude_plans bit    = 1          -- 1 = filter out excluded plan names
)
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------------------
    -- Default date window: today 00:00 -> today + @days_ahead
    -------------------------------------------------------------------------
    DECLARE @today      datetime = CONVERT(datetime, CONVERT(date, GETDATE()));
    DECLARE @month_start datetime = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);

    SET @start_date = COALESCE(@start_date, @today);
    SET @end_date   = COALESCE(@end_date,   DATEADD(day, @days_ahead, @today));

    -------------------------------------------------------------------------
    -- 1) Appointments in window
    -------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#appt') IS NOT NULL DROP TABLE #appt;
    SELECT
          a.apptid
        , a.apptdb
        , a.createdate
        , a.ddb_last_mod
        , a.apptdate
        , a.TIME_HOUR   AS appt_hour
        , a.TIME_MINUTE AS appt_min
        , a.status
        , a.patid
        , a.patdb
        , a.prprovid
        , a.prprovdb
        , c.urscid      AS clinic_urscid
        , c.rscdb       AS clinic_rscdb
        , d.description
    INTO #appt
    FROM dentrix.dbo.ddb_appt_base a
    LEFT JOIN dentrix.dbo.ddb_def_text d
        ON d.defid = a.status
       AND d.type  = 7
    LEFT JOIN dentrix.dbo.ddb_rsc_base s
        ON a.opid = s.urscid
       AND a.opdb = s.rscdb
    LEFT JOIN dentrix.dbo.ddb_rsc_base c
        ON s.defaultclinic = c.urscid
       AND c.rsctype = 0
       AND c.urscid > 0
    WHERE a.apptdate >= @start_date
      AND a.apptdate <  @end_date;

    CREATE CLUSTERED INDEX CX_appt_pat ON #appt(patid, patdb);
    CREATE NONCLUSTERED INDEX IX_appt_clinic ON #appt(clinic_urscid);

    -------------------------------------------------------------------------
    -- 2) Patients in range
    -------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#patients') IS NOT NULL DROP TABLE #patients;
    SELECT DISTINCT patid, patdb
    INTO #patients
    FROM #appt;

    CREATE CLUSTERED INDEX CX_patients ON #patients(patid, patdb);

    -------------------------------------------------------------------------
    -- 3) Kept patients = NOT EXISTS any eligibility check this month (any InsType)
    -------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#kept_patients') IS NOT NULL DROP TABLE #kept_patients;
    SELECT pir.patid, pir.patdb
    INTO #kept_patients
    FROM #patients pir
    WHERE NOT EXISTS (
        SELECT 1
        FROM dentrix.dbo.DDB_PAT_INSURED_base mpi
        WHERE mpi.patid = pir.patid
          AND mpi.patdb = pir.patdb
          AND mpi.LastCheckDateTime >= @month_start
    );

    CREATE CLUSTERED INDEX CX_kept ON #kept_patients(patid, patdb);

    -------------------------------------------------------------------------
    -- 4) Patient dimension (only kept patients)
    -------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#pat') IS NOT NULL DROP TABLE #pat;
    SELECT
          p.patid
        , p.patdb
        , TRY_CONVERT(varchar(20), p.firstname) AS patient_first_name
        , TRY_CONVERT(varchar(20), p.lastname)  AS patient_last_name
        , TRY_CONVERT(varchar(40), p.guarid) + '|' + TRY_CONVERT(varchar(40), p.guardb) AS guarantor_id_source
        , TRY_CONVERT(varchar(40), p.chart) AS chart_id

        -- raw keys for membership join
        , p.prinsuredid, p.prinsureddb
        , p.scinsuredid, p.scinsureddb

        -- “warehouse-style” string keys if you still want them
        , TRY_CONVERT(varchar(40), p.prinsuredid) + '|' + TRY_CONVERT(varchar(40), p.prinsureddb) AS insurance_coverage_id_source_primary
        , TRY_CONVERT(varchar(40), p.scinsuredid) + '|' + TRY_CONVERT(varchar(40), p.scinsureddb) AS insurance_coverage_id_source_secondary
    INTO #pat
    FROM dentrix.dbo.ddb_pat_base p
    INNER JOIN #kept_patients kp
        ON kp.patid = p.patid
       AND kp.patdb = p.patdb;

    CREATE CLUSTERED INDEX CX_pat ON #pat(patid, patdb);
    CREATE NONCLUSTERED INDEX IX_pat_primary ON #pat(prinsuredid, prinsureddb);
    CREATE NONCLUSTERED INDEX IX_pat_secondary ON #pat(scinsuredid, scinsureddb);

    -------------------------------------------------------------------------
    -- 5) Membership header rows (insured) restricted to only what our kept patients use
    -------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#membership') IS NOT NULL DROP TABLE #membership;
    SELECT
          ib.INSUREDID
        , ib.INSUREDDB
        , ib.INSID
        , ib.INSDB
        , ib.IDNUM   AS membership_number
        , ib.IDNUM2  AS membership_group_number
        , NULLIF(ib.LAST_VERIFIED,  '1753-03-02T00:00:00.000') AS last_verified_date
        , NULLIF(ib.EffectiveDate,  '1753-03-02T00:00:00.000') AS membership_start_date
        , NULLIF(ib.ExpirationDate, '1753-03-02T00:00:00.000') AS membership_end_date
    INTO #membership
    FROM dentrix.dbo.ddb_insured_base ib
    WHERE EXISTS (
        SELECT 1
        FROM #pat p
        WHERE (p.prinsuredid = ib.INSUREDID AND p.prinsureddb = ib.INSUREDDB)
           OR (p.scinsuredid = ib.INSUREDID AND p.scinsureddb = ib.INSUREDDB)
    );

    CREATE CLUSTERED INDEX CX_membership ON #membership(INSUREDID, INSUREDDB);
    CREATE NONCLUSTERED INDEX IX_membership_plan ON #membership(INSID, INSDB);

    -------------------------------------------------------------------------
    -- 6) Insurance plan info restricted to only plans referenced by memberships
    -------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#insurance_info') IS NOT NULL DROP TABLE #insurance_info;

    ;WITH fs AS (
        SELECT DISTINCT feeschid, feeschdb, feename
        FROM dentrix.dbo.DDB_FEESCHED_ITEM_BASE
        WHERE ISNULL(feename,'') <> ''
    )
    SELECT
          i.insid
        , i.insdb
        , i.insconame AS insurance_name
        , i.groupname AS insurance_group_name
        , i.groupnum  AS insurance_group_number
        , CONVERT(varchar(20), i.feeschedid) + '|' + CONVERT(varchar(20), i.feescheddb) AS fee_schedule_id_source
        , fs.feename  AS fee_schedule_name
        , UPPER(LEFT(cf.description, NULLIF(CHARINDEX(' ', cf.description), 0) - 1)) AS claim_format
    INTO #insurance_info
    FROM dentrix.dbo.ddb_insurance_base i
    LEFT JOIN dentrix.dbo.ddb_def_text cf
        ON cf.defid = i.claimformat
       AND cf.type  = 13
    LEFT JOIN fs
        ON fs.feeschid = i.feeschedid
    WHERE EXISTS (
        SELECT 1
        FROM #membership m
        WHERE m.INSID = i.insid
          AND m.INSDB = i.insdb
    );

    CREATE CLUSTERED INDEX CX_insinfo ON #insurance_info(insid, insdb);

    -------------------------------------------------------------------------
    -- 7) Eligibility rows: most recent per patient + InsType (Dental 0/1)
    -------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#elig') IS NOT NULL DROP TABLE #elig;

    SELECT
          x.patid
        , x.patdb
        , x.InsType
        , x.patient_eligibility_start_date
        , x.patient_eligibility_end_date
        , x.eligibility_last_checked_date
    INTO #elig
    FROM (
        SELECT
              mpi.patid
            , mpi.patdb
            , mpi.InsType
            , NULLIF(mpi.EligStartDate, '1753-03-02T00:00:00.000') AS patient_eligibility_start_date
            , NULLIF(mpi.EligEndDate,       '1753-03-02T00:00:00.000') AS patient_eligibility_end_date
            , NULLIF(mpi.LastCheckDateTime, '1753-03-02T00:00:00.000') AS eligibility_last_checked_date
            , ROW_NUMBER() OVER (
                  PARTITION BY mpi.patid, mpi.patdb, mpi.InsType
                  ORDER BY
                      CASE WHEN mpi.LastCheckDateTime IS NULL THEN 1 ELSE 0 END,
                      mpi.LastCheckDateTime DESC,
                      mpi.ddb_last_mod DESC
              ) AS rn
        FROM dentrix.dbo.DDB_PAT_INSURED_base mpi
        INNER JOIN #kept_patients kp
            ON kp.patid = mpi.patid
           AND kp.patdb = mpi.patdb
        WHERE mpi.InsType IN (0,1)
    ) x
    WHERE x.rn = 1;

    CREATE CLUSTERED INDEX CX_elig ON #elig(patid, patdb, InsType);

    -------------------------------------------------------------------------
    -- 8) Locations (your “allow list”)
    -------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#locations') IS NOT NULL DROP TABLE #locations;

    SELECT
        urscid,
        dci.RSCID AS clinic_name
    INTO #locations
    FROM Dentrix.dbo.DDB_CLINIC_INFO dci
    WHERE dci.RSCID IN (
      'ACADEMY','ALBANY','ALTAMONT','AMHERST','BALDWINSVI','BOONSBORO','BOSTON','BRIDGETON','BRINTONLAK',
      'BRKHEIGHTS','BUFFALO','CATSKILL','CENTRALSQ','CLIFTONPRK','COMMACK','DAYTON','DOYLESTOWN','EASTGREEN',
      'EDGEWATER','ELKINSPARK','ENGLISHTOW','GARDENCITY','GREENPOINT','HAMILTONSQ','HOBOKEN','HURLEYAVE',
      'HYDEPARK','JAMESPORT','LAKEWOOD','LANGHORNE','LAWRENCEVI','LOUDONVILL','MANAHAWKIN','MEDFORDNJ',
      'MEDFORD','MIDDLETOWN','MOORESTOWN','MOUNTAINSD','MSFISHKILL','NEWPALTZ','NORTHBABYL','OMSCLIFPRK',
      'PINEBUSH','PINEST','PORTWASH','POUGHKEEPS','RAHWAY','RANCOCAS','REDHOOK','SMITHTOWN','SMITHTO_OS',
      'SOLVAY','SOUDERTON1','SPLNFIELD','SPRINGFIEL','SYOSSET','VALLEYSTRM','WADINGRVR','WAPPNGRFLL',
      'WASHSQPARK','WELLESLEY','WESTSENEC','WHITESTONE','WOODLYN'
    );

    CREATE CLUSTERED INDEX CX_locations ON #locations(urscid);

    -------------------------------------------------------------------------
    -- Final output
    -------------------------------------------------------------------------
    SELECT
          locs.clinic_name AS clinic
        , a.apptdate       AS appointment_date
        , a.appt_hour
        , a.appt_min

        , CASE
              WHEN a.status = 100 THEN 'Broken'
              WHEN a.status = 101 THEN 'Wait'
              WHEN a.status = 150 THEN 'Complete'
              ELSE
                  CASE
                      WHEN a.description IS NULL THEN 'Unknown'
                      WHEN PATINDEX('%  %', a.description) = 0 THEN a.description
                      ELSE ISNULL(
                          STUFF(LEFT(a.description, PATINDEX('%  %', a.description) - 1), 1, 1, ''),
                          'Unknown'
                      )
                  END
          END AS appointment_status

        , p.patient_first_name
        , p.patient_last_name
        , p.chart_id

        -- Dental Primary (membership -> plan)
        , mp.membership_number       AS dental_primary_membership_number
        , mp.membership_group_number AS dental_primary_membership_group_number
        , mp.membership_start_date   AS dental_primary_membership_start_date
        , mp.membership_end_date     AS dental_primary_membership_end_date
        , ip.insurance_name          AS dental_primary_insurance_name
        , ip.insurance_group_name    AS dental_primary_insurance_group_name
        , ip.insurance_group_number  AS dental_primary_insurance_group_number
        , ip.fee_schedule_name       AS dental_primary_fee_schedule_name
        , ip.claim_format            AS dental_primary_claim_format

        -- Dental Primary eligibility
        , ep.patient_eligibility_start_date AS dental_primary_eligibility_start_date
        , ep.patient_eligibility_end_date   AS dental_primary_eligibility_end_date
        , ep.eligibility_last_checked_date  AS dental_primary_eligibility_last_checked_date

        -- Dental Secondary (membership -> plan)
        , ms.membership_number       AS dental_secondary_membership_number
        , ms.membership_group_number AS dental_secondary_membership_group_number
        , ms.membership_start_date   AS dental_secondary_membership_start_date
        , ms.membership_end_date     AS dental_secondary_membership_end_date
        , isec.insurance_name        AS dental_secondary_insurance_name
        , isec.insurance_group_name  AS dental_secondary_insurance_group_name
        , isec.insurance_group_number AS dental_secondary_insurance_group_number
        , isec.fee_schedule_name     AS dental_secondary_fee_schedule_name
        , isec.claim_format          AS dental_secondary_claim_format

        -- Dental Secondary eligibility
        , es.patient_eligibility_start_date AS dental_secondary_eligibility_start_date
        , es.patient_eligibility_end_date   AS dental_secondary_eligibility_end_date
        , es.eligibility_last_checked_date  AS dental_secondary_eligibility_last_checked_date

    FROM #appt a
    INNER JOIN #pat p
        ON p.patid = a.patid
       AND p.patdb = a.patdb
    INNER JOIN #locations locs
        ON a.clinic_urscid = locs.urscid

    -- primary membership -> plan
    LEFT JOIN #membership mp
        ON mp.INSUREDID = p.prinsuredid
       AND mp.INSUREDDB = p.prinsureddb
    LEFT JOIN #insurance_info ip
        ON ip.insid = mp.INSID
       AND ip.insdb = mp.INSDB

    -- primary eligibility
    LEFT JOIN #elig ep
        ON ep.patid = a.patid
       AND ep.patdb = a.patdb
       AND ep.InsType = 0

    -- secondary membership -> plan
    LEFT JOIN #membership ms
        ON ms.INSUREDID = p.scinsuredid
       AND ms.INSUREDDB = p.scinsureddb
    LEFT JOIN #insurance_info isec
        ON isec.insid = ms.INSID
       AND isec.insdb = ms.INSDB

    -- secondary eligibility
    LEFT JOIN #elig es
        ON es.patid = a.patid
       AND es.patdb = a.patdb
       AND es.InsType = 1

    WHERE
        (
            @exclude_plans = 0
            OR
            (
                -- keep NULLs, only exclude when we actually match a bad name
                ip.insurance_name IS NULL
                OR NOT (
                       UPPER(ip.insurance_name) LIKE '%SELF PAY%'
                    OR UPPER(ip.insurance_name) LIKE '%BROOKBEAM DISCOUNT PLAN%'
                    OR UPPER(ip.insurance_name) LIKE '%EDP%'
                    OR UPPER(ip.insurance_name) LIKE '%SBS CAREINGTON DISCOUNT%'
                    OR UPPER(ip.insurance_name) LIKE '%SMILIST%'
                    OR UPPER(ip.insurance_name) LIKE '%SMYLEN'
                    OR UPPER(ip.insurance_name) LIKE '%IDG%'
                    OR UPPER(ip.insurance_name) LIKE '%EMPLOYEE FAMILY PLAN%'
                    OR UPPER(ip.insurance_name) LIKE '%EMPLOYEE NAVIGATOR%'
                    OR UPPER(ip.insurance_name) LIKE '%EMPLOYEE PLAN%'
                    OR UPPER(ip.insurance_name) LIKE '%ENCORE EMPLOYEE%'
                    OR UPPER(ip.insurance_name) LIKE '%SMILIST EMPLOYEE%'
                    OR UPPER(ip.insurance_name) LIKE '%SMILIST EMPLOYEE FAMILY%'
                )
            )
        )
    ORDER BY a.apptdate, a.appt_hour, a.appt_min;

END;