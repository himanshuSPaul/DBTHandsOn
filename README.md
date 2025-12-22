pip install dbt-snowflake==1.10.6
# DBTHandsOn

## Installing dbt and dbt-snowflake

To set up your environment for dbt with Snowflake:

1. **(Recommended)** Create and activate a Python virtual environment:
	```sh
	python -m venv dbt-sf-venv
	# On Windows:
	dbt-sf-venv\Scripts\activate
	# On macOS/Linux:
	source dbt-sf-venv/bin/activate
	```

2. **Install dbt and the Snowflake adapter:**
	```sh
	pip install dbt-snowflake==1.10.6
	```

3. **Verify installation:**
	```sh
	dbt --version
	```

For more details, see the [dbt documentation](https://docs.getdbt.com/docs/introduction).



## Initiate dbt project 


	```sh
	dbt init
	```


# Test Connection present in profile

 dbt debug --profile dbt_sf_handson
