
CREATE TABLE [logs].[TableLoggingData](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Base_ID] [bigint] NOT NULL,
	[Table_ID] [bigint] NOT NULL,
	[DateAdd] [datetime] NOT NULL,
	[is_type] [bit] NOT NULL,
	[HostName] [varchar](100) NULL,
	[ProgramName] [varchar](100) NULL,
	[Proc_ID] [bigint] NULL,
	[SystemUser] [varchar](50) NULL,
	[Str_json] [nvarchar](max) NULL, 
    [Str_xml] NVARCHAR(MAX) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
