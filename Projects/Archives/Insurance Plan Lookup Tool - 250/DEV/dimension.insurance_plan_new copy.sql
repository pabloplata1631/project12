
	CREATE TABLE dimension.insurance_plan_new
		(
		[Insurance_Plan_Key_Lakehouse] [bigint] NULL,
		[Source_Key_Lakehouse] [int] NULL,
		[Insurance_Plan_Natural_Key] [varchar](100) NULL,
		[Insurance_Plan_Company_Name] [varchar](200) NULL,
		[Insurance_Plan_Group_Name] [varchar](100) NULL,
		[Insurance_Plan_Group_Number] [varchar](100) NULL,
		[Insurance_Plan_Renewal_Month] [varchar](50) NULL,
        -- New columns set to NULL
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
        -- New columns set to NULL     
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

;


INSERT INTO dimension.insurance_plan_new (
    [Insurance_Plan_Key_Lakehouse],
    [Source_Key_Lakehouse],
    [Insurance_Plan_Natural_Key],
    [Insurance_Plan_Company_Name],
    [Insurance_Plan_Group_Name],
    [Insurance_Plan_Group_Number],
    [Insurance_Plan_Renewal_Month],
     -- New columns set to NULL
            [group_plan_name],
            [plan_group_number],
            [carrier],
            --[plan_employer],
            [deductible_standard_individual_lifetime],
            [deductible_standard_individual_annual],
            [deductible_standard_family_annual],
            [deductible_preventative_individual_lifetime],
            [deductible_preventative_individual_annual],
            [deductible_preventative_family_annual],
            [deductible_other_individual_lifetime],
            [deductible_other_individual_annual],
            [deductible_other_family_annual],
            [fee_schedule_id],
            [maximum_benefit_individual],
            [ortho_plan],
     -- New columns set to NULL
    [Inserted_Date_Time],
    [Updated_Date_Time],
    [Pipeline_Id],
    [Log_Id],
    [HashKey],
    [Deleted_Flag_Hard],
    [Deleted_Flag_Soft]
)
SELECT 
    [Insurance_Plan_Key_Lakehouse],
    [Source_Key_Lakehouse],
    [Insurance_Plan_Natural_Key],
    [Insurance_Plan_Company_Name],
    [Insurance_Plan_Group_Name],
    [Insurance_Plan_Group_Number],
    [Insurance_Plan_Renewal_Month],
    -- New columns set to NULL
            NULL AS [group_plan_name],
            NULL AS [plan_group_number],
            NULL AS [carrier],
            --NULL AS [plan_employer],
            NULL AS [deductible_standard_individual_lifetime],
            NULL AS [deductible_standard_individual_annual],
            NULL AS [deductible_standard_family_annual],
            NULL AS [deductible_preventative_individual_lifetime],
            NULL AS [deductible_preventative_individual_annual],
            NULL AS [deductible_preventative_family_annual],
            NULL AS [deductible_other_individual_lifetime],
            NULL AS [deductible_other_individual_annual],
            NULL AS [deductible_other_family_annual],
            NULL AS [fee_schedule_id],
            NULL AS [maximum_benefit_individual],
            NULL AS [ortho_plan],
     -- New columns set to NULL
    [Inserted_Date_Time],
    [Updated_Date_Time],
    [Pipeline_Id],
    [Log_Id],
    [HashKey],
    [Deleted_Flag_Hard],
    [Deleted_Flag_Soft]
FROM dimension.insurance_plan;



-- Rename the existing dimension.insurance_plan table to dimension.insurance_plan_old
EXEC sp_rename 'dimension.insurance_plan', 'insurance_plan_old';

EXEC sp_rename 'dimension.insurance_plan_new', 'insurance_plan';

