Use NDSRenovation
Go
If Exists(Select 1 from Sys.Procedures where Name='Proc_App')
Begin
	Drop Procedure Proc_App
End
Go
Create Procedure Proc_App
	@P_Condition		Varchar(50),
	@P_SNo				Integer      	= NULL,
	@P_SystemName		varchar(100)	= NULL,
	@P_SystemIP			varchar(100)	= NULL,
	@P_LongStr			varchar(Max)	= NULL,
	@P_CreatedBy		varchar(50)		= NULL,
	@P_ExeDate		    varchar(50)		= NULL,
	@P_ProcMessage		Varchar(Max)	= NULL OutPut,
	@P_ProcReturn		Integer 		= NULL OutPut
AS
Begin Transaction
Declare @RetryCounter INT
Set @RetryCounter = 1
Retry:
Begin Transaction
Begin Try
	Set NoCount On
	Set @P_ProcMessage='Operation Failed.'
	Set @P_ProcReturn=0

	Declare
	@IsSupportUser bit=0,	@KeyValue as varchar(Max)=''

	--Exec Proc_App @P_Condition='DeleteAppUpdateDetails' ,@P_SNo=3
	if @P_Condition='DeleteAppUpdateDetails'
	Begin
		Delete from Tbl_AppUpdateDetails where SNo = @P_SNo
		Set @P_ProcMessage=Cast(@@RowCount as varchar)+' Record(s) deleted.'
		Set @P_ProcReturn=1
	End
	--Exec Proc_App @P_Condition='CheckPhotoExistence'
	if @P_Condition='GetallSetting'
	Begin
		Select * from [dbo].[Tbl_Setting]
	End   

	--Exec Proc_App @P_Condition='GetUpdatesInoForSystem',@P_LongStr='DMSVFS',@P_SystemName='NLP164'
	If @P_Condition='GetUpdatesInoForSystem'
	Begin
		Declare @CurrentID int=0

		select top 1 @CurrentID = ISNULL(updateID,0) FROM Tbl_AppUpdateSystemDetails where [SystemName] = @P_SystemName order by Createdon desc

		Select top 1  U.SNo,U.Title,U.Description,U.Location,U.CreatedOn,U.EffectiveFrom
		from Tbl_AppUpdateDetails U
		left join Tbl_AppUpdateSystemDetails S
		on U.SNo=S.UpdateID and @P_SystemName=S.SystemName
		where S.UpdateID is null and U.IsActive=1 --and  (U.EffectiveFrom<=GetDate() and U.CreatedOn>GetDate()-3 OR U.SNo > @CurrentID)
		 and U.Project=@P_LongStr order by U.ModifiedOn
		

	End	

	--Exec Proc_App @P_Condition='GetUpdatesAvailableForSystem',@P_LongStr='DMS_VFS',@P_SystemName='NLP164'
	If @P_Condition='GetUpdatesAvailableForSystem'
	Begin
		Declare @CurrentUpdateID int=0

		select top 1 @CurrentUpdateID = ISNULL(updateID,0) FROM Tbl_AppUpdateSystemDetails where [SystemName] = @P_SystemName order by Createdon desc

		Select Count(U.SNo) as 'UpdatesAvailable'
		from Tbl_AppUpdateDetails U
		left join Tbl_AppUpdateSystemDetails S
		on U.SNo=S.UpdateID and @P_SystemName=S.SystemName
		where S.UpdateID is null and U.IsActive=1 and  (U.EffectiveFrom<=GetDate() and U.CreatedOn>GetDate()-3 OR U.SNo > @CurrentUpdateID)
		 and U.Project=@P_LongStr --and ISNULL(IsForUAT,0)= CASE WHEN @IsSupportUser = 1 THEN ISNULL(IsForUAT,0) ELSE 0 END
		

	End	

	--Exec Proc_App @P_Condition='CheckPhotoExistence'
	if @P_Condition='CheckPhotoExistence'
	Begin
		if Exists(Select 1 from Tbl_Setting where Key1='Result' and Key2='MarkSheet' and Key3='IsPhotoRequired' and KeyValue='1')
		Begin
			Set @KeyValue=''
			Select @KeyValue=KeyValue 
			from Tbl_Setting(NoLock)
			where Key1='Result' and Key2='MarkSheet' and Key3='PhPath'

			Update Vw_StudentMaster
			Set IsPhotoExists=Dbo.Fn_CheckFileExists(@KeyValue+PhPath)

			If @@RowCount > 0
			Begin
				Set @P_ProcMessage=Cast(@@RowCount as varchar)+' Record(s) affected.'
				Set @P_ProcReturn=1
			End
		End
	End

	--Exec Proc_App @P_Condition='IsAppUpgradeEXEAvailable'
	if @P_Condition='IsAppUpgradeEXEAvailable'	--Added by Arun v on 12/01/2019
	Begin
		Select Key1,Key2,Key3,KeyValue 
		from Tbl_Setting 
		where Key1='App' and Key2='AppUpgradeEXE' and Key3='IsAvailable'
	End

	--Exec Proc_App @P_Condition='GetSystemUpdatesInfo', @P_SystemName='NLP154'
	If @P_Condition='GetSystemUpdatesInfo'
	Begin
		If Object_ID('TempDB.Dbo.#TTAppUpdate','U') is not null
			Drop Table #TTAppUpdate

		Create Table #TTAppUpdate
		(
			SNo int identity(1,1) primary key,
			Updates varchar(Max)
		)

		Insert into #TTAppUpdate(Updates)
		Select 'Recent Update'

		Insert into #TTAppUpdate(Updates)
		Select Top(1) UpdateID 
		from Tbl_AppUpdateSystemDetails
		where SystemName=@P_SystemName
		order by UpdatedDate Desc

		Update TT
		Set TT.Updates=Space(8)+A.Title
		from #TTAppUpdate TT
		inner join Tbl_AppUpdateDetails A
		on TT.Updates=A.SNo and TT.SNo=2

		Insert into #TTAppUpdate(Updates)
		Select 'Upcoming Updates'

		Insert into #TTAppUpdate(Updates)
		Select Space(8)+U.Title
		from Tbl_AppUpdateDetails U
		left join Tbl_AppUpdateSystemDetails S
		on U.SNo=S.UpdateID and @P_SystemName=S.SystemName
		where S.UpdateID is null and U.IsActive=1 and ISNULL(@P_SystemName,'')<>''
		order by U.ModifiedOn

		Select Updates
		from #TTAppUpdate
		order by SNo
	End

	--Exec Proc_App @P_Condition='UpdateSystemDetails'
	If @P_Condition='UpdateSystemDetails'
	Begin
		Insert into Tbl_AppUpdateSystemDetails(SystemName,SystemIP,UpdateID,UpdatedDate,CreatedBy,CreatedOn,ModifiedBy,ModifiedOn,Project)
		Select X.Col1, X.Col2, X.Col3, GetDate(), ISNULL(X.Col5,'API'), GetDate(), ISNULL(X.Col5,'API'), GetDate(),X.Col4
		from Dbo.StringToTable(@P_LongStr,'|',',') as X

		Set @P_ProcMessage=Cast(@@RowCount as varchar)+' Record(s) affected.'
		Set @P_ProcReturn=1
	End

	--Exec Proc_App @P_Condition='GetNewUpdateForSystem', @P_SystemName='NLP154', @P_CreatedBy=1
	--Exec Proc_App @P_Condition='GetNewUpdateForSystem', @P_SystemName='DESKTOP-IANU0RU', @P_CreatedBy=26
	If @P_Condition='GetNewUpdateForSystem'
	Begin

		Select U.SNo,U.Title,U.Description,U.Location,U.EffectiveFrom,U.IsCompulsary,U.CreatedOn,U.ModifiedOn		
		from Tbl_AppUpdateDetails U
		where U.SNo= @P_SNo

	End	--Added by Hitesh 

	--Exec Proc_App @P_Condition='GetAutoUpdateSettings'
	if @P_Condition='GetAutoUpdateSettings'	--Added by Rajesh to get settings for Application auto update
	Begin
		Select Key1,Key2,Key3,KeyValue 
		from Tbl_Setting 
		where Key1='App' and Key2='AutoUpdation' and Key3='IsRequired'
	End

	--Exec Proc_App @P_Condition='DeleteFromAppUpdateDetails'
	If @P_Condition='DeleteFromAppUpdateDetails'
	Begin
		Exec Proc_CopySchemaOfTable @P_Condition='CreateColumn',@P_SourceTable='Tbl_AppUpdateDetails',@P_DestinationTable='Tbl_DelAppUpdateDetails'
		Exec Proc_GetAllColumns 'GetAllColumns','Tbl_AppUpdateDetails','SNo,CreatedBy,CreatedOn,ModifiedBy,ModifiedOn',@P_ProcMessage OutPut,@P_ProcReturn OutPut
		if ISNULL(@P_ProcMessage,'')<>''
		Begin
			if Not Exists(Select 1 from Information_Schema.Columns where Table_Name='Tbl_DelAppUpdateDetails' and Column_Name='SlNo')
			Begin
				Alter Table Tbl_DelMast Add SlNo int
			End

			Exec('Insert into Tbl_DelAppUpdateDetails('+@P_ProcMessage+',SlNo,CreatedBy,CreatedOn)
			Select '+@P_ProcMessage+',SNo,'''+@P_CreatedBy+''',GetDate()
			from Tbl_AppUpdateDetails
			where SNo='+@P_SNo)
		
			Delete
			from Tbl_AppUpdateDetails 
			where SNo=@P_SNo

			Set @P_ProcMessage=Cast(@@RowCount as varchar)+' Record(s) deleted.'
			Set @P_ProcReturn=1
		End
	End
		
	--Exec Proc_App @P_Condition='GetAllUpdateDetails'
	If @P_Condition='GetAllUpdateDetails'
	Begin
		Declare @TTAppUpdateDetails as Table
		(
			SNo int,
			Project varchar(Max),
			Title varchar(Max),
			Description varchar(Max),
			Location varchar(Max),
			EffectiveFrom DateTime,
			IsCompulsary bit,
			IsActive bit,
			CreatedOn DateTime,
			ModifiedOn DateTime,
			Version bigint,
			IsForUAT bit,
			UpdatedSystems varchar(Max)
		)

		Insert into @TTAppUpdateDetails(SNo,Project,Title,Description,Location,EffectiveFrom,IsCompulsary,IsActive,CreatedOn,ModifiedOn,Version,IsForUAT)
		Select Top(100) SNo,Project,Title,Description,Location,EffectiveFrom,IsCompulsary,IsActive,CreatedOn,ModifiedOn,Version,IsForUAT
		from Tbl_AppUpdateDetails
		order by ModifiedOn Desc

		Update TT
		Set TT.UpdatedSystems=X.UpdatedSystems
		from @TTAppUpdateDetails TT
		inner join (Select UpdateID,Stuff((Select Distinct ', ' + SystemName 
					from Tbl_AppUpdateSystemDetails 
					where UpdateID=X.UpdateID for xml path('')),1,1,'') as 'UpdatedSystems'
					from Tbl_AppUpdateSystemDetails X
					group by UpdateID) X
		on TT.SNo=X.UpdateID
		
		Select *
		from @TTAppUpdateDetails
		order by ModifiedOn Desc
	End

	--Exec Proc_App @P_Condition='SaveAppUpdateDetails', @P_SNo=0, @P_LongStr='0|VFS VER 2.0|VFS MODIFIED|http://localhost:50488/api/NDSRenovationAPI/\\dnc1.zip|1|1|1|1|DMS_VFS|^'
	If @P_Condition='SaveAppUpdateDetails'
	Begin
		IF Exists(Select 1 from Tbl_AppUpdateDetails where SNo=@P_SNo)
		Begin
			Update T
			Set T.Title=X.Col2, T.Description=X.Col3, T.Location=X.Col4, T.EffectiveFrom=Convert(DateTime, GetDate(),103),
			T.IsCompulsary=X.Col5, T.IsActive=X.Col6, T.ModifiedBy=X.Col7, T.ModifiedOn=GetDate(), IsForUAT=X.Col8,[Project]=X.Col9
			from Tbl_AppUpdateDetails T
			inner join Dbo.StringToTable(@P_LongStr,'|','^') as X
			on T.SNo=X.Col1
		End
		Else 
		Begin
			Insert into Tbl_AppUpdateDetails(Title,Description,Location,EffectiveFrom,IsCompulsary,IsActive,CreatedBy,CreatedOn,ModifiedBy,ModifiedOn,IsForUAT,Version,[Project])
			Select X.Col2, X.Col3, X.Col4, Convert(DateTime,Getdate(),103), X.Col5, X.Col6, X.Col7, GetDate(), X.Col7, GetDate(), X.Col8,
			Replace(Convert(varchar,GetDate(),112),'/','')+Replace(Replace(Cast(Cast(GetDate() as Time(3)) as varchar),':',''),'.',''),X.Col9
			from Dbo.StringToTable(@P_LongStr,'|','^') as X
		End
	End

	Commit Transaction
	Set NoCount Off
End Try
Begin Catch
	RollBack Transaction
	Declare @DoRetry bit;
	Declare @ErrorMessage varchar(Max)
	Set @doRetry = 0;
	Set @ErrorMessage = Error_Message()
	If Error_Message() = 1205 -- Deadlock Error Number
	Begin
		Set @doRetry = 1;
	End
	If @DoRetry = 1
	Begin
		Set @RetryCounter = @RetryCounter + 1
		If (@RetryCounter > 5)				
		Begin
			RaisError(@ErrorMessage, 18, 1) -- Raise Error Message if still deadlock occurred after three retries
		End
		Else
		Begin
			WaitFor Delay '00:00:00.500' -- Wait for 100 ms
			GoTo Retry	-- Go to Label RETRY
		End
	End
	Else
	Begin
		RaisError(@ErrorMessage,18, 1)
	End
End Catch
    
IF(@@Error<>0)
Begin
	RollBack
	Set @P_ProcReturn=0
	Set @P_ProcMessage=ERROR_MESSAGE()
End
Else
Begin
	Commit
	Set @P_ProcReturn=1
	Return (1) 
End

if @P_ProcMessage=''
Begin 
	Set @P_ProcMessage=ERROR_MESSAGE()
End