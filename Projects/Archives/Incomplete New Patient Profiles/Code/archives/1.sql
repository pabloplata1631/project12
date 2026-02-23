
--- SQL Query to retrieve upcoming appointments with patient and clinic details-
---Initial Code 

SELECT 
	a.* 
	,p.clinic_id_source
	,p.provider_first_name
	,p.provider_last_name
	,p.service_date
	,p.patient_id
	,p.patient_first_name
	,p.patient_last_name
	,p.patient_date_of_birth
	,p.patient_chart
	,c.*
	--/*
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
	/*
	,primary_sub.patient_first_name as primary_subscriber_first_name
	,primary_sub.patient_last_name as primary_subscriber_last_name
	,primary_sub.patient_date_of_birth as primary_subscriber_DOB
	,secondary_sub.patient_first_name as secondary_subscriber_first_name
	,secondary_sub.patient_last_name as secondary_subscriber_last_name
	,secondary_sub.patient_date_of_birth as secondary_subscriber_DOB
	*/
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
		AND a.appointment_date >= CAST(DATEADD(DAY, 0, GETDATE()) AS DATE)
		--AND a.appointment_date < DATEADD(DAY, 30, CAST(GETDATE() AS DATE))
) a
LEFT JOIN mart.appointment_detail AD
	ON a.appointment_id_source = ad.appointment_id_source 
LEFT JOIN mart.new_patients  p
	ON a.patient_id_source = p.patient_id
	--AND a.data_source_id = p.data_source_id
LEFT JOIN reference.clinics c
	ON a.clinic_id_reference1 = c.clinic_id_reference