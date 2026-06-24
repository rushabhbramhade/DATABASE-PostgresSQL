-- Triggers examples
CREATE OR REPLACE FUNCTION log_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Log changes here
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
