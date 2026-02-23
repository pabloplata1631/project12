/*DROP TABLE dbo.Report_ME_FINC_ProviderAR"
CREATE TABLE dbo.Report_ME_FINC_ProviderAR
(	ReportRunTime DATETIME NULL,
	ClinicName VARCHAR (50) NULL,
	ProvID VARCHAR (50) NULL,
	ProvName VARCHAR (100) NULL,
	ProvID_Name VARCHAR (500) NULL,
	BizType VARCHAR (10) NULL,
	BizLine VARCHAR (50) NULL,
	BizLine_Detail VARCHAR (50) NULL,
	Prod$ DECIMAL (18,2) NULL,         /* NO ADA-CAT RESTRICTION */
	Balance DECIMAL (18,2) NULL,
	[A/R_Bucket] VARCHAR (10) NULL,
	Expected_Collections DECIMAL (18,2) NULL)*/

INSERT INTO dbo.Report_ME_FINC_ProviderAR

SELECT
GETDATE()																						AS ReportRunTime,
ClinicName																						AS ClinicName,
ProvID																							AS ProvID,
ProvName																						AS ProvName,
ProvID_Name																						AS ProvID_Name,
BizType																							AS BizType,
BizLine																							AS BizLine,
BizLine_Detail																					AS BizLine_Detail,
SUM(Prod$)																						AS Prod$,
SUM(Balance)																					AS Balance,
[A/R_Bucket]																					AS [A/R_Bucket],
CASE
 WHEN [A/R_Bucket] = '0-30' AND BizType =  'General' THEN (SUM(Balance) * .98/*.9*/)
  WHEN [A/R_Bucket] = '31-60' AND BizType =  'General' THEN (SUM(Balance) * .95/*.7*/)
   WHEN [A/R_Bucket] = '61-90' AND BizType =  'General' THEN (SUM(Balance) * .90/*.3*/)
    WHEN [A/R_Bucket] = '91-120' AND BizType =  'General' THEN (SUM(Balance) * .85/*.25*/)
     WHEN [A/R_Bucket] = '121-150' AND BizType =  'General' THEN (SUM(Balance) * .70/*.15*/)
	  WHEN [A/R_Bucket] = '151-180' AND BizType =  'General' THEN (SUM(Balance) * .70/*.15*/)
       WHEN /*[A/R_Bucket] = '>181' AND*/ BizType =  'General' THEN (SUM(Balance) * .25/*.05*/)
 WHEN [A/R_Bucket] = '0-30' AND BizType =  'Ortho' THEN (SUM(Balance) * .95 /*.9*/)
  WHEN [A/R_Bucket] = '31-60' AND BizType =  'Ortho' THEN (SUM(Balance) * .95 /*.9*/)
   WHEN [A/R_Bucket] = '61-90' AND BizType =  'Ortho' THEN (SUM(Balance) * .95 /*.9*/)
    WHEN [A/R_Bucket] = '91-120' AND BizType =  'Ortho' THEN (SUM(Balance) * .95 /*.9*/)
     WHEN [A/R_Bucket] = '121-150' AND BizType =  'Ortho' THEN (SUM(Balance) * .95 /*.9*/)
	  WHEN [A/R_Bucket] = '151-180' AND BizType =  'Ortho' THEN  (SUM(Balance) * .95 /*.9*/)
       WHEN /*[A/R_Bucket] = '>181' AND*/ BizType =  'Ortho' THEN (SUM(Balance) * .90 /*.9*/)
