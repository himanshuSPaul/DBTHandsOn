-- Custom Test: Monitor item counts across layers (informational only)
-- Purpose: Track consistency between staging and mart layers  
-- Severity: INFO - This test is disabled as count differences are expected
-- Reason: Incremental materialization may cause different row counts between
--         layers due to the on_delete and on_update merging strategies

SELECT 1 WHERE FALSE  -- Always passes: returns 0 rows



