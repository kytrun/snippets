SET @table_schema='db_name';


WITH table_indexes AS (
    SELECT
        table_name,
        GROUP_CONCAT(
            DISTINCT
            CONCAT(
                index_name,
                CASE WHEN non_unique = 0 THEN '(唯一)' ELSE '' END,
                ': (',
                (
                    SELECT GROUP_CONCAT(column_name ORDER BY seq_in_index)
                    FROM information_schema.statistics s2
                    WHERE s2.table_schema = s1.table_schema
                    AND s2.table_name = s1.table_name
                    AND s2.index_name = s1.index_name
                ),
                ')'
            ) ORDER BY index_name SEPARATOR '; '
        ) as index_info
    FROM information_schema.statistics s1
    WHERE table_schema = @table_schema
    GROUP BY table_name
)

SELECT column_name, DATA_TYPE, is_nullable, COLUMN_COMMENT
FROM (
    SELECT table_name, '' AS column_name, '' AS DATA_TYPE, '' AS is_nullable, '' AS COLUMN_COMMENT, -5 AS ORDINAL_POSITION
    FROM information_schema.tables
    WHERE table_schema=@table_schema

    UNION ALL
    SELECT table_name, CONCAT('表名：', table_name) AS column_name, '' AS DATA_TYPE, '' AS is_nullable, '' AS COLUMN_COMMENT, -4 AS ORDINAL_POSITION
    FROM information_schema.tables
    WHERE table_schema=@table_schema

    UNION ALL
    SELECT table_name, CONCAT('用途：', table_comment) AS column_name, '' AS DATA_TYPE, '' AS is_nullable, '' AS COLUMN_COMMENT, -3 AS ORDINAL_POSITION
    FROM information_schema.tables
    WHERE table_schema=@table_schema

    UNION ALL
    SELECT t.table_name, CONCAT('索引：', COALESCE(i.index_info, '无')) AS column_name, '' AS DATA_TYPE, '' AS is_nullable, '' AS COLUMN_COMMENT, -2 AS ORDINAL_POSITION
    FROM information_schema.tables t
    LEFT JOIN table_indexes i ON t.table_name = i.table_name
    WHERE t.table_schema=@table_schema

    UNION ALL
    SELECT table_name, '字段名' AS column_name, '字段类型' AS DATA_TYPE, '是否必填' AS is_nullable, '描述' AS COLUMN_COMMENT, -1 AS ORDINAL_POSITION
    FROM information_schema.tables
    WHERE table_schema=@table_schema

    UNION ALL
    SELECT
        table_name,
        column_name,
        CONCAT(DATA_TYPE, CASE
            WHEN CHARACTER_MAXIMUM_LENGTH IS NOT NULL THEN CONCAT('(', CHARACTER_MAXIMUM_LENGTH, ')')
            WHEN NUMERIC_PRECISION IS NOT NULL THEN CONCAT('(',NUMERIC_PRECISION, CASE WHEN NUMERIC_SCALE>0 THEN CONCAT(',',NUMERIC_SCALE) ELSE '' END , ')')
            WHEN DATETIME_PRECISION > 0 THEN CONCAT('(', DATETIME_PRECISION, ')')
            ELSE '' END) AS DATA_TYPE,
        CASE IS_NULLABLE WHEN 'NO' THEN '是' ELSE '否' END AS is_nullable,
        COLUMN_COMMENT,
        ORDINAL_POSITION
    FROM information_schema.columns
    WHERE table_schema=@table_schema
) AS t
ORDER BY table_name, ORDINAL_POSITION;