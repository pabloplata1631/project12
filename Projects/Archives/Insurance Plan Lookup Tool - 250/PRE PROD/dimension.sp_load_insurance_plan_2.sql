CREATE PROC [dimension].[sp_load_insurance_plan]
	@par_pipeline_id varchar(100),
	@par_log_id varchar(100)
AS
BEGIN

	----Check if the table exists
	IF object_id('dimension.insurance_plan') is null
	BEGIN
		CREATE TABLE dimension.insurance_plan (
				[Insurance_Plan_Key_Lakehouse]	[bigint]			NULL
			,	[Source_Key_Lakehouse]			[int]				NULL
			,	[Insurance_Plan_Key_Natural]	[varchar](100)		NULL
			,	[Insurance_Plan_Company_Name]	[varchar](200)		NULL
			,	[Insurance_Plan_Group_Name]		[varchar](100)		NULL
			,	[Insurance_Plan_Group_Number]	[varchar](100)		NULL
			,	[Insurance_Plan_Renewal_Month]	[varchar](50)		NULL
					,[Plan_Employer] 								[varchar](200) NULL
					,[Deductible_Standard_Individual_Lifetime] 		[decimal](14,6) NULL
					,[Deductible_Standard_Individual_Annual] 		[decimal](14,6) NULL
					,[Deductible_Standard_Family_Annual] 			[decimal](14,6) NULL
					,[Deductible_Preventative_Individual_Lifetime] 	[decimal](14,6) NULL
					,[Deductible_Preventative_Individual_Annual] 	[decimal](14,6) NULL
					,[Deductible_Preventative_Family_Annual] 		[decimal](14,6) NULL
					,[Deductible_Other_Individual_Lifetime] 		[decimal](14,6) NULL
					,[Deductible_Other_Individual_Annual] 			[decimal](14,6) NULL
					,[Deductible_Other_Family_Annual] 				[decimal](14,6) NULL
					,[Fee_Schedule_Key_Natural] 					[bigint] NULL
					,[Maximum_Benefit_Individual] 					[decimal](14,6) NULL
					,[Ortho_Plan] 									BIT NULL
			,	[Inserted_Date_Time]			[datetime2](5)		NULL
			,	[Updated_Date_Time]				[datetime2](5)		NULL
			,	Pipeline_Id						VARCHAR(100)		NULL
			,	Log_Id							VARCHAR(100)		NULL
			,	HashKey							VARBINARY(8000)
			,	Deleted_Flag_Hard				BIT					NULL
			,	Deleted_Flag_Soft				BIT					NULL
			)	
	END
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

	begin try
		/*******************************
		begin transaction
		*******************************/
		begin transaction

		/*******************************
		Setup identity column value
		*******************************/
		DECLARE @MaxID BIGINT = (SELECT COALESCE(MAX(Insurance_Plan_Key_Lakehouse),0) FROM dimension.insurance_plan);
	
		WITH
			/*******************************
			Setup actions
			*******************************/
			actions as (
			select 		
					try_convert(int				,	
						iif(	targets.Insurance_Plan_Key_Natural is null
							,	@MaxID+ROW_NUMBER() OVER(
								partition by
									iif(targets.Insurance_Plan_Key_Natural is null,1,0)
								order by 
									CONCAT_WS('|~|',sources.INSID,sources.INSDB,'1'))	
							,	targets.Insurance_Plan_Key_Lakehouse	))									Insurance_Plan_Key_Lakehouse			
				,	isnull(
							targets.Insurance_Plan_Key_Natural
						,	try_convert(VARCHAR(100),CONCAT_WS('|~|',sources.INSID,sources.INSDB,'1')))		Insurance_Plan_Key_Natural
				,	1																						Source_Key_Lakehouse
			
				,	try_convert(bit,iif(actives.INSID is null,1,0))											Deleted_Flag_Hard
				,	case 
						when 1=1
							and targets.Insurance_Plan_Key_Natural is not null
							and targets.Deleted_Flag_Hard = 0
							and actives.INSID is null
						then 'DELETE'
						when 1=1
							and targets.Insurance_Plan_Key_Natural is null
							and actives.INSID is not null
						then 'INSERT'
						when 1=1
							and targets.Insurance_Plan_Key_Natural is not null
							and actives.INSID is not null
						then 'UPDATE'
						else 'IGNORE'
						end																					Action_To_Take
			from		[Smilist_Gold_Lakehouse].[Dentrix_Smilist_sqldb].dbo_DDB_INSURANCE_BASE			sources
			full join	[Smilist_Gold_Warehouse].dimension.insurance_plan								targets
				on		CONCAT_WS('|~|',sources.INSID,sources.INSDB,'1') = targets.Insurance_Plan_Key_Natural 
				and		1 = targets.Source_Key_Lakehouse
			left join	[Smilist_Gold_Lakehouse].[Dentrix_Smilist_sqldb].dbo_DDB_INSURANCE_BASE_Active	actives
				on		sources.INSID = actives.INSID
				and		sources.INSDB = actives.INSDB
			)
			/*******************************
			Setup natural key data
			*******************************/
		,	natural_keys_data as (
			SELECT 
					actions.Insurance_Plan_Key_Lakehouse
				,	actions.Insurance_Plan_Key_Natural
				,	actions.Source_Key_Lakehouse
				,	try_convert([varchar](200)	,	[INSCONAME]											)	[Insurance_Plan_Company_Name]	
				,	try_convert([varchar](100)	,	[GROUPNAME]											)	[Insurance_Plan_Group_Name]		
				,	try_convert([varchar](100)	,	[GROUPNUM]											)	[Insurance_Plan_Group_Number]	
				,	try_convert([varchar](50)	,	[POLMONTH]											)	[Insurance_Plan_Renewal_Month]
			   -- Emp.Name            AS [plan_employer],
						,	try_convert([varchar](200), 	NULL												)	[Plan_Employer]
						,	try_convert([decimal](14,6) ,	[DEDPERPERSON] 										)	[Deductible_Standard_Individual_Lifetime]
						,	try_convert([decimal](14,6) ,	[DEDPERPERSONLT] 									)	[Deductible_Standard_Individual_Annual]
						,	try_convert([decimal](14,6) ,	[DEDPERFAMILY]  									)	[Deductible_Standard_Family_Annual]
						,	try_convert([decimal](14,6) ,	[DEDPERPERSON2] 									)	[Deductible_Preventative_Individual_Lifetime]
						,	try_convert([decimal](14,6) ,	[DEDPERPERSON2LT] 									)	[Deductible_Preventative_Individual_Annual]
						,	try_convert([decimal](14,6) ,	[DEDPERFAMILY2]  									)	[Deductible_Preventative_Family_Annual]
						,	try_convert([decimal](14,6) ,	[DEDPERPERSON3]  									)	[Deductible_Other_Individual_Lifetime]
						,	try_convert([decimal](14,6) ,	[DEDPERPERSON3LT]  									)	[Deductible_Other_Individual_Annual]
						,	try_convert([decimal](14,6) ,	[DEDPERFAMILY3]  									)	[Deductible_Other_Family_Annual]
						,	try_convert([bigint] ,			[FEESCHEDID]  										)	[Fee_Schedule_Key_Natural]
						,	try_convert([decimal](14,6) , 	[MAXCOVPERSON] 										)	[Maximum_Benefit_Individual]
						,	try_convert(BIT ,				[OrthoFlag]          								)	[Ortho_Plan]
				,	try_convert(bit				,	0													)	Deleted_Flag_Soft
				,	actions.Deleted_Flag_Hard
				,	actions.Action_To_Take
			FROM		actions																			actions
			left join	[Smilist_Gold_Lakehouse].[Dentrix_Smilist_sqldb].dbo_DDB_INSURANCE_BASE			sources
				on		actions.Insurance_Plan_Key_Natural = try_convert(VARCHAR(100),CONCAT_WS('|~|',sources.INSID,sources.INSDB,'1'))
				and		actions.Source_Key_Lakehouse = 1
			)
		/*******************************
		Setup hash
		*******************************/
		select 
				source_data.Insurance_Plan_Key_Lakehouse
			,	source_data.Source_Key_Lakehouse
			,	source_data.Insurance_Plan_Key_Natural
			,	source_data.Insurance_Plan_Company_Name
			,	source_data.Insurance_Plan_Group_Name
			,	source_data.Insurance_Plan_Group_Number
			,	source_data.Insurance_Plan_Renewal_Month
				,	source_data.Plan_Employer
				,	source_data.Deductible_Standard_Individual_Lifetime
				,	source_data.Deductible_Standard_Individual_Annual
				,	source_data.Deductible_Standard_Family_Annual
				,	source_data.Deductible_Preventative_Individual_Lifetime
				,	source_data.Deductible_Preventative_Individual_Annual
				,	source_data.Deductible_Preventative_Family_Annual
				,	source_data.Deductible_Other_Individual_Lifetime
				,	source_data.Deductible_Other_Individual_Annual
				,	source_data.Deductible_Other_Family_Annual
				,	source_data.Fee_Schedule_Key_Natural
				,	source_data.Maximum_Benefit_Individual
				,	source_data.Ortho_Plan
			,	source_data.Deleted_Flag_Hard				
			,	source_data.Deleted_Flag_Soft						
			,	source_data.Action_To_Take
			,	HASHBYTES('SHA2_256'																		
					,	concat_ws(																				
							'|'
						,	isnull(try_convert(varchar(200),source_data.Insurance_Plan_Company_Name					),'')
						,	isnull(try_convert(varchar(200),source_data.Insurance_Plan_Group_Name					),'')
						,	isnull(try_convert(varchar(200),source_data.Insurance_Plan_Group_Number					),'')
						,	isnull(try_convert(varchar(200),source_data.Insurance_Plan_Renewal_Month				),'')
							,	isnull(try_convert(varchar(200),source_data.Plan_Employer							),'')
							,	isnull(try_convert(varchar(200),source_data.Deductible_Standard_Individual_Lifetime	),'')
							,	isnull(try_convert(varchar(200),source_data.Deductible_Standard_Individual_Annual	),'')
							,	isnull(try_convert(varchar(200),source_data.Deductible_Standard_Family_Annual		),'')
							,	isnull(try_convert(varchar(200),source_data.Deductible_Preventative_Individual_Lifetime	),'')
							,	isnull(try_convert(varchar(200),source_data.Deductible_Preventative_Individual_Annual	),'')
							,	isnull(try_convert(varchar(200),source_data.Deductible_Preventative_Family_Annual	),'')
							,	isnull(try_convert(varchar(200),source_data.Deductible_Other_Individual_Lifetime	),'')
							,	isnull(try_convert(varchar(200),source_data.Deductible_Other_Individual_Annual		),'')
							,	isnull(try_convert(varchar(200),source_data.Deductible_Other_Family_Annual			),'')
							,	isnull(try_convert(varchar(200),source_data.Fee_Schedule_Key_Natural				),'')
							,	isnull(try_convert(varchar(200),source_data.Maximum_Benefit_Individual				),'')
							,	isnull(try_convert(varchar(200),source_data.Ortho_Plan								),'')
						,	isnull(try_convert(varchar(200),source_data.Deleted_Flag_Hard							),'')
						,	isnull(try_convert(varchar(200),source_data.Deleted_Flag_Soft							),'')

						))	HashKey
		into #source_data
		from natural_keys_data source_data

		/*******************************
		Insert
		*******************************/
		print('Records Inserted:');
		INSERT INTO	dimension.insurance_plan (	
				Insurance_Plan_Key_Lakehouse
			,	Source_Key_Lakehouse
			,	Insurance_Plan_Key_Natural
			,	Insurance_Plan_Company_Name
			,	Insurance_Plan_Group_Name
			,	Insurance_Plan_Group_Number
			,	Insurance_Plan_Renewal_Month
					,Plan_Employer	
					,Deductible_Standard_Individual_Lifetime	
					,Deductible_Standard_Individual_Annual	
					,Deductible_Standard_Family_Annual	
					,Deductible_Preventative_Individual_Lifetime	
					,Deductible_Preventative_Individual_Annual	
					,Deductible_Preventative_Family_Annual	
					,Deductible_Other_Individual_Lifetime	
					,Deductible_Other_Individual_Annual	
					,Deductible_Other_Family_Annual	
					,Fee_Schedule_Key_Natural	
					,Maximum_Benefit_Individual	
					,Ortho_Plan	
			,	Inserted_Date_Time
			,	Updated_Date_Time
			,	Pipeline_Id						
			,	Log_Id							
			,	HashKey							
			,	Deleted_Flag_Hard				
			,	Deleted_Flag_Soft				
			)
		SELECT  
				source_data.Insurance_Plan_Key_Lakehouse
			,	source_data.Source_Key_Lakehouse
			,	source_data.Insurance_Plan_Key_Natural
			,	source_data.Insurance_Plan_Company_Name
			,	source_data.Insurance_Plan_Group_Name
			,	source_data.Insurance_Plan_Group_Number
			,	source_data.Insurance_Plan_Renewal_Month
					,source_data.Plan_Employer	
					,source_data.Deductible_Standard_Individual_Lifetime	
					,source_data.Deductible_Standard_Individual_Annual	
					,source_data.Deductible_Standard_Family_Annual	
					,source_data.Deductible_Preventative_Individual_Lifetime	
					,source_data.Deductible_Preventative_Individual_Annual	
					,source_data.Deductible_Preventative_Family_Annual	
					,source_data.Deductible_Other_Individual_Lifetime	
					,source_data.Deductible_Other_Individual_Annual	
					,source_data.Deductible_Other_Family_Annual	
					,source_data.Fee_Schedule_Key_Natural	
					,source_data.Maximum_Benefit_Individual	
					,source_data.Ortho_Plan	
			,	getdate()						Inserted_Datetime						
			,	null							Updated_Date_Time						
			,	@par_pipeline_id				Pipeline_Id								
			,	@par_log_id						Log_Id				
			,	source_data.HashKey							
			,	source_data.Deleted_Flag_Hard				
			,	source_data.Deleted_Flag_Soft				
		from	#source_data	source_data
		where	source_data.Action_To_Take = 'INSERT';

		/*******************************
		UPDATES
		*******************************/
		print('Records Updated:');
		update	target_data
		set
				target_data.Insurance_Plan_Company_Name		=	source_data.Insurance_Plan_Company_Name
			,	target_data.Insurance_Plan_Group_Name		=	source_data.Insurance_Plan_Group_Name
			,	target_data.Insurance_Plan_Group_Number		=	source_data.Insurance_Plan_Group_Number
			,	target_data.Insurance_Plan_Renewal_Month	=	source_data.Insurance_Plan_Renewal_Month
				  	,target_data.Plan_Employer = source_data.Plan_Employer
					,target_data.Deductible_Standard_Individual_Lifetime = source_data.Deductible_Standard_Individual_Lifetime
					,target_data.Deductible_Standard_Individual_Annual = source_data.Deductible_Standard_Individual_Annual
					,target_data.Deductible_Standard_Family_Annual = source_data.Deductible_Standard_Family_Annual
					,target_data.Deductible_Preventative_Individual_Lifetime = source_data.Deductible_Preventative_Individual_Lifetime
					,target_data.Deductible_Preventative_Individual_Annual = source_data.Deductible_Preventative_Individual_Annual
					,target_data.Deductible_Preventative_Family_Annual = source_data.Deductible_Preventative_Family_Annual
					,target_data.Deductible_Other_Individual_Lifetime = source_data.Deductible_Other_Individual_Lifetime
					,target_data.Deductible_Other_Individual_Annual = source_data.Deductible_Other_Individual_Annual
					,target_data.Deductible_Other_Family_Annual = source_data.Deductible_Other_Family_Annual
					,target_data.Fee_Schedule_Key_Natural = source_data.Fee_Schedule_Key_Natural
					,target_data.Maximum_Benefit_Individual =  source_data.Maximum_Benefit_Individual
					,target_data.Ortho_Plan =  source_data.Ortho_Plan					
			,	target_data.Updated_Date_Time				=	getdate()
			,	target_data.Pipeline_Id						=	@par_pipeline_id
			,	target_data.Log_Id							=	@par_log_id
			,	target_data.HashKey							=	source_data.HashKey		
			,	target_data.Deleted_Flag_Hard				=	source_data.Deleted_Flag_Hard
			,	target_data.Deleted_Flag_Soft				=	source_data.Deleted_Flag_Soft				
		from	dimension.insurance_plan	target_data
		join	#source_data				source_data
			on	target_data.Insurance_Plan_Key_Lakehouse =	source_data.Insurance_Plan_Key_Lakehouse
			and source_data.Action_To_Take = 'UPDATE'
		where target_data.HashKey <> source_data.HashKey;
	
		/*******************************
		DELETES
		*******************************/
		print('Records Deleted:');
		update	target_data
		set				
				target_data.Updated_Date_Time						=	getdate()
			,	target_data.Pipeline_Id								=	@par_pipeline_id						
			,	target_data.Log_Id									=	@par_log_id			
			,	target_data.Deleted_Flag_Hard						=	1			
		from	dimension.insurance_plan	target_data
		join	#source_data				source_data
			on	target_data.Insurance_Plan_Key_Lakehouse =	source_data.Insurance_Plan_Key_Lakehouse
			and source_data.Action_To_Take = 'DELETE';
	
		commit;
	end try
	begin catch
		rollback;
		throw;
	end catch
END



