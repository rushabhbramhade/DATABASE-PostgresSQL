# 🤖 AI / ML SaaS Platform Database Schema

## Overview
This database schema models a multi-tenant AI / Machine Learning SaaS platform. It handles tenant organizations, user memberships with role-based access control (RBAC), hashed API keys for developers, ML model registries, inference/training runs, subscription plans, usage-metered billing systems, and append-only API usage audit trails.

## Schema Architecture

```mermaid
erDiagram
    ORGANIZATIONS ||--o{ USERS : "contains"
    ORGANIZATIONS ||--o{ API_KEYS : "issues"
    ORGANIZATIONS ||--o{ MODELS : "registers"
    ORGANIZATIONS ||--o{ SUBSCRIPTIONS : "subscribes"
    ORGANIZATIONS ||--o{ BILLING : "invoiced"
    ORGANIZATIONS ||--o{ USAGE_LOGS : "meters"
    USERS ||--o{ API_KEYS : "creates"
    USERS ||--o{ MODELS : "trains"
    USERS ||--o{ MODEL_RUNS : "triggers"
    USERS ||--o{ USAGE_LOGS : "logs"
    API_KEYS ||--o{ MODEL_RUNS : "authorizes"
    API_KEYS ||--o{ USAGE_LOGS : "logs"
    MODELS ||--o{ MODEL_RUNS : "executes"
    SUBSCRIPTIONS ||--o? BILLING : "generates"
```

## Table Descriptions

### 1. `organizations`
Represents the tenant entities. Uses UUIDs to prevent enumeration attacks. Includes the subscription tier (`plan`) and seat limits.

### 2. `users`
Profiles for individuals linked to an organization. Features a role enum (`owner`, `admin`, `member`, `viewer`) to implement Role-Based Access Control (RBAC).

### 3. `api_keys`
Hashed API keys for programmatic access. The platform only stores the `key_hash` and `key_prefix` (e.g. `sk_live_...`). Scopes are represented as a PostgreSQL `TEXT[]` array for simplified permission checking.

### 4. `models`
An ML model registry detailing versioning, frameworks, parameters (stored as `JSONB` for flexibility), and statuses.

### 5. `model_runs`
Records model execution (e.g., LLM generation or training tasks). Tracks input/output tokens, execution latency, error messages, and cost metrics in USD.

### 6. `subscriptions`
Tracks active plans, pricing tiers, resource credits, stripe mapping, and period ends.

### 7. `billing`
Invoices generated automatically. Computes the net `total` using a generated column (`subtotal + tax`).

### 8. `usage_logs`
An append-only, high-write audit trail of API invocations, tracking latency, IP address, and status codes. Used for usage-based metering.

---

## Sample Queries

### 1. API Key Authentication and Rate Limit Validation
Locates and validates an API key, verifying it is active and not expired.
```sql
SELECT 
    key_id,
    org_id,
    scopes,
    rate_limit_rpm,
    is_active,
    (expires_at IS NULL OR expires_at > NOW()) AS is_valid
FROM api_keys
WHERE key_hash = SHA256('sk_live_abc123')::VARCHAR
  AND is_active = TRUE;
```

### 2. Organization Usage Metering (Token Count & Cost)
Sums up token usage and cost for an organization within a billing period.
```sql
SELECT 
    org_id,
    COUNT(run_id) AS total_runs,
    SUM(input_tokens) AS total_input_tokens,
    SUM(output_tokens) AS total_output_tokens,
    SUM(input_tokens + output_tokens) AS total_tokens,
    SUM(cost_usd) AS total_cost_usd,
    AVG(duration_ms) AS avg_latency_ms
FROM model_runs
WHERE org_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::UUID
  AND created_at BETWEEN '2026-06-01' AND '2026-06-30'
GROUP BY org_id;
```

### 3. Average Model Latencies and Parameters Filtering
Finds model versions with their average run latencies, filtering by model type parameter.
```sql
SELECT 
    m.name AS model_name,
    m.version AS model_version,
    ROUND(AVG(mr.duration_ms) / 1000.0, 3) AS avg_duration_seconds,
    COUNT(mr.run_id) AS total_executions
FROM models m
JOIN model_runs mr ON m.model_id = mr.model_id
WHERE m.parameters @> '{"type": "chat"}'
  AND mr.status = 'completed'
GROUP BY m.model_id, m.name, m.version
ORDER BY avg_duration_seconds ASC;
```

### 4. Organizations Approaching Seat Limits
Finds tenants where the number of active users is close to or exceeds the subscription limit.
```sql
SELECT 
    o.org_id,
    o.name AS organization_name,
    o.plan AS current_plan,
    o.max_seats,
    COUNT(u.user_id) AS active_members,
    o.max_seats - COUNT(u.user_id) AS remaining_seats
FROM organizations o
LEFT JOIN users u ON o.org_id = u.org_id AND u.is_active = TRUE
GROUP BY o.org_id, o.name, o.plan, o.max_seats
HAVING COUNT(u.user_id) >= o.max_seats - 1
ORDER BY active_members DESC;
```
