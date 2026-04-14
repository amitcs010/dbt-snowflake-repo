{{ config(materialized='table') }}

-- This model is a placeholder for schema and permissions setup
-- Note: Schema creation, group management, and permission grants 
-- should be handled outside of dbt (in your Snowflake initialization scripts)
-- This file documents the intended warehouse structure.

select 1 as setup_complete
```

**Note:** This SQL file contains only DDL and DCL statements (CREATE SCHEMA, CREATE GROUP, GRANT, ALTER DEFAULT PRIVILEGES) which cannot be converted to a dbt model. 

**Recommendation:** Handle this setup separately:
1. **Schema & Groups**: Run these as one-time setup scripts in Snowflake before dbt initialization
2. **Permissions**: Manage via Snowflake role-based access control (RBAC) or a dedicated permissions management tool
3. **dbt approach**: Use `pre-hook` or `post-hook` in `dbt_project.yml` if you need to execute setup SQL, or use Snowflake's native role hierarchy instead of groups