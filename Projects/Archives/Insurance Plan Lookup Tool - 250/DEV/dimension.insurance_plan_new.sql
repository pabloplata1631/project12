-- Creating - dimension.insurance_plan_new table 
CREATE TABLE dimension.insurance_plan_new AS
SELECT 
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
    OrthoFlag           AS [ortho_plan]
FROM [Smilist_Gold_Lakehouse].[Dentrix_Smilist_sqldb].[dbo_DDB_INSURANCE_BASE] ins
/*
LEFT JOIN   [Smilist_Gold_Lakehouse].[Dentrix_Smilist_sqldb].[dbo_DDB_EMP_BASE] emp
    ON  ins.EMPID = emp.EMPID
    AND ins.EMPDB = emp.EMPDB
*/
;



-- INSERT 

SELECT TOP (1000) [Insurance_Plan_Key_Lakehouse]
      ,[Source_Key_Lakehouse]
      ,[Insurance_Plan_Natural_Key]
      ,[Insurance_Plan_Company_Name]
      ,[Insurance_Plan_Group_Name]
      ,[Insurance_Plan_Group_Number]
      ,[Insurance_Plan_Renewal_Month]
      ,[Inserted_Date_Time]
      ,[Updated_Date_Time]
      ,[Pipeline_Id]
      ,[Log_Id]
      ,[HashKey]
      ,[Deleted_Flag_Hard]
      ,[Deleted_Flag_Soft]
  FROM [dimension].[insurance_plan]

  ;


  -- Insert existing data from dimension.insurance_plan into dimension.insurance_plan_new
INSERT INTO dimension.insurance_plan_new (
    [Insurance_Plan_Key_Lakehouse],
    [Source_Key_Lakehouse],
    [Insurance_Plan_Natural_Key],
    [Insurance_Plan_Company_Name],
    [Insurance_Plan_Group_Name],
    [Insurance_Plan_Group_Number],
    [Insurance_Plan_Renewal_Month],
    ----------------------
    [group_plan_name],
    [plan_group_number],
    [carrier],
    [plan_employer],
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
    ----------------------
    [Inserted_Date_Time],
    [Updated_Date_Time],
    [Pipeline_Id],
    [Log_Id],
    [HashKey],
    [Deleted_Flag_Hard],
    [Deleted_Flag_Soft],
    -- New columns set to NULL
    
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
    NULL AS [plan_employer],
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

