
GO
If Exists(Select 1 from Sys.Procedures where Name='Proc_GetAllColumns')
Begin
	Drop Procedure Proc_GetAllColumns
End
Go
Create Procedure [dbo].[Proc_GetAllColumns]
	@P_Condition		Varchar(50),
	@P_SourceTable		varchar(50),
	@P_UnwantedColumns	varchar(Max),
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
	IF ISNULL(@P_ProcMessage,'') =''
	BEGIN
	Set @P_ProcMessage='Operation Failed.'
	END
	Set @P_ProcReturn=0

	--Exec Proc_GetAllColumns @P_Condition='GetAllColumns',@P_SourceTable='TBL_RESMAST',@P_UnwantedColumns='SNo,CreatedBy,CreatedOn,ModifiedBy,ModifiedOn'
	if @P_Condition='GetAllColumns'
	Begin		
		--ADDED BY RAJESH ON 28-06-2019 FOR CREATING DELETE TABLE IN MASTERDB
		If @P_SourceTable like 'ASUA.DBO%' OR @P_SourceTable like 'SUKSN.DBO%' OR @P_SourceTable like 'MUC.DBO%'
		Begin
		set @P_SourceTable =   REPLACE(@P_SourceTable, @P_ProcMessage, '')
		End

		Declare @Str as varchar(Max)='',@ColumnName as varchar(50)
		Declare Cur Cursor for
			Select Column_Name as 'ColumnName'
			from Information_Schema.Columns
			where Table_Name=@P_SourceTable and Column_Name not in (Select Col1 from Dbo.StringToTable(@P_UnwantedColumns,'|',','))
			order by Column_Name
		Open Cur
		Fetch Next From Cur Into @ColumnName
		While @@FETCH_STATUS=0
		Begin
			If ISNULL(@Str,'')=''
			Begin
				Set @Str+=@ColumnName
			End
			Else
			Begin
				Set @Str+=','+@ColumnName
			End			
			Fetch Next From Cur Into @ColumnName
		End
		Close Cur
		DeAllocate Cur

		Set @P_ProcMessage=@Str
		Set @P_ProcReturn=1
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