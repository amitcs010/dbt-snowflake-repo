{{ config(materialized='table') }}

-- depends_on: {{ source('raw', 'raw_customers') }}

WITH ranked AS (
    SELECT
        CAST(c.id AS NUMBER)                         AS customer_id,
        CAST(c.email AS VARCHAR)                     AS email_raw,
        CAST(c.first_name AS VARCHAR)                AS first_name,
        CAST(c.last_name AS VARCHAR)                 AS last_name,
        CAST(c.phone AS VARCHAR)                     AS phone_raw,
        CAST(c.country AS VARCHAR)                   AS country,
        CAST(c.state AS VARCHAR)                     AS state,
        CAST(c.city AS VARCHAR)                      AS city,
        CAST(c.postal_code AS VARCHAR)               AS postal_code,
        TRY_TO_DATE(c.created_at)                    AS registration_date,
        TRY_TO_DATE(c.last_login)                    AS last_login_date,
        COALESCE(c.marketing_opt_in, FALSE)          AS marketing_opt_in,
        COALESCE(c.loyalty_tier, 'Bronze')           AS loyalty_tier,
        CAST(c.lifetime_value AS DECIMAL(12, 2))    AS reported_ltv,
        ROW_NUMBER() OVER (
            PARTITION BY c.id
            ORDER BY c.updated_at DESC
        ) AS _row_num
    FROM {{ source('raw', 'raw_customers') }} c
    WHERE c.id IS NOT NULL
      AND c.email IS NOT NULL
      AND LENGTH(c.email) > 3
)
SELECT
    customer_id,
    -- PII masking: hash email, keep domain for analytics
    MD5(LOWER(TRIM(email_raw)))                      AS email_hash,
    SPLIT_PART(email_raw, '@', 2)                    AS email_domain,
    LEFT(first_name, 1) || '***'                     AS first_name_masked,
    LEFT(last_name, 1) || '***'                      AS last_name_masked,
    -- Keep only country code from phone
    LEFT(phone_raw, 3)                               AS phone_country_prefix,
    country,
    state,
    city,
    LEFT(postal_code, 3) || '***'                    AS postal_code_masked,
    registration_date,
    last_login_date,
    marketing_opt_in,
    loyalty_tier,
    COALESCE(reported_ltv, 0)                        AS reported_ltv,
    DATEDIFF(day, registration_date, CURRENT_DATE()) AS days_since_registration,
    CURRENT_TIMESTAMP()                              AS _loaded_at
FROM ranked
WHERE _row_num = 1