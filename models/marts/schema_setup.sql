{{ config(materialized='table') }}

-- This model is a placeholder for schema and permissions setup
-- Note: Schema creation, group management, and permission grants 
-- should be handled outside of dbt (in your Snowflake initialization scripts)
-- This file documents the intended warehouse structure.

select 1 as setup_complete
```

**Note:** This SQL file contains only DDL and DCL statements (CREATE SCHEMA, CREATE GROUP, GRANT, ALTER DEFAULT PRIVILEGES) which cannot be converted to a dbt model. 

**Recommendation:** Handle this setup separately:
1. **Schema & Group Creation**: Run these as one-time setup scripts directly in Snowflake
2. **Permissions Management**: Use Snowflake's role-based access control (RBAC) instead of groups, or manage via a separate `on-run-start` hook in `dbt_project.yml`:

```yaml
# dbt_project.yml
on-run-start:
  - "{{ run_query('CREATE SCHEMA IF NOT EXISTS staging;') }}"
  - "{{ run_query('CREATE SCHEMA IF NOT EXISTS transforms;') }}"
  - "{{ run_query('CREATE SCHEMA IF NOT EXISTS marts;') }}"