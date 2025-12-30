Welcome to your new dbt project!

### Using the starter project



``` 
Root Path            : D:\Learning\VSCode\DBT\DBTHandsOn
Virtual Env. Path    : D:\Learning\VSCode\DBT\DBTHandsOn\dbt-sf-venv
DBT Project Path     : D:\Learning\VSCode\DBT\DBTHandsOn\dbt_sf_handson
Sample Data Dir Path : D:\Learning\VSCode\DBT\DBTHandsOn\ImportJaffelShopDataToSnowflake
```

### Steps to Start Using This Project
```
-- Step :1  
-- Activate Virtual Envirnment
D:\Learning\VSCode\DBT\DBTHandsOn\dbt-sf-venv\Scripts\Activate.ps1;

--Step :2
-- Go To DBT Project Folder
cd D:\Learning\VSCode\DBT\DBTHandsOn\dbt_sf_handson

You should see below folder structure for 'tree /f' command 

│   .gitignore
│   dbt_project.yml
│   README.md
├───analyses
│       .gitkeep
├───macros
│       .gitkeep
├───models
│       .gitkeep
├───seeds
│       .gitkeep
├───snapshots
│       .gitkeep
├───target
│       .gitkeep
└───tests
        .gitkeep
```
### Resources:


## Snapshot 

Snowflake Queries For DBT Snapshot

### DBT Init Log

#### dbt init Setup

```
09:33:46  Running with dbt=1.11.0-rc4
09:33:46  Setting up your profile.
The profile dbt_sf_handson already exists in C:\Users\Himanshu\.dbt\profiles.yml. Continue and overwrite it? [y/N]: y
Which database would you like to use?
[1] snowflake

(Don't see the one you want? https://docs.getdbt.com/docs/available-adapters)

Enter a number: 1
account (https://<this_value>.snowflakecomputing.com): xdyidpl-ui11981
user (dev username): himanshu
[1] password
[2] keypair
[3] sso
Desired authentication type option (enter a number): 1
password (dev password): 
role (dev role): ACCOUNTADMIN
warehouse (warehouse name): COMPUTE_WH
database (default database that dbt will build objects in): DEMODB
schema (default schema that dbt will build objects in): PUBLIC
threads (1 or more) [1]: 4
09:35:09  Profile dbt_sf_handson written to C:\Users\Himanshu\.dbt\profiles.yml using target's profile_template.yml and your supplied values. Run 'dbt debug' to validate the connection.
```

#### dbt debug Validation

```
09:35:54  Running with dbt=1.11.0-rc4
09:35:54  dbt version: 1.11.0-rc4
09:35:54  python version: 3.13.7
09:35:54  python path: D:\Learning\VSCode\DBT\DBTHandsOn\dbt-sf-venv\Scripts\python.exe
09:35:54  os info: Windows-11-10.0.26200-SP0
09:35:54  Using profiles dir at C:\Users\Himanshu\.dbt
09:35:54  Using profiles.yml file at C:\Users\Himanshu\.dbt\profiles.yml
09:35:54  Using dbt_project.yml file at D:\Learning\VSCode\dbt_project.yml
09:35:54  adapter type: snowflake
09:35:54  adapter version: 1.10.6
09:35:54  Configuration:
09:35:54    profiles.yml file [OK found and valid]
09:35:54    dbt_project.yml file [OK found and valid]
09:35:54  Required dependencies:
09:35:54   - git [OK found]

09:35:54  Connection:
09:35:54    account: xdyidpl-ui11981
09:35:54    user: himanshu
09:35:54    database: DEMODB
09:35:54    warehouse: COMPUTE_WH
09:35:54    role: ACCOUNTADMIN
09:35:54    schema: PUBLIC
09:35:54    authenticator: None
09:35:54    oauth_client_id: None
09:35:54    query_tag: None
09:35:54    client_session_keep_alive: False
09:35:54    host: None
09:35:54    port: None
09:35:54    proxy_host: None
09:35:54    proxy_port: None
09:35:54    protocol: None
09:35:54    connect_retries: 1
09:35:54    connect_timeout: None
09:35:54    retry_on_database_errors: False
09:35:54    retry_all: False
09:35:54    insecure_mode: False
09:35:54    reuse_connections: True
09:35:54    s3_stage_vpce_dns_name: None
09:35:54    platform_detection_timeout_seconds: 0.0
09:35:54  Registered adapter: snowflake=1.10.6
09:36:02    Connection test: [OK connection ok]

09:36:02  All checks passed!
```