ELSE 9999999999999999 END														AS ExpectedCollectios
	FROM	(SELECT
			ClinicName															AS ClinicName,
			ProvID_Name															AS ProvID_Name,
			SUBSTRING(ProvID_Name, 1, CHARINDEX('--', ProvID_Name)-1)			AS ProvID,
			SUBSTRING(ProvID_Name, CHARINDEX('--', ProvID_Name) + 2, 1000)		AS ProvName,
			[A/R_Bucket]														AS [A/R_Bucket],
			Prod$																AS Prod$,
			Balance																AS Balance,
			CASE
				WHEN BizLine = 'PERIO'		THEN 'General'
				WHEN BizLine = 'PROSTH'		THEN 'General'
				WHEN BizLine = 'ENDO'		THEN 'General'
				WHEN BizLine = 'DENTIST'	THEN 'General'
				WHEN BizLine = 'HYGIENIST'	THEN 'General'
				WHEN BizLine = 'ORTHO'		THEN 'Ortho'
				WHEN BizLine = 'GENPRACT'	THEN 'General'
				WHEN BizLine = 'ORALSURG'	THEN 'General'
				WHEN BizLine = 'PEDO'		THEN 'General'
				WHEN BizLine = 'ASSISTANT'	THEN 'General'
				WHEN BizLine = 'XRay'		THEN 'General'
			ELSE 'OTHER/NEW!'	 END											AS BizType,
			CASE
				WHEN BizLine = 'PERIO'		THEN 'Specialist'
				WHEN BizLine = 'PROSTH'	THEN 'Specialist'
				WHEN BizLine = 'ENDO'		THEN 'Specialist'
				WHEN BizLine = 'DENTIST'	THEN 'GP'
				WHEN BizLine = 'HYGIENIST'	THEN 'Hygiene'
				WHEN BizLine = 'ORTHO'		THEN 'Specialist'
				WHEN BizLine = 'GENPRACT'	THEN 'Office'
				WHEN BizLine = 'ORALSURG'	THEN 'Specialist'
				WHEN BizLine = 'PEDO'		THEN 'Specialist'
				WHEN BizLine = 'ASSISTANT'	THEN 'Assistant'
				WHEN BizLine = 'XRay'		THEN 'Specialist'
			ELSE 'OTHER/NEW!'	 END											AS BizLine,
			CASE
				WHEN BizLine = 'Perio'		THEN 'PERIO'
				WHEN BizLine = 'Prosth'	THEN 'PRO'
				WHEN BizLine = 'Endo'		THEN 'ENDO'
				WHEN BizLine = 'Dentist'	THEN 'GP'
				WHEN BizLine = 'Hygienist'	THEN 'HYG'
				WHEN BizLine = 'Ortho'		THEN 'ORTHO'
				WHEN BizLine = 'GenPract'	THEN 'OFF'
				WHEN BizLine = 'OralSurg'	THEN 'OS'
				WHEN BizLine = 'Pedo'		THEN 'PEDO'
				WHEN BizLine = 'Assistant'	THEN 'ASIST'
				WHEN BizLine = 'XRay'		THEN 'OS'
			ELSE 'OTHER/NEW!'	 END											AS BizLine_Detail
			FROM		(SELECT
						ClinicName																			AS ClinicName,	
						ProvID_Name																			AS ProvID_Name,	
						BizLine																				AS BizLine,
						DOS_ARbucket																		AS [A/R_Bucket],
						SUM(Prod$)																			AS Prod$,
						SUM(Prod$) + SUM(ADJ) + ISNULL(SUM(SpecialCR),0) + SUM(InsPay) + SUM(PatPay)		AS Balance
			
						FROM dbo.JF_4030_Liquidation_of_Gross_Production_OpenBalance
						--WHERE CREATEDATE < '01-01-2021' AND BizLine != 'XRay
						where ProvID_Name is not null
						GROUP BY ClinicName,ProvID_Name,BizLine,DOS_ARbucket
						) A
			GROUP BY ClinicName, BizLine, ProvID_Name, [A/R_Bucket], Prod$, Balance
			) A
GROUP BY ClinicName, ProvID, ProvName, ProvID_Name, BizType, BizLine, BizLine_Detail, [A/R_Bucket]
ORDER BY ProvID_Name





SELECT 
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length AS MaxLength,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity
FROM tempdb.sys.columns AS c
JOIN tempdb.sys.types AS t
    ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('tempdb..#temp');