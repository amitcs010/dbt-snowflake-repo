-- depends_on: {{ source('raw', 'raw_clickstream') }}

{{ config(materialized='table') }}

WITH raw_events AS (
    SELECT
        event_id,
        GET_PATH(PARSE_JSON(payload), 'user_id')::STRING          AS user_id,
        GET_PATH(PARSE_JSON(payload), 'session_id')::STRING        AS session_id,
        GET_PATH(PARSE_JSON(payload), 'event_type')::STRING        AS event_type,
        GET_PATH(PARSE_JSON(payload), 'page_url')::STRING          AS page_url,
        GET_PATH(PARSE_JSON(payload), 'referrer')::STRING          AS referrer,
        GET_PATH(PARSE_JSON(payload), 'device_type')::STRING       AS device_type,
        GET_PATH(PARSE_JSON(payload), 'browser')::STRING           AS browser,
        GET_PATH(PARSE_JSON(payload), 'country')::STRING           AS country,
        GET_PATH(PARSE_JSON(payload), 'product_id')::STRING        AS product_id,
        TRY_CAST(GET_PATH(PARSE_JSON(payload), 'revenue')::STRING AS DECIMAL(12,2)) AS event_revenue,
        TRY_TO_TIMESTAMP(event_time)                              AS event_timestamp,
        CURRENT_TIMESTAMP()                                        AS _loaded_at,
        ROW_NUMBER() OVER (
            PARTITION BY event_id 
            ORDER BY event_time DESC
        ) AS _row_num
    FROM {{ source('raw', 'raw_clickstream') }}
    WHERE event_time >= DATEADD(day, -3, CURRENT_DATE())
      AND event_id IS NOT NULL
)
SELECT
    event_id,
    TRY_CAST(user_id AS BIGINT)         AS user_id,
    session_id,
    event_type,
    page_url,
    COALESCE(referrer, 'direct')        AS referrer,
    COALESCE(device_type, 'unknown')    AS device_type,
    browser,
    country,
    TRY_CAST(product_id AS BIGINT)      AS product_id,
    COALESCE(event_revenue, 0)          AS event_revenue,
    event_timestamp,
    _loaded_at
FROM raw_events
WHERE _row_num = 1