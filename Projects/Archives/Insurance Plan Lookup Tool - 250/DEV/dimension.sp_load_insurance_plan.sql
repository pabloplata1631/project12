/****** Object:  StoredProcedure [dimension].[sp_load_insurance_plan]    Script Date: 7/23/2025 12:31:03 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dimension].[sp_load_insurance_plan]
	@par_pipeline_id varchar(100),
	@par_log_id varchar(100)
AS
BEGIN

----Check if the table exists
IF object_id('dimension.insurance_plan') is null
BEGIN
	CREATE TABLE dimension.insurance_plan
		(
		[Insurance_Plan_Key_Lakehouse] [bigint] NULL,
		[Source_Key_Lakehouse] [int] NULL,
		[Insurance_Plan_Natural_Key] [varchar](100) NULL,
		[Insurance_Plan_Company_Name] [varchar](200) NULL,
		[Insurance_Plan_Group_Name] [varchar](100) NULL,
		[Insurance_Plan_Group_Number] [varchar](100) NULL,
		[Insurance_Plan_Renewal_Month] [varchar](50) NULL,
			[group_plan_name] [varchar](200) NULL,
            [plan_group_number] [varchar](200) NULL,
            [carrier] [varchar](200) NULL,
                    -- Emp.Name            AS [plan_employer],
            [deductible_standard_individual_lifetime] [int] NULL,
            [deductible_standard_individual_annual] [int] NULL,
            [deductible_standard_family_annual] [int] NULL,
            [deductible_preventative_individual_lifetime] [int] NULL,
            [deductible_preventative_individual_annual] [int] NULL,
            [deductible_preventative_family_annual] [int] NULL,
            [deductible_other_individual_lifetime] [int] NULL,
            [deductible_other_individual_annual] [int] NULL,
            [deductible_other_family_annual] [int] NULL,
            [fee_schedule_id] [int] NULL,
            [maximum_benefit_individual] [int] NULL,
            [ortho_plan] [SMALLINT] NULL, 
		--[Insurance_Plan_Ortho_Flag] [smallint] NULL,
		--[Insurance_Plan_National_Plan_Id] [varchar](20) NULL,
		--[Insurance_Plan_Source_Of_Payment] [smallint] NULL,
		--[Insurance_Plan_Type_Indicator] [smallint] NULL,
		--[Insurance_Plan_AutoAdjustment_Method] [smallint] NULL,
		--[Insurance_Plan_Ajustment_Provider] [smallint] NULL,
		--[Insurance_Plan_Post_Method] [smallint] NULL,
		--[Insurance_Plan_Other_Code] [varchar](8000) NULL,
		[Inserted_Date_Time] [datetime2](5) NULL,
		[Updated_Date_Time] [datetime2](5) NULL,
		Pipeline_Id	VARCHAR(100) NULL,
		Log_Id	VARCHAR(100) NULL,
		HashKey VARBINARY(8000),
		Deleted_Flag_Hard BIT NULL,
		Deleted_Flag_Soft BIT NULL
		)	
 END

----Update deletion flag to 0
UPDATE dimension.insurance_plan
	set Deleted_Flag_Hard=0
	WHERE 1=1;

----Update existing records
UPDATE target
SET
	target.Source_Key_Lakehouse = source.Source_Key_Lakehouse,
	target.Insurance_Plan_Company_Name = source.Insurance_Plan_Company_Name,
	target.Insurance_Plan_Group_Name = source.Insurance_Plan_Group_Name,
	target.Insurance_Plan_Group_Number = source.Insurance_Plan_Group_Number,
	target.Insurance_Plan_Renewal_Month = source.Insurance_Plan_Renewal_Month
	  ,target.group_plan_name = source.group_plan_name
      ,target.plan_group_number = source.plan_group_number
      ,target.carrier = source.carrier
      ,target.deductible_standard_individual_lifetime = source.deductible_standard_individual_lifetime
      ,target.deductible_standard_individual_annual = source.deductible_standard_individual_annual
      ,target.deductible_standard_family_annual = source.deductible_standard_family_annual
      ,target.deductible_preventative_individual_lifetime = source.deductible_preventative_individual_lifetime
      ,target.deductible_preventative_individual_annual = source.deductible_preventative_individual_annual
      ,target.deductible_preventative_family_annual = source.deductible_preventative_family_annual
      ,target.deductible_other_individual_lifetime = source.deductible_other_individual_lifetime
      ,target.deductible_other_individual_annual = source.deductible_other_individual_annual
      ,target.deductible_other_family_annual = source.deductible_other_family_annual
      ,target.fee_schedule_id = source.fee_schedule_id
      ,target.maximum_benefit_individual =  source.maximum_benefit_individual
      ,target.ortho_plan =  source.ortho_plan
	--target.Insurance_Plan_Ortho_Flag = source.Insurance_Plan_Ortho_Flag,
	--target.Insurance_Plan_National_Plan_Id = source.Insurance_Plan_National_Plan_Id,
	--target.Plan_Source_Of_Payment = source.Plan_Source_Of_Payment,
	--target.Plan_Type_Indicator = source.Plan_Type_Indicator,
	--target.Plan_AutoAdjustment_Method = source.Plan_AutoAdjustment_Method,
	--target.Plan_Ajustment_Provider = source.Plan_Ajustment_Provider,
	--target.Plan_Post_Method = source.Plan_Post_Method,
	--target.Plan_Other_Code = source.Plan_Other_Code,
	,target.Updated_Date_Time = source.Updated_Date_Time,
	target.HashKey = source.HashKey
FROM dimension.insurance_plan target
INNER JOIN (
	SELECT *
		,HASHBYTES('SHA2_256',concat(isnull(T.Source_Key_Lakehouse,'')
				,isnull(T.Insurance_Plan_Company_Name,'')
				,isnull(T.Insurance_Plan_Group_Name,'')
				,isnull(T.Insurance_Plan_Group_Number,'')
				,isnull(T.Insurance_Plan_Renewal_Month,'')
				      ,group_plan_name
					  ,plan_group_number
					  ,carrier
					  ,deductible_standard_individual_lifetime
					  ,deductible_standard_individual_annual
					  ,deductible_standard_family_annual
					  ,deductible_preventative_individual_lifetime
					  ,deductible_preventative_individual_annual
					  ,deductible_preventative_family_annual
					  ,deductible_other_individual_lifetime
					  ,deductible_other_individual_annual
					  ,deductible_other_family_annual
					  ,fee_schedule_id
					  ,maximum_benefit_individual
					  ,ortho_plan
				--,isnull(T.Insurance_Plan_Ortho_Flag,'')
				--,isnull(T.Insurance_Plan_National_Plan_Id,'')
				--,isnull(T.Plan_Source_Of_Payment,'')
				--,isnull(T.Plan_Type_Indicator,'')
				--,isnull(T.Plan_AutoAdjustment_Method,'')
				--,isnull(T.Plan_Ajustment_Provider,'')
				--,isnull(T.Plan_Post_Method,'')
				--,isnull(T.Plan_Other_Code,'')
				)) as HashKey
	FROM 
	(
		SELECT DISTINCT 1 AS Source_Key_Lakehouse, -- need to derive this once it is added in source tables
			CONCAT([INSID], '|~|',[INSDB]) AS Insurance_Plan_Natural_Key,
			[INSCONAME] AS Insurance_Plan_Company_Name,
			[GROUPNAME] AS Insurance_Plan_Group_Name,			 
			[GROUPNUM] AS Insurance_Plan_Group_Number,
			[POLMONTH] AS Insurance_Plan_Renewal_Month,	
				GROUPNAME           AS [group_plan_name],
				GROUPNUM            AS [plan_group_number],
				INSCONAME           AS [carrier],
			   -- Emp.Name            AS [plan_employer],
				DEDPERPERSON        AS [deductible_standard_individual_lifetime],
				DEDPERPERSONLT      AS [deductible_standard_individual_annual],
				DEDPERFAMILY        AS [deductible_standard_family_annual],
				DEDPERPERSON2       AS [deductible_preventative_individual_lifetime],
				DEDPERPERSON2LT     AS [deductible_preventative_individual_annual],
				DEDPERFAMILY2       AS [deductible_preventative_family_annual],
				DEDPERPERSON3       AS [deductible_other_individual_lifetime],
				DEDPERPERSON3LT     AS [deductible_other_individual_annual],
				DEDPERFAMILY3       AS [deductible_other_family_annual],
				FEESCHEDID          AS [fee_schedule_id],
				MAXCOVPERSON        AS [maximum_benefit_individual],
				OrthoFlag           AS [ortho_plan],
			--[OrthoFlag] AS Insurance_Plan_Ortho_Flag,
			--[NationalPlanID] AS Insurance_Plan_National_Plan_Id,
			--[SOURCEOFPAYMENT] AS Plan_Source_Of_Payment,  --68=Medicaid, 70=Commercial Insurance, 71= BlueCross/Blue Shield, 72=CHAMPUS			 
			--[INSFLAG] Plan_Type_Indicator	,	  --0=Dental, 1=Medical	
			--[ADJ_METHOD] AS Plan_AutoAdjustment_Method,  --Auto adjustment method: 0=No Adjustment, 1=Write OffEstimated Insurance Portion Radio Button, 2=Fee Schedule Radio button
			--[ADJ_Prov_Method] AS Plan_Ajustment_Provider,  --Adjustment Provider radio buttons: 0=Rendering Provider,1=Default Provider
			--[ADJ_Post_Method] AS Plan_Post_Method,  --Under Fee Schedule radio button: 0=Post When Procedureis Posted, 1=Post When Claim is Paid
			--[OtherCode] AS Plan_Other_Code,  -- is this in details table?
			getdate() as Updated_Date_Time
		FROM [Smilist_Gold_Lakehouse].[Dentrix_Smilist_sqldb].[dbo_DDB_INSURANCE_BASE]
	)T	
) source
	ON target.Insurance_Plan_Natural_Key = source.Insurance_Plan_Natural_Key
where target.HashKey <> source.HashKey


DECLARE @MaxID AS BIGINT;
SET @MaxID = (SELECT COALESCE( MAX(Insurance_Plan_Key_Lakehouse),0) FROM dimension.insurance_plan);

---Create new records
INSERT INTO dimension.insurance_plan (Insurance_Plan_Key_Lakehouse,Source_Key_Lakehouse,Insurance_Plan_Natural_Key,Insurance_Plan_Company_Name,Insurance_Plan_Group_Name,
		Insurance_Plan_Group_Number,Insurance_Plan_Renewal_Month
					  ,group_plan_name
					  ,plan_group_number
					  ,carrier
					  ,deductible_standard_individual_lifetime
					  ,deductible_standard_individual_annual
					  ,deductible_standard_family_annual
					  ,deductible_preventative_individual_lifetime
					  ,deductible_preventative_individual_annual
					  ,deductible_preventative_family_annual
					  ,deductible_other_individual_lifetime
					  ,deductible_other_individual_annual
					  ,deductible_other_family_annual
					  ,fee_schedule_id
					  ,maximum_benefit_individual
					  ,ortho_plan
		--Insurance_Plan_Ortho_Flag,Insurance_Plan_National_Plan_Id,Plan_Source_Of_Payment,Plan_Type_Indicator,Plan_AutoAdjustment_Method,Plan_Ajustment_Provider,Plan_Post_Method,Plan_Other_Code
		,Inserted_Date_Time,Updated_Date_Time,Pipeline_Id,Log_Id,HashKey
		,Deleted_Flag_Hard
		,Deleted_Flag_Soft)
SELECT source.*
FROM dimension.insurance_plan target
RIGHT JOIN (
SELECT *
		,HASHBYTES('SHA2_256',concat(isnull(T.Source_Key_Lakehouse,'')
				,isnull(T.Insurance_Plan_Company_Name,'')
				,isnull(T.Insurance_Plan_Group_Name,'')
				,isnull(T.Insurance_Plan_Group_Number,'')
				,isnull(T.Insurance_Plan_Renewal_Month,'')
					  ,isnull(group_plan_name,'')
					  ,isnull(plan_group_number,'')
					  ,isnull(carrier,'')
					  ,isnull(deductible_standard_individual_lifetime,'')
					  ,isnull(deductible_standard_individual_annual,'')
					  ,isnull(deductible_standard_family_annual,'')
					  ,isnull(deductible_preventative_individual_lifetime,'')
					  ,isnull(deductible_preventative_individual_annual,'')
					  ,isnull(deductible_preventative_family_annual,'')
					  ,isnull(deductible_other_individual_lifetime,'')
					  ,isnull(deductible_other_individual_annual,'')
					  ,isnull(deductible_other_family_annual,'')
					  ,isnull(fee_schedule_id,'')
					  ,isnull(maximum_benefit_individual,'')
					  ,isnull(ortho_plan,'')
				--,isnull(T.Insurance_Plan_Ortho_Flag,'')
				--,isnull(T.Insurance_Plan_National_Plan_Id,'')
				--,isnull(T.Plan_Source_Of_Payment,'')
				--,isnull(T.Plan_Type_Indicator,'')
				--,isnull(T.Plan_AutoAdjustment_Method,'')
				--,isnull(T.Plan_Ajustment_Provider,'')
				--,isnull(T.Plan_Post_Method,'')
				--,isnull(T.Plan_Other_Code,'')
				)) as HashKey	
		, 0 AS Deleted_Flag_Hard
		, 0 AS Deleted_Flag_Soft
				
	FROM 
	(
		SELECT DISTINCT @MaxID + (row_number() over (order by CONCAT([INSID], '|~|',[INSDB]))) as Insurance_Plan_Key_Lakehouse,
			1 AS Source_Key_Lakehouse,
			CONCAT([INSID], '|~|',[INSDB]) AS Insurance_Plan_Natural_Key,
			[INSCONAME] AS Insurance_Plan_Company_Name,
			[GROUPNAME] AS Insurance_Plan_Group_Name,			 
			[GROUPNUM] AS Insurance_Plan_Group_Number,
			[POLMONTH] AS Insurance_Plan_Renewal_Month,
				GROUPNAME           AS [group_plan_name],
				GROUPNUM            AS [plan_group_number],
				INSCONAME           AS [carrier],
			   -- Emp.Name            AS [plan_employer],
				DEDPERPERSON        AS [deductible_standard_individual_lifetime],
				DEDPERPERSONLT      AS [deductible_standard_individual_annual],
				DEDPERFAMILY        AS [deductible_standard_family_annual],
				DEDPERPERSON2       AS [deductible_preventative_individual_lifetime],
				DEDPERPERSON2LT     AS [deductible_preventative_individual_annual],
				DEDPERFAMILY2       AS [deductible_preventative_family_annual],
				DEDPERPERSON3       AS [deductible_other_individual_lifetime],
				DEDPERPERSON3LT     AS [deductible_other_individual_annual],
				DEDPERFAMILY3       AS [deductible_other_family_annual],
				FEESCHEDID          AS [fee_schedule_id],
				MAXCOVPERSON        AS [maximum_benefit_individual],
				OrthoFlag           AS [ortho_plan],
			--[OrthoFlag] AS Insurance_Plan_Ortho_Flag,
			--[NationalPlanID] AS Insurance_Plan_National_Plan_Id,
			--[SOURCEOFPAYMENT] AS Plan_Source_Of_Payment,  --68=Medicaid, 70=Commercial Insurance, 71= BlueCross/Blue Shield, 72=CHAMPUS			 
			--[INSFLAG] Plan_Type_Indicator	,	  --0=Dental, 1=Medical	
			--[ADJ_METHOD] AS Plan_AutoAdjustment_Method,  --Auto adjustment method: 0=No Adjustment, 1=Write OffEstimated Insurance Portion Radio Button, 2=Fee Schedule Radio button
			--[ADJ_Prov_Method] AS Plan_Ajustment_Provider,  --Adjustment Provider radio buttons: 0=Rendering Provider,1=Default Provider
			--[ADJ_Post_Method] AS Plan_Post_Method,  --Under Fee Schedule radio button: 0=Post When Procedureis Posted, 1=Post When Claim is Paid
			--[OtherCode] AS Plan_Other_Code,  -- is this in details table?
			getdate() as Inserted_Date_Time,
			null as Updated_Date_Time,
			@par_pipeline_id as Pipeline_Id,
			@par_log_id as Log_Id
		FROM [Smilist_Gold_Lakehouse].[Dentrix_Smilist_sqldb].[dbo_DDB_INSURANCE_BASE]
	)T	
) source
	ON target.Insurance_Plan_Natural_Key = source.Insurance_Plan_Natural_Key
WHERE target.Insurance_Plan_Key_Lakehouse is null

----Mark Source deleted records
	
	update t
	set t.Deleted_Flag_Hard =1
	FROM dimension.insurance_plan t
	where exists 
	(
		SELECT 1
		FROM  [Smilist_Gold_Warehouse].[deleted].[dbo_DDB_INSURANCE_BASE_Delete] base
		WHERE t.Insurance_Plan_Natural_Key =  CONCAT([INSID], '|~|',[INSDB])
	)


END

GO


