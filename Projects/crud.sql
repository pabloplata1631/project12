USE [smilist_data_warehouse]
GO

-- Drop the view if it exists
IF OBJECT_ID('mart.v_AppointmentTimeDataset', 'V') IS NOT NULL
    DROP VIEW mart.v_AppointmentTimeDataset;
GO

-- Create the view with CTEs
CREATE VIEW mart.v_AppointmentTimeDataset
AS
WITH appointments AS (
    -- Filter appointments early
    SELECT 
        a.apptid,
        a.apptdb,
        a.apptdate,
        a.TIME_HOUR,
        a.TIME_MINUTE,
        a.apptlen,
        a.status,
        a.patid,
        a.patdb,
        a.prprovid,
        a.prprovdb,
        a.opid,
        a.opdb
    FROM dentrix.dbo.ddb_appt_base a
    WHERE a.timeblock <> 0
        AND a.status NOT IN (100, 101, 150)
        AND a.apptdate >= CAST(GETDATE() AS DATE)
        AND a.apptdate < DATEADD(MONTH, 6, CAST(GETDATE() AS DATE))
),
descriptions AS (
    -- Status descriptions
    SELECT 
        d.defid,
        d.description
    FROM dentrix.dbo.ddb_def_text d
    WHERE d.type = 7
),
schedules AS (
    -- Schedules (operatories)
    SELECT 
        s.urscid,
        s.rscdb,
        s.defaultclinic
    FROM dentrix.dbo.ddb_rsc_base s
),
clinics AS (
    -- Clinics
    SELECT 
        c.urscid,
        c.rscdb
    FROM dentrix.dbo.ddb_rsc_base c
    WHERE c.rsctype = 0 
        AND c.urscid > 0
),
patients AS (
    -- Patients
    SELECT 
        p.PATID,
        p.PATDB,
        p.CHART
    FROM dentrix.dbo.DDB_PAT_BASE p
)
-- Final SELECT using the CTEs
SELECT DISTINCT
    1 AS data_source_id,
    
    CONVERT(VARCHAR(20), a.apptid) + '|' +
    CONVERT(VARCHAR(20), a.apptdb) AS appointment_id_source,
    
    TRY_CONVERT(VARCHAR(20), a.prprovid) + '|' +
    TRY_CONVERT(VARCHAR(20), a.prprovdb) AS provider_id_source,
    
    CONVERT(VARCHAR(20), c.urscid) + '|' +
    CONVERT(VARCHAR(20), c.rscdb) AS clinic_id_source,
    
    CONVERT(VARCHAR(20), a.patid) + '|' +
    CONVERT(VARCHAR(20), a.patdb) AS patient_id_source,
    
    TRY_CONVERT(DATE, a.apptdate) AS appointment_date,
    
    TRY_CONVERT(TIME,
        RIGHT('0' + CONVERT(VARCHAR, a.TIME_HOUR), 2) + ':' +
        RIGHT('0' + CONVERT(VARCHAR, a.TIME_MINUTE), 2)
    ) AS appointment_start,
    
    DATEADD(MINUTE,
        a.apptlen,
        TRY_CONVERT(TIME,
            RIGHT('0' + CONVERT(VARCHAR, a.TIME_HOUR), 2) + ':' +
            RIGHT('0' + CONVERT(VARCHAR, a.TIME_MINUTE), 2)
        )
    ) AS appointment_end,
    
    a.status,
    a.apptlen,
    p.CHART
FROM appointments a
LEFT JOIN descriptions d
    ON d.defid = a.status
LEFT JOIN schedules s
    ON a.opid = s.urscid 
    AND a.opdb = s.rscdb    
LEFT JOIN clinics c
    ON s.defaultclinic = c.urscid
LEFT JOIN patients p
    ON a.PATID = p.PATID
    AND a.PATDB = p.PATDB
GO