{{ config(materialized='table') }}

-- This model is a placeholder for schema and permissions setup
-- Note: Schema creation, group management, and permission grants 
-- should be handled outside of dbt (in your Snowflake account setup)
-- This file documents the intended warehouse structure.

select 1 as setup_complete
```

**Note:** This SQL file contains only DDL and administrative commands (CREATE SCHEMA, CREATE GROUP, GRANT, ALTER DEFAULT PRIVILEGES) which cannot be converted to a dbt model. 

**Recommendation:** Handle this setup separately:
- Use Snowflake's native setup scripts or Terraform for schema/group/permission management
- Or create a separate `on-run-start` hook in `dbt_project.yml` if you need dbt to execute these commands:

```yaml
on-run-start:
  - "{{ run_query('CREATE SCHEMA IF NOT EXISTS staging') }}"
  - "{{ run_query('CREATE SCHEMA IF NOT EXISTS transforms') }}"
  # ... etc