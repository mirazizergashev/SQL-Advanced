-- Declare variables for schema name, table name, and search value
DECLARE @SchemaName NVARCHAR(MAX) = 'dbo'; -- Schema name
DECLARE @TableName NVARCHAR(MAX) = 'zoom'; -- Table name
DECLARE @SearchValue NVARCHAR(MAX) = 'Alex'; -- Value to search

-- Declare variables to store column names and SQL query
DECLARE @Columns NVARCHAR(MAX); -- Stores column names cast to NVARCHAR(MAX)
DECLARE @UnpivotColumns NVARCHAR(MAX); -- Stores column names for UNPIVOT operation
DECLARE @SQL NVARCHAR(MAX); -- Stores the dynamically generated SQL query

-- Retrieve column names from INFORMATION_SCHEMA and cast them to NVARCHAR(MAX)
-- Use FOR XML PATH for older SQL Server versions
SELECT @Columns = CAST(
    (SELECT 'CAST(' + QUOTENAME(COLUMN_NAME) + ' AS NVARCHAR(MAX)) AS ' + QUOTENAME(COLUMN_NAME) + ', '
     FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_NAME = @TableName 
       AND TABLE_SCHEMA = @SchemaName
     FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)') 
AS NVARCHAR(MAX));

-- Retrieve column names for UNPIVOT operation
-- Use FOR XML PATH for older SQL Server versions
SELECT @UnpivotColumns = CAST(
    (SELECT QUOTENAME(COLUMN_NAME) + ', '
     FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_NAME = @TableName 
       AND TABLE_SCHEMA = @SchemaName
     FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)') 
AS NVARCHAR(MAX));

-- Remove the trailing comma from @Columns and @UnpivotColumns
SET @Columns = LEFT(@Columns, LEN(@Columns) - 1);
SET @UnpivotColumns = LEFT(@UnpivotColumns, LEN(@UnpivotColumns) - 1);

-- Construct the dynamic SQL query
SET @SQL = '
-- Step 1: Create a CTE (Common Table Expression) to prepare the data
WITH SourceData AS (
    SELECT ' + @Columns + ', 
           -- Assign a unique row number to each row for identification
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS original_row
    FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '
),
-- Step 2: Perform UNPIVOT to transform columns into rows
Unpvt AS (
    SELECT column_name, value, original_row
    FROM SourceData
    UNPIVOT (value FOR column_name IN (' + @UnpivotColumns + ')) AS unpvt
),
-- Step 3: Create JSON data for each row
JSONData AS (
    SELECT 
        original_row,
        -- Generate JSON data for the row using FOR JSON PATH
        (SELECT ' + @Columns + ' 
         FROM SourceData 
         WHERE original_row = Unpvt.original_row
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS Row_JSON
    FROM Unpvt
)
-- Step 4: Final query to retrieve the results
SELECT 
    column_name AS Column_Name, -- Column name where the search value was found
    MAX(Unpvt.original_row) AS Row_Number, -- Row number where the value was found
    MAX(Row_JSON) AS Row_JSON -- JSON data of the row
FROM Unpvt
JOIN JSONData ON Unpvt.original_row = JSONData.original_row
-- Filter rows where the value matches the search value
WHERE value = ''' + REPLACE(@SearchValue, '''', '''''') + '''
GROUP BY column_name, Unpvt.original_row;';

-- Print the dynamic SQL query for debugging
PRINT @SQL;

-- Execute the dynamic SQL query
EXEC sp_executesql @SQL;
