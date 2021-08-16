
If Exists(Select 1 from Sys.Procedures where Name='Proc_License')
Begin
	Drop Procedure Proc_License
End
Go
Create PROCEDURE [dbo].[Proc_License]

@P_Condition varchar(Max),
@P_LongStr varchar(Max) = NULL,
@P_CreatedBy	Varchar(50)		= NULL,	
@P_ProcMessage	Varchar(Max)	= NULL OutPut,
@P_ProcReturn	Integer 		= NULL OutPut

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

	--Exec Proc_License @P_condition='DeleteLicenseDetails',@P_LongStr='2'
	if @P_condition='DeleteLicenseDetails'
	Begin
		DELETE A FROM [dbo].[Tbl_LicenseDtl] A
		inner join [dbo].[Tbl_LicenseHdr] B
		ON A.[MasterLicense] = B.[MasterLicense]
		Where B.SNo = @P_LongStr

		DELETE  FROM [dbo].[Tbl_LicenseHdr]  Where SNo = @P_LongStr

		Set @P_ProcMessage='License deleted successfully.'
		Set @P_ProcReturn=1
	End

	--Exec Proc_License @P_condition='GetLicenseDetails',@P_LongStr='bcdaef76-cac3-4405-a95e-ab3dbdb96730'
	if @P_condition='GetLicenseDetails'
	Begin
		Select A.[MasterLicense],A.[ChildCount],A.[EffectiveFrom],A.[EffectiveTo],B.[ClientLicense] 
		from [dbo].[Tbl_LicenseHdr] A
		inner join [dbo].[Tbl_LicenseDtl] B
		ON A.[MasterLicense] = B.[MasterLicense]
		Where A.[MasterLicense] = @P_LongStr
	End

	--Exec Proc_License @P_Condition='GetAllGeneratedLicenses'
	If @P_Condition='GetAllGeneratedLicenses'
	Begin
		Declare @TTLicenseDetails as Table
		(
			SNo int,
			MasterLicense varchar(Max),
			ClientID int,
			ClientName varchar(Max),
			ChildCount int,
			EffectiveFrom DateTime,
			EffectiveTo DateTime,
			ModifiedOn DateTime
		)

		Insert into @TTLicenseDetails(SNo,MasterLicense,ClientID,ChildCount,EffectiveFrom,EffectiveTo,ModifiedOn)
		Select SNo,MasterLicense,ClientID,ChildCount,EffectiveFrom,EffectiveTo,ModifiedOn
		from Tbl_LicenseHdr
		order by ModifiedOn Desc

		Update TT
		Set TT.ClientName=X.ClientName
		from @TTLicenseDetails TT
		inner join [dbo].[Tbl_Client] X
		on TT.ClientID=X.SNo
		
		Select *
		from @TTLicenseDetails
		order by ModifiedOn Desc
	End

	--Exec Proc_License @P_condition='SaveLicenseDetails', @P_LongStr='0|1|fbc71f1c-2350-4730-aaee-5e93294fbdfb|new|3|2020-10-26|2020-11-26|31|true^'
	if @P_condition='SaveLicenseDetails'
	Begin
	Declare @ChildCount int, @i int
	Select @ChildCount = Col5 from DBo.StringToTable(@P_LongStr,'|','^')

		INSERT INTO [dbo].[Tbl_LicenseHdr]([ClientID],[MasterLicense],[Status],[ChildCount] ,[EffectiveFrom] ,[EffectiveTo],[Validity],[IsActive],[CreatedBy] ,[CreatedOn],[ModifiedBy] ,[Modifiedon])
	     Select Col2,Col3,Col4,Col5,Col6,Col7,Col8,Col9,@P_CreatedBy,GetDate(),@P_CreatedBy,GetDate()	
			from DBo.StringToTable(@P_LongStr,'|','^')
		
		Set @i=1
		While @i<=@ChildCount
		Begin
		INSERT INTO [dbo].[Tbl_LicenseDtl]
           ([ClientID] ,[MasterLicense],[ClientLicense],[CreatedBy],[CreatedOn],[ModifiedBy] ,[Modifiedon])
		    Select Col2,Col3,newid(),@P_CreatedBy,GetDate(),@P_CreatedBy,GetDate()	
			from DBo.StringToTable(@P_LongStr,'|','^')
			set @i = @i + 1
		End

	Set @P_ProcMessage='License generated successfully.'
	Set @P_ProcReturn=1
	End

	--Exec Proc_License @P_condition='GetClientDetails'
	if @P_condition='GetClientDetails'
	Begin
		Select SNo,ClientName from Tbl_Client
	End

	--Exec Proc_License @P_condition='GenerateMasterLicense'
	if @P_condition='GenerateMasterLicense'
	Begin
		Select newid() as MasterLicense
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
	Return (1) 
End

if @P_ProcMessage=''
Begin 
	Set @P_ProcMessage=ERROR_MESSAGE()
End
