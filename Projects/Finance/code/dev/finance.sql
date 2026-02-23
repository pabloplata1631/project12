
SELECT *
INTO #TempGrossProduction
FROM [MS].[dbo].[SNIP_001_Gross Production]
WHERE YEAR(reportruntime) = 2026;


--Select distinct ReportRunTime from #TempGrossProduction;

----Clinics 
With CBase as (
	Select 

			mclin.data_source_id			data_source_id
		,	mclin.clinic_id_source			clinic_id_source
		,	sclin.clinic_name				clinic_name_source
		,	mclin.clinic_id_reference		clinic_id_reference
		,	rclin.clinic_name_reference		clinic_name_reference
		,	rclin.date_of_dentrix			clinic_date_of_dentrix
 
 
	
	from smilist_data_warehouse.reference.clinics_map mclin
	Left join smilist_data_warehouse.standard.clinics
		sclin on 1=1
			and	sclin.clinic_id_source	= mclin.clinic_id_source
			and sclin.data_source_id	= mclin.data_source_id
		--order by clinic_name
	left join smilist_data_warehouse.reference.clinics 
	rclin on mclin.clinic_id_reference	= rclin.clinic_id_reference
) --
,names as (

Select Distinct clinic_name_reference from cbase
)
,

 Base as (

Select *,
CASE 
    WHEN DATEADD(MONTH, 1, DATEFROMPARTS(YEAR([CreateDate]), MONTH([CreateDate]), 1)) 
         = DATEFROMPARTS(YEAR([ReportRunTime]), MONTH([ReportRunTime]), 1)
    THEN 1
    ELSE 0
END AS IsNextMonth
from #TempGrossProduction
where ADA_Categ is not null 

)
 
SELECT 
    clinic_name_reference,
	--clinicName,
    'Dentist' AS BizLineDetail,  -- Force it to 'Dentist' instead of using b.BizLineDetail
    COALESCE(SUM([Prod$]), 0) AS TotalProd
FROM CBase a 
LEFT JOIN Base b
    ON a.clinic_name_source = b.ClinicName
    AND b.reportruntime = '2026-01-09 08:05:07.313' 
    AND b.BizLineDetail = 'Dentist' 
   AND b.IsNextMonth = 1
GROUP BY clinic_name_reference  -- Only group by clinic_name
ORDER BY clinic_name_reference 

