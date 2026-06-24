-- Stored Procedures examples
CREATE OR REPLACE PROCEDURE greet()
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Hello!';
END $$;
