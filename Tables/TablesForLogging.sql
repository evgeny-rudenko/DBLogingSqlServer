CREATE TABLE [logs].[TablesForLogging](
	[BaseName] [nvarchar](50) NULL,
	[TableName] [nvarchar](50) NULL,
	[Field_Key] [nvarchar](100) NULL, -- ????
	[is_active] [bit] NULL,
	[Storage] [int] NULL --- ????
) ON [PRIMARY]
GO

ALTER TABLE [logs].[TablesForLogging] ADD  CONSTRAINT [DF_TablesForLogging_is_active]  DEFAULT ((1)) FOR [is_active]
GO