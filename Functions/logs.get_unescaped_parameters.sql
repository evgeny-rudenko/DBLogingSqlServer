CREATE FUNCTION [logs].[get_unescaped_parameter_name]
(
    @name nvarchar(255) = NULL
)
RETURNS nvarchar(128)
AS
BEGIN

RETURN
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(@name
    , '_x0020_', ' '), '_x0021_', '!'), '_x0022_', '"'), '_x0023_', '#'), '_x0024_', '$')
    , '_x0025_', '%'), '_x0026_', '&'), '_x0027_', ''''), '_x0028_', '('), '_x0029_', ')')
    , '_x002A_', '*'), '_x002B_', '+'), '_x002C_', ','), '_x002D_', '-'), '_x002E_', '.')
    , '_x002F_', '/'), '_x003A_', ':'), '_x003B_', ';'), '_x003C_', '<'), '_x003D_', '=')
    , '_x003E_', '>'), '_x003F_', '?'), '_x0040_', '@'), '_x005B_', '['), '_x005C_', '\')
    , '_x005D_', ']'), '_x005E_', '^'), '_x0060_', '`'), '_x007B_', '{'), '_x007C_', '|')
    , '_x007D_', '}'), '_x007E_', '~')

END