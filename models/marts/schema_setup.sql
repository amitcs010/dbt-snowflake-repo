{{ config(materialized='table') }}

-- This model is a placeholder for schema and permissions setup
-- Note: Schema creation, group management, and permission grants 
-- should be handled outside of dbt models (in dbt_project.yml hooks or separate scripts)
-- This file documents the intended warehouse structure.

select 1 as setup_complete
```

**Note:** The original SQL file contains only DDL and administrative commands (CREATE SCHEMA, CREATE GROUP, GRANT, ALTER DEFAULT PRIVILEGES) with no data transformation logic. 

These operations should be handled separately:
- **Schema/group creation**: Use dbt hooks in `dbt_project.yml` or a separate setup script
- **Permissions management**: Use Snowflake role-based access control (RBAC) configured outside dbt
- **External schemas**: Configure in `profiles.yml` or through Snowflake setup scripts

If you need to document the warehouse structure, consider creating a `_warehouse_config.yml` file in your `models/` directory instead.