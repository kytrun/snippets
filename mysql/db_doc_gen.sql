SET @table_schema='db_name';

SELECT column_name, DATA_TYPE, COLUMN_COMMENT
FROM (
SELECT table_name, '' AS column_name, '' AS DATA_TYPE, '' AS COLUMN_COMMENT, -4 AS ORDINAL_POSITION FROM information_schema.tables WHERE table_schema=@table_schema
UNION
SELECT table_name, CONCAT('表名：', table_name) AS column_name, '' AS DATA_TYPE, '' AS COLUMN_COMMENT, -3 AS ORDINAL_POSITION FROM information_schema.tables WHERE table_schema=@table_schema
UNION
SELECT table_name, CONCAT('用途：', table_comment) AS column_name, '' AS DATA_TYPE, '' AS COLUMN_COMMENT, -2 AS ORDINAL_POSITION FROM information_schema.tables WHERE table_schema=@table_schema
UNION
SELECT table_name, '字段名' AS column_name, '字段类型' AS DATA_TYPE, '描述' AS COLUMN_COMMENT, -1 AS ORDINAL_POSITION FROM information_schema.tables WHERE table_schema=@table_schema
UNION
SELECT table_name, column_name, CONCAT(DATA_TYPE, CASE WHEN CHARACTER_MAXIMUM_LENGTH IS NOT NULL THEN CONCAT('(', CHARACTER_MAXIMUM_LENGTH, ')') WHEN NUMERIC_PRECISION IS NOT NULL THEN CONCAT('(',NUMERIC_PRECISION, CASE WHEN NUMERIC_SCALE>0 THEN CONCAT(',',NUMERIC_SCALE) ELSE '' END , ')') WHEN DATETIME_PRECISION > 0 THEN CONCAT('(', DATETIME_PRECISION, ')') ELSE '' END) AS DATA_TYPE, COLUMN_COMMENT,ORDINAL_POSITION FROM information_schema.columns WHERE table_schema=@table_schema
) AS t
ORDER BY table_name, ORDINAL_POSITION;