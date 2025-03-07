### SQL Script: Search Across All Columns and Return Row Data in JSON Format

This script dynamically searches for a specific value across all columns of a table and returns the row data in JSON format. It uses `UNPIVOT` to transform columns into rows and `FOR JSON PATH` to generate JSON output.

#### Key Features:
- **Flexible**: Works with any table and column structure.
- **Dynamic**: Schema and table names are passed as variables.
- **JSON Output**: Returns row data in JSON format for easy parsing.

#### Example Usage:
- Schema: `dbo`
- Table: `zoom`
- Search Value: `Alex`

#### Output:
| Column_Name   | Row_Number | Row_JSON                                                                 |
|---------------|------------|--------------------------------------------------------------------------|
| Username      | 1          | {"ID":1,"Topic":"Meeting 1","Type":"TypeA","Start_time":"2023-10-01T10:00:00", ...} |
| ...           | ...        | ...                                                                      |

#### Notes:
- Ensure the schema and table names are correctly specified.
- For older SQL Server versions, replace `STRING_AGG` with `FOR XML PATH`.
