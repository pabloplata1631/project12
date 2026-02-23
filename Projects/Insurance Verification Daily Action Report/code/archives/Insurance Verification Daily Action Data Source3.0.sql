
/*
    1/7/2026 - Pablo Plata -- updated as per Jenni 
    Notes 	
    (ad.secondary_insurance IS NULL OR ad.secondary_insurance = '')
    AND (
        ad.primary_insurance LIKE '%Self Pay%'
        OR ad.primary_insurance LIKE '%Brookbeam Discount Plan%'
        OR ad.primary_insurance LIKE '%EDP%'
		 OR ad.primary_insurance LIKE '%SBS Careington Discount%'
		  OR ad.primary_insurance LIKE '%Smylen%'
    )
)
*/

SELECT 
	a.* 
	,p.patient_id_warehouse
	,p.data_load_id
	,p.patient_first_name
	,p.patient_last_name
	,p.guarantor_id_source
	,p.chart_id_source
	,left(
    p.chart_id_source,
    CASE 
        WHEN charindex('|', p.chart_id_source) > 0 
        THEN charindex('|', p.chart_id_source) - 1
        ELSE LEN(p.chart_id_source)
    END
	) as chart_id
	,p.gender_id_source
	,p.employer_id_source
	,p.clinic_id_source_primary
	,p.insurance_coverage_id_source_primary
	,p.insurance_coverage_id_source_secondary
	,p.patient_phone_home
	,p.patient_phone_mobile
	,p.patient_email
	,p.patient_date_of_birth
	,p.row_hash
	,c.*
	,ad.primary_eligibility_checked_date
	,ad.primary_eligibility_start_date
	,ad.primary_eligibility_end_date
	,ad.primary_membership_id_source
	,ad.primary_membership_number
	,ad.primary_insurance
	,ad.primary_insurance_group_name
	,ad.primary_insurance_group_number
	,ad.primary_insurance_fee_schedule_id
	,ad.primary_insurance_fee_schedule
	,ad.primary_claim_format
	,ad.patient_id_source_subscriber_primary
	,ad.secondary_eligibility_checked_date
	,ad.secondary_eligibility_start_date
	,ad.secondary_eligibility_end_date
	,ad.secondary_membership_id_source
	,ad.secondary_membership_number
	,ad.secondary_insurance
	,ad.secondary_insurance_group_name
	,ad.secondary_insurance_group_number
	,ad.secondary_insurance_fee_schedule_id
	,ad.secondary_insurance_fee_schedule
	,ad.secondary_claim_format
	,ad.patient_id_source_subscriber_secondary
	--,ad.primary_insurance as primary_insurance_group_name
	,primary_sub.patient_first_name as primary_subscriber_first_name
	,primary_sub.patient_last_name as primary_subscriber_last_name
	,primary_sub.patient_date_of_birth as primary_subscriber_DOB
	,secondary_sub.patient_first_name as secondary_subscriber_first_name
	,secondary_sub.patient_last_name as secondary_subscriber_last_name
	,secondary_sub.patient_date_of_birth as secondary_subscriber_DOB
FROM (
	SELECT
		a.data_source_id,
		a.patient_id_source,
		a.appointment_date,
		a.appointment_id_source,
		cm.clinic_id_reference as clinic_id_reference1
	FROM standard.appointments a
	LEFT JOIN reference.clinics_map cm ON 1=1
		AND a.data_source_id = cm.data_source_id
		AND a.clinic_id_source = cm.clinic_id_source
	WHERE 1=1
		AND a.appointment_date >= CAST(GETDATE() AS DATE)
		AND a.appointment_date < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 2, 0)
) a
LEFT JOIN mart.appointment_detail AD
	ON a.appointment_id_source = ad.appointment_id_source 
LEFT JOIN standard.Patients p
	ON a.patient_id_source = p.patient_id_source
	AND a.data_source_id = p.data_source_id
LEFT JOIN reference.clinics c
	ON a.clinic_id_reference1 = c.clinic_id_reference
LEFT JOIN standard.Patients primary_sub
	ON ad.patient_id_source_subscriber_primary = primary_sub.patient_id_source
LEFT JOIN standard.Patients secondary_sub
	ON ad.patient_id_source_subscriber_secondary = secondary_sub.patient_id_source
WHERE 1=1
	-- Exclude records where eligibility was checked this month (regardless of naming convention)
	AND NOT (
		YEAR(ad.primary_eligibility_checked_date) = YEAR(GETDATE())
		AND MONTH(ad.primary_eligibility_checked_date) = MONTH(GETDATE())
	)
	-- Exclude Self Pay in primary with null/blank secondary
AND NOT (
    (ad.secondary_insurance IS NULL OR ad.secondary_insurance = '')
    AND (
        ad.primary_insurance LIKE '%Self Pay%'
        OR ad.primary_insurance LIKE '%Brookbeam Discount Plan%'
        OR ad.primary_insurance LIKE '%EDP%'
		 OR ad.primary_insurance LIKE '%SBS Careington Discount%'
		  OR ad.primary_insurance LIKE '%Smylen%'
    )
)