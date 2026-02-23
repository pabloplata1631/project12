Select 
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

FROM (
	SELECT
		--a.data_source_id,
		a.patient_id_source,
		a.appointment_date,
                FORMAT(CAST(a.appointment_start AS DATETIME), 'hh:mm tt') AS appointment_time,
		a.appointment_id_source,
		cm.clinic_id_reference as clinic_id_reference1
	FROM mart.appointment_times a
	LEFT JOIN reference.clinics_map cm ON 1=1
		--AND a.data_source_id = cm.data_source_id
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