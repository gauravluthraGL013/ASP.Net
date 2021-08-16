
Go
If Exists(Select 1 from Sys.Procedures where Name='Proc_CopySchemaOfTable')
Begin
	Drop Procedure Proc_CopySchemaOfTable
End
Go
Create Procedure Proc_CopySchemaOfTable
	@P_Condition		Varchar(50),
	@P_SourceTable		varchar(50),
	@P_DestinationTable	varchar(50),
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

	--Exec Proc_CopySchemaOfTable @P_Condition='CreateColumn',@P_SourceTable='Tbl_RESMAST',@P_DestinationTable='Tbl_DelRESMAST',@P_ProcMessage='ASUA.DBO.'
	if @P_Condition='CreateColumn'
	Begin
		--ADDED BY RAJESH ON 28-06-2019 FOR CREATING DELETE TABLE IN MASTERDB
		If @P_SourceTable like 'ASUA.DBO%' OR @P_SourceTable like 'SUKSN.DBO%' OR @P_SourceTable like 'MUC.DBO%'
		Begin

		set @P_SourceTable =   REPLACE(@P_SourceTable, @P_ProcMessage, '')
		set @P_DestinationTable =  REPLACE(@P_DestinationTable, @P_ProcMessage, '')

		End

		Exec Proc_CopySchemaOfTable @P_Condition='CreateTable',@P_SourceTable=@P_SourceTable,@P_DestinationTable=@P_DestinationTable
		
		Declare @ColumnName as varchar(100),@DataType as varchar(100),@Size as varchar(100)
		Declare Cur Cursor for
			Select A.Column_Name as 'ColumnName',A.Data_Type as 'DataType',A.Character_Maximum_Length as 'Size'
			from Information_Schema.Columns A
			left join Information_Schema.Columns B
			on B.Table_Name=@P_DestinationTable
			and A.Column_Name=B.Column_Name
			where A.Table_Name=@P_SourceTable and B.Column_Name is null
		Open Cur
		Fetch Next From Cur Into @ColumnName,@DataType,@Size
		While @@FETCH_STATUS=0
		Begin
			If @Size='-1'
			Begin
				Set @Size='Max'
			End

			If ISNULL(@Size,'')=''
			Begin
				Exec('Alter Table '+@P_DestinationTable+' Add '+@ColumnName+' '+@DataType)
			End
			Else
			Begin
				Exec('Alter Table '+@P_DestinationTable+' Add '+@ColumnName+' '+@DataType+'('+@Size+')')
			End			
			Fetch Next From Cur Into @ColumnName,@DataType,@Size
		End
		Close Cur
		DeAllocate Cur

		Set @P_ProcMessage='Column Created.'
		Set @P_ProcReturn=1
	End
	
	--Exec Proc_CopySchemaOfTable @P_Condition='CreateTable',@P_SourceTable=' TBL_RESMAST',@P_DestinationTable='Tbl_DelRESMAST'
	if @P_Condition='CreateTable'
	Begin
		if Not Exists(Select 1 from Sys.Tables where Name=@P_DestinationTable)
		Begin
			Exec('Create Table '+@P_DestinationTable+'(SNo int Identity(1,1) Primary Key,
											 CreatedBy varchar(50),
											 CreatedOn DateTime,
											 ModifiedBy varchar(50),
											 ModifiedOn DateTime)')
		End

		Set @P_ProcMessage='Table Created.'
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