-- ============================================================
-- AI / ML SaaS PLATFORM DATABASE SCHEMA
-- Domain: Multi-tenant AI platform (organizations, users,
--         models, inference runs, API keys, billing)
-- PostgreSQL 15+
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- EXTENSIONS
-- ────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";       -- gen_random_uuid()

-- ────────────────────────────────────────────────────────────
-- ENUM TYPES
-- ────────────────────────────────────────────────────────────

CREATE TYPE org_plan AS ENUM ('free', 'starter', 'pro', 'enterprise');

CREATE TYPE user_role AS ENUM ('owner', 'admin', 'member', 'viewer');

CREATE TYPE model_status AS ENUM (
    'draft', 'training', 'ready', 'deprecated', 'archived'
);

CREATE TYPE run_status AS ENUM (
    'queued', 'running', 'completed', 'failed', 'cancelled'
);

CREATE TYPE subscription_status AS ENUM (
    'active', 'past_due', 'cancelled', 'trialing'
);

CREATE TYPE billing_status AS ENUM (
    'pending', 'paid', 'overdue', 'void', 'refunded'
);

-- ────────────────────────────────────────────────────────────
-- 1. ORGANIZATIONS
-- ────────────────────────────────────────────────────────────
CREATE TABLE organizations (
    org_id         UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name           VARCHAR(120)    NOT NULL,
    slug           VARCHAR(60)     NOT NULL UNIQUE,
    plan           org_plan        NOT NULL DEFAULT 'free',
    max_seats      INT             NOT NULL DEFAULT 5
                                   CHECK (max_seats > 0),
    logo_url       TEXT,
    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE organizations IS 'Tenant organizations on the platform';

CREATE INDEX idx_org_slug ON organizations (slug);
CREATE INDEX idx_org_plan ON organizations (plan);

-- ────────────────────────────────────────────────────────────
-- 2. USERS
-- ────────────────────────────────────────────────────────────
CREATE TABLE users (
    user_id        UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id         UUID            NOT NULL
                                   REFERENCES organizations(org_id)
                                   ON DELETE CASCADE,
    email          VARCHAR(150)    NOT NULL UNIQUE,
    password_hash  VARCHAR(255)    NOT NULL,
    full_name      VARCHAR(120)    NOT NULL,
    role           user_role       NOT NULL DEFAULT 'member',
    avatar_url     TEXT,
    is_active      BOOLEAN         NOT NULL DEFAULT TRUE,
    last_login_at  TIMESTAMPTZ,
    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE users IS 'Individual user accounts within organizations';

CREATE INDEX idx_users_org     ON users (org_id);
CREATE INDEX idx_users_email   ON users (email);
CREATE INDEX idx_users_role    ON users (role);

-- ────────────────────────────────────────────────────────────
-- 3. API KEYS
-- ────────────────────────────────────────────────────────────
CREATE TABLE api_keys (
    key_id         UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id         UUID            NOT NULL
                                   REFERENCES organizations(org_id)
                                   ON DELETE CASCADE,
    created_by     UUID            NOT NULL
                                   REFERENCES users(user_id)
                                   ON DELETE SET NULL,
    name           VARCHAR(100)    NOT NULL,
    key_hash       VARCHAR(255)    NOT NULL UNIQUE,
    key_prefix     VARCHAR(12)     NOT NULL,
    scopes         TEXT[]          NOT NULL DEFAULT '{}',
    rate_limit_rpm INT             NOT NULL DEFAULT 60
                                   CHECK (rate_limit_rpm > 0),
    is_active      BOOLEAN         NOT NULL DEFAULT TRUE,
    expires_at     TIMESTAMPTZ,
    last_used_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE api_keys
    IS 'Hashed API keys with scopes and rate limits per organization';

CREATE INDEX idx_apikeys_org       ON api_keys (org_id);
CREATE INDEX idx_apikeys_prefix    ON api_keys (key_prefix);
CREATE INDEX idx_apikeys_active    ON api_keys (is_active) WHERE is_active;

-- ────────────────────────────────────────────────────────────
-- 4. MODELS
-- ────────────────────────────────────────────────────────────
CREATE TABLE models (
    model_id       UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id         UUID            NOT NULL
                                   REFERENCES organizations(org_id)
                                   ON DELETE CASCADE,
    name           VARCHAR(150)    NOT NULL,
    version        VARCHAR(30)     NOT NULL DEFAULT '1.0.0',
    description    TEXT,
    framework      VARCHAR(50),
    status         model_status    NOT NULL DEFAULT 'draft',
    parameters     JSONB           NOT NULL DEFAULT '{}',
    artifact_url   TEXT,
    created_by     UUID            REFERENCES users(user_id)
                                   ON DELETE SET NULL,
    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    UNIQUE (org_id, name, version)
);

COMMENT ON TABLE models IS 'ML models registered by an organization';

CREATE INDEX idx_models_org       ON models (org_id);
CREATE INDEX idx_models_status    ON models (status);
CREATE INDEX idx_models_params    ON models USING GIN (parameters);

-- ────────────────────────────────────────────────────────────
-- 5. MODEL RUNS  (inference / training runs)
-- ────────────────────────────────────────────────────────────
CREATE TABLE model_runs (
    run_id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id        UUID            NOT NULL
                                    REFERENCES models(model_id)
                                    ON DELETE CASCADE,
    triggered_by    UUID            REFERENCES users(user_id)
                                    ON DELETE SET NULL,
    api_key_id      UUID            REFERENCES api_keys(key_id)
                                    ON DELETE SET NULL,
    status          run_status      NOT NULL DEFAULT 'queued',
    input_tokens    INT             NOT NULL DEFAULT 0
                                    CHECK (input_tokens >= 0),
    output_tokens   INT             NOT NULL DEFAULT 0
                                    CHECK (output_tokens >= 0),
    duration_ms     INT             CHECK (duration_ms >= 0),
    cost_usd        NUMERIC(12, 6)  NOT NULL DEFAULT 0
                                    CHECK (cost_usd >= 0),
    error_message   TEXT,
    metadata        JSONB           DEFAULT '{}',
    started_at      TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE model_runs IS 'Individual inference or training executions';

CREATE INDEX idx_runs_model     ON model_runs (model_id);
CREATE INDEX idx_runs_user      ON model_runs (triggered_by);
CREATE INDEX idx_runs_status    ON model_runs (status);
CREATE INDEX idx_runs_created   ON model_runs (created_at DESC);
CREATE INDEX idx_runs_meta      ON model_runs USING GIN (metadata);

-- ────────────────────────────────────────────────────────────
-- 6. SUBSCRIPTIONS
-- ────────────────────────────────────────────────────────────
CREATE TABLE subscriptions (
    subscription_id  UUID                 PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id           UUID                 NOT NULL
                                          REFERENCES organizations(org_id)
                                          ON DELETE CASCADE,
    plan             org_plan             NOT NULL,
    status           subscription_status  NOT NULL DEFAULT 'trialing',
    monthly_price    NUMERIC(10, 2)       NOT NULL CHECK (monthly_price >= 0),
    included_credits INT                  NOT NULL DEFAULT 0,
    stripe_sub_id    VARCHAR(100)         UNIQUE,
    current_period_start TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    current_period_end   TIMESTAMPTZ      NOT NULL,
    cancelled_at     TIMESTAMPTZ,
    created_at       TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ          NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE subscriptions IS 'Organization subscription plans and billing cycles';

CREATE INDEX idx_sub_org       ON subscriptions (org_id);
CREATE INDEX idx_sub_status    ON subscriptions (status);
CREATE INDEX idx_sub_period    ON subscriptions (current_period_end);

-- ────────────────────────────────────────────────────────────
-- 7. BILLING  (invoices)
-- ────────────────────────────────────────────────────────────
CREATE TABLE billing (
    invoice_id       UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id           UUID              NOT NULL
                                       REFERENCES organizations(org_id)
                                       ON DELETE CASCADE,
    subscription_id  UUID              REFERENCES subscriptions(subscription_id)
                                       ON DELETE SET NULL,
    period_start     TIMESTAMPTZ       NOT NULL,
    period_end       TIMESTAMPTZ       NOT NULL,
    subtotal         NUMERIC(12, 2)    NOT NULL CHECK (subtotal >= 0),
    tax              NUMERIC(12, 2)    NOT NULL DEFAULT 0,
    total            NUMERIC(12, 2)    GENERATED ALWAYS AS (
                         subtotal + tax
                     ) STORED,
    currency         CHAR(3)           NOT NULL DEFAULT 'USD',
    status           billing_status    NOT NULL DEFAULT 'pending',
    stripe_inv_id    VARCHAR(100)      UNIQUE,
    due_date         DATE              NOT NULL,
    paid_at          TIMESTAMPTZ,
    created_at       TIMESTAMPTZ       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE billing IS 'Monthly invoices generated from subscription usage';

CREATE INDEX idx_bill_org      ON billing (org_id);
CREATE INDEX idx_bill_status   ON billing (status);
CREATE INDEX idx_bill_due      ON billing (due_date)
    WHERE status IN ('pending', 'overdue');

-- ────────────────────────────────────────────────────────────
-- 8. USAGE LOGS  (append-only audit trail)
-- ────────────────────────────────────────────────────────────
CREATE TABLE usage_logs (
    log_id          BIGSERIAL       PRIMARY KEY,
    org_id          UUID            NOT NULL
                                    REFERENCES organizations(org_id)
                                    ON DELETE CASCADE,
    user_id         UUID            REFERENCES users(user_id)
                                    ON DELETE SET NULL,
    api_key_id      UUID            REFERENCES api_keys(key_id)
                                    ON DELETE SET NULL,
    endpoint        VARCHAR(200)    NOT NULL,
    method          VARCHAR(10)     NOT NULL DEFAULT 'POST',
    tokens_used     INT             NOT NULL DEFAULT 0
                                    CHECK (tokens_used >= 0),
    latency_ms      INT             CHECK (latency_ms >= 0),
    status_code     SMALLINT,
    ip_address      INET,
    user_agent      TEXT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE usage_logs IS 'Append-only API usage audit trail for metering';

CREATE INDEX idx_usage_org       ON usage_logs (org_id);
CREATE INDEX idx_usage_user      ON usage_logs (user_id);
CREATE INDEX idx_usage_created   ON usage_logs (created_at DESC);
CREATE INDEX idx_usage_endpoint  ON usage_logs (endpoint);

-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. UUIDs as primary keys support distributed systems and
--    prevent enumeration attacks on public APIs
-- 2. api_keys stores only the HASH; the raw key is shown once
--    and never stored (key_prefix aids quick identification)
-- 3. models.parameters uses JSONB with a GIN index for
--    flexible hyperparameter storage and querying
-- 4. usage_logs is append-only — ideal for partitioning by
--    created_at in a production deployment
-- 5. GENERATED ALWAYS AS on billing.total keeps invoices
--    consistent without application logic
-- 6. TEXT[] array for api_keys.scopes avoids a separate
--    junction table for a small, bounded set of values
-- ============================================================
