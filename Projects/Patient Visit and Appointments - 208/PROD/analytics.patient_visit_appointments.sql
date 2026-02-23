/****** Object:  View [analytics].[patient_visit_appointments]    Script Date: 7/17/2025 11:48:45 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Auto Generated (Do not modify) D62F9F54AFA8B9E84ED79C7D96EA3218D5DCB0062D906169D1758AF7F986AB9D

-- ============================================================
-- ========== PATIENT VISIT + APPOINTMENTS WITH CTEs ==========
-- ========== Pablo ------=====================================
-- ============================================================
CREATE VIEW [analytics].[patient_visit_appointments] AS
WITH patient_visits AS (
       SELECT
        1 AS data_source_id,
        Person_Key_Lakehouse AS patient_id_source,
        Clinic_Key_Reference AS clinic_id_reference,
        Visit_Date,
        ROW_NUMBER() OVER (
            PARTITION BY Person_Key_Lakehouse
            ORDER BY Visit_Date
        ) AS patient_visit_rank
    FROM fact.person_visit
),
patient_appointments AS ( 
    SELECT
        1 AS data_source_id,
        Person_Key_Lakehouse AS patient_id_source,
        Clinic_Key_Reference AS clinic_id_reference,
        CAST(Appointment_Date_Time AS DATE) AS appointment_date,
        ROW_NUMBER() OVER (
            PARTITION BY Person_Key_Lakehouse
            ORDER BY CAST(Appointment_Date_Time AS DATE)
        ) AS patient_visit_rank
    FROM fact.appointment
    left join dimension.clinic on appointment.Clinic_Key_Lakehouse = clinic.Clinic_key_Lakehouse
    WHERE 1 = 1
),


combined_data AS (
    SELECT
        v.data_source_id,
        v.clinic_id_reference,
        v.patient_id_source,
        v.Visit_Date AS date,
        1 AS visit_flag,
        IIF(v.patient_visit_rank = 1, 1, 0) AS visit_flag_new,
        0 AS appointment_flag,
        0 AS appointment_flag_new
    FROM patient_visits v
    WHERE v.Visit_Date >= DATEADD(MONTH, -24, DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()))
    UNION ALL
    SELECT
        a.data_source_id,
        a.clinic_id_reference,
        a.patient_id_source,
        a.appointment_date AS date,
        0 AS visit_flag,
        0 AS visit_flag_new,
        1 AS appointment_flag,
        IIF(a.patient_visit_rank = 1, 1, 0) AS appointment_flag_new
    FROM patient_appointments a
    WHERE a.appointment_date >= DATEADD(MONTH, -24, DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()))
),
revenue_data AS ( 
    SELECT
        1 AS data_source_id,
        Person_Key AS patient_id_source,
        SUM(Amount) AS net_production
    FROM fact.view_accounts_receivable
    WHERE
        Transaction_Class = 'Debit'
        AND Transaction_Category = 'Production'
        AND Amount > 0
    GROUP BY Person_Key
),
dentist_day_data AS ( 
    SELECT
        Clinic_Key_Reference AS clinic_id_reference,
        Provider_Key_Reference AS provider_name,
        Service_Date
    FROM fact.provider_days
    WHERE
        ISNULL(Business_Line, '') = 'Dentist'
        AND Service_Date >= '2023-01-01'
),
patient_visit_appointments AS ( 
    SELECT
        cd.data_source_id,
        cd.clinic_id_reference,
        cd.patient_id_source,
        cd.date,
        MAX(cd.visit_flag) AS visit_flag,
        MAX(cd.visit_flag_new) AS new_visit_flag,
        MAX(cd.appointment_flag) AS appointment_flag,
        MAX(cd.appointment_flag_new) AS new_appointment_flag,
        CAST(r.net_production AS DECIMAL(14,2)) AS production,
        NULL AS dentist_days
    FROM combined_data cd
    LEFT JOIN revenue_data r
        ON cd.patient_id_source = r.patient_id_source
        AND cd.data_source_id = r.data_source_id
    GROUP BY
        cd.data_source_id,
        cd.clinic_id_reference,
        cd.patient_id_source,
        r.net_production,
        cd.date
),
provider_days_summary AS (
    SELECT
        1 AS data_source_id,
        clinic_id_reference,
        NULL AS patient_id_source,
        Service_Date AS date,
        NULL AS visit_flag,
        NULL AS new_visit_flag,
        NULL AS appointment_flag,
        NULL AS new_appointment_flag,
        NULL AS production,
        COUNT(provider_name) AS dentist_days
    FROM dentist_day_data
    GROUP BY clinic_id_reference, Service_Date
),
patient_visit_appointments_final AS (
    SELECT * FROM patient_visit_appointments
    UNION ALL
    SELECT * FROM provider_days_summary
)
SELECT * FROM patient_visit_appointments_final

GO
GO


