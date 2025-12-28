
select DEPARTMENT,SUM(EMP_SALARY) as TOTAL_SALARY
from {{ source('snapshot_demo', 'emp_sal') }}
GROUP BY DEPARTMENT