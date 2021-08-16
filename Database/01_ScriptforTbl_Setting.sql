Use NDSRenovation

If Not Exists(Select 1 from Information_Schema.Columns where Table_Name='Tbl_Setting')
Begin
CREATE TABLE [dbo].[Tbl_Setting](
	[SNo] [int] IDENTITY(1,1) PRIMARY KEY,
	[Key1] [varchar](50) NULL,
	[Key2] [varchar](50) NULL,
	[Key3] [varchar](50) NULL,
	[KeyValue] [varchar](max) NULL,
	[Value] [varchar](50) NULL,
	[IsActive] [bit] NULL,
	[CreatedBy] [varchar](50) NULL,
	[CreatedOn] [datetime] NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedOn] [datetime] NULL,
	)
End
--Declare
--@Key1 as varchar(Max)='',	@Key2 as varchar(Max)='',	@Key3 as varchar(Max)=''

--If Not Exists(Select 1 from Tbl_Setting where Key1='App' and Key2='AppUpgradeEXE' and Key3='IsAvailable')
--Begin
--	INSERT [dbo].[Tbl_Setting] ( [Key1], [Key2], [Key3], [KeyValue], [Value], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES 
--	( N'App', N'NDSRenovationEXE', N'IsAvailable', N'1', NULL, 1, N'1', NULL, NULL, NULL)
--End

--If Not Exists(Select 1 from Tbl_Setting where Key1='DataService' and Key2='AppUpgradeExe' and Key3='ServerPath')
--Begin
--	INSERT [dbo].[Tbl_Setting] ( [Key1], [Key2], [Key3], [KeyValue], [Value], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES
--	( N'NDSRenovationAPI', N'NDSRenovationExe', N'ServerPath', N'C:\DMS_VFS\NDSRenovationEXE\NDSRenovation.exe', NULL, 1, N'1', NULL, NULL, NULL)
--End

--If Not Exists(Select 1 from Tbl_Setting where Key1='DataService' and Key2='NDSRenovationExe' and Key3='DestinationPath')
--Begin
--	INSERT [dbo].[Tbl_Setting] ( [Key1], [Key2], [Key3], [KeyValue], [Value], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES
--    ( N'AppUpdateWebAPI', N'AppUpgradeExe', N'DestinationPath', N'AppUpgrade.exe', NULL, 1, NULL, NULL, NULL, NULL)
--End

----25/04/2019 Added by Hitesh Chauhan to set the location for backup file copy
--If Not Exists(Select 1 from Tbl_Setting where Key1='App' and Key2='ResultBackUp' and Key3='DestinationPath')
--Begin
--	Insert into Tbl_Setting (Key1,Key2,Key3,KeyValue,Value,IsActive,CreatedBy,CreatedOn,ModifiedBy,ModifiedOn)
--	Select 'App','ResultBackUp','DestinationPath','\\AppServer01\C$\EMSDATAEXP','',1,'EMS',GetDate(),'EMS',GetDate()
--End

--25/04/2019 Added by Rajesh to set the location for Application
--If Not Exists(Select 1 from Tbl_Setting where Key1='DMS_VFS' and Key2='Application' and Key3='Path')
--Begin
--	Insert into Tbl_Setting (Key1,Key2,Key3,KeyValue,Value,IsActive,CreatedBy,CreatedOn,ModifiedBy,ModifiedOn)
--	Select 'DMS_VFS','Application','Path','NDS\DMS_VFS','',1,'DMS_VFS',GetDate(),'DMS_VFS',GetDate()
--End


--Select Top(10) * from DMS_VFS.Dbo.Tbl_Setting order by CreatedOn Desc