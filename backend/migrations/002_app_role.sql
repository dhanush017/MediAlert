-- Least-privilege role for the application. It can add and read audit rows, and nothing else on audit_logs.
-- NOLOGIN: the app connects as a login role that is granted this one (set up per environment).

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'medialert_app') THEN
    CREATE ROLE medialert_app NOLOGIN;
  END IF;
END
$$;

-- Lets the migrating role switch into medialert_app (SET ROLE), which the tests rely on.
GRANT medialert_app TO CURRENT_USER;

GRANT USAGE ON SCHEMA public TO medialert_app;
GRANT SELECT, INSERT ON audit_logs TO medialert_app;
REVOKE UPDATE, DELETE, TRUNCATE ON audit_logs FROM medialert_app;
