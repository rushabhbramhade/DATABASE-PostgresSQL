-- ============================================================================
-- JSONB DATA TYPE IN POSTGRESQL
-- ============================================================================
-- JSONB (Binary JSON) is PostgreSQL's powerful data type for storing and
-- querying JSON documents. Unlike plain JSON, JSONB stores data in a
-- decomposed binary format — making it slower to insert but significantly
-- faster to query. It also supports indexing (GIN indexes).
--
-- JSON vs JSONB:
-- ┌────────────────────┬──────────────────────┬──────────────────────┐
-- │ Feature            │ JSON                 │ JSONB                │
-- ├────────────────────┼──────────────────────┼──────────────────────┤
-- │ Storage            │ Exact text copy      │ Decomposed binary    │
-- │ Duplicate keys     │ Allowed              │ Last value wins      │
-- │ Key ordering       │ Preserved            │ Not preserved        │
-- │ Insert speed       │ Faster               │ Slightly slower      │
-- │ Query speed        │ Slower (re-parsed)   │ Much faster          │
-- │ Indexing (GIN)     │ ✗ Not supported      │ ✓ Supported          │
-- │ Equality check     │ ✗ Not supported      │ ✓ Supported          │
-- │ Containment (@>)   │ ✗ Not supported      │ ✓ Supported          │
-- └────────────────────┴──────────────────────┴──────────────────────┘
--
-- Rule of thumb: Always use JSONB unless you specifically need to preserve
-- exact formatting or duplicate keys.
-- ============================================================================


-- ============================================================================
-- SAMPLE TABLE SETUP
-- ============================================================================

DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS app_settings CASCADE;

-- Table with a JSONB column to store flexible product attributes
CREATE TABLE products (
    product_id   SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    category     VARCHAR(50),
    price        NUMERIC(10, 2),
    attributes   JSONB        -- Flexible key-value attributes
);

-- Insert sample data with JSONB
INSERT INTO products (name, category, price, attributes) VALUES
('iPhone 15 Pro', 'Electronics', 1199.99,
 '{"brand": "Apple", "color": "Titanium Blue", "storage_gb": 256,
   "features": ["Face ID", "USB-C", "A17 Pro chip"],
   "specs": {"weight_g": 187, "display_inches": 6.1, "battery_mah": 3274}}'),

('Samsung Galaxy S24', 'Electronics', 899.99,
 '{"brand": "Samsung", "color": "Phantom Black", "storage_gb": 128,
   "features": ["Galaxy AI", "S Pen support", "Snapdragon 8 Gen 3"],
   "specs": {"weight_g": 167, "display_inches": 6.2, "battery_mah": 4000}}'),

('Sony WH-1000XM5', 'Audio', 349.99,
 '{"brand": "Sony", "color": "Black", "type": "Over-ear",
   "features": ["ANC", "LDAC", "30hr battery", "Multipoint"],
   "specs": {"weight_g": 250, "driver_mm": 30, "bluetooth": "5.2"}}'),

('MacBook Pro 16"', 'Electronics', 2499.99,
 '{"brand": "Apple", "color": "Space Black", "storage_gb": 512,
   "ram_gb": 18, "chip": "M3 Pro",
   "features": ["Liquid Retina XDR", "MagSafe", "HDMI"],
   "specs": {"weight_g": 2140, "display_inches": 16.2, "battery_hrs": 22}}'),

('Kindle Paperwhite', 'Electronics', 149.99,
 '{"brand": "Amazon", "color": "Agave Green", "storage_gb": 16,
   "features": ["Waterproof", "Warm light", "USB-C"],
   "specs": {"weight_g": 205, "display_inches": 6.8}}'),

('Nike Air Max 90', 'Footwear', 129.99,
 '{"brand": "Nike", "color": "White/Red", "sizes": [7, 8, 9, 10, 11, 12],
   "material": "Leather/Mesh", "gender": "Unisex"}'),

('Organic Green Tea', 'Grocery', 12.99,
 '{"brand": "Twinings", "weight_g": 200, "organic": true,
   "origin": "Japan", "caffeine": "low"}');


-- ============================================================================
-- EXAMPLE 1: Basic JSONB Operators — -> and ->>
-- ============================================================================
-- ->   Returns a JSON object/value (as JSONB type)
-- ->>  Returns a JSON value as plain TEXT

SELECT
    name,
    attributes -> 'brand'        AS brand_json,     -- Returns: "Apple" (with quotes, JSONB)
    attributes ->> 'brand'       AS brand_text,     -- Returns: Apple  (without quotes, TEXT)
    attributes -> 'storage_gb'   AS storage_json,   -- Returns: 256 (JSONB number)
    attributes ->> 'storage_gb'  AS storage_text    -- Returns: 256 (TEXT)
FROM products
WHERE category = 'Electronics';

-- Expected Output:
-- ┌──────────────────┬────────────┬────────────┬──────────────┬──────────────┐
-- │ name             │ brand_json │ brand_text │ storage_json │ storage_text │
-- ├──────────────────┼────────────┼────────────┼──────────────┼──────────────┤
-- │ iPhone 15 Pro    │ "Apple"    │ Apple      │ 256          │ 256          │
-- │ Samsung Galaxy   │ "Samsung"  │ Samsung    │ 128          │ 128          │
-- │ MacBook Pro 16"  │ "Apple"    │ Apple      │ 512          │ 512          │
-- │ Kindle Paperwhite│ "Amazon"   │ Amazon     │ 16           │ 16           │
-- └──────────────────┴────────────┴────────────┴──────────────┴──────────────┘


-- ============================================================================
-- EXAMPLE 2: Nested Access — #> and #>>
-- ============================================================================
-- #>   Navigate a path and return JSONB
-- #>>  Navigate a path and return TEXT

SELECT
    name,
    attributes #> '{specs, weight_g}'     AS weight_jsonb,    -- JSONB
    attributes #>> '{specs, weight_g}'    AS weight_text,     -- TEXT
    attributes #>> '{specs, display_inches}' AS display_size,
    attributes #> '{features, 0}'         AS first_feature    -- Array index 0
FROM products
WHERE attributes #>> '{specs, display_inches}' IS NOT NULL;

-- Expected Output:
-- ┌──────────────────┬──────────────┬─────────────┬──────────────┬───────────────────────┐
-- │ name             │ weight_jsonb │ weight_text │ display_size │ first_feature         │
-- ├──────────────────┼──────────────┼─────────────┼──────────────┼───────────────────────┤
-- │ iPhone 15 Pro    │ 187          │ 187         │ 6.1          │ "Face ID"             │
-- │ Samsung Galaxy   │ 167          │ 167         │ 6.2          │ "Galaxy AI"           │
-- │ MacBook Pro 16"  │ 2140         │ 2140        │ 16.2         │ "Liquid Retina XDR"   │
-- │ Kindle Paperwhite│ 205          │ 205         │ 6.8          │ "Waterproof"          │
-- └──────────────────┴──────────────┴─────────────┴──────────────┴───────────────────────┘


-- ============================================================================
-- EXAMPLE 3: Containment Operator — @>
-- ============================================================================
-- @> checks if the left JSONB value contains the right JSONB value

-- Find all Apple products
SELECT name, price
FROM products
WHERE attributes @> '{"brand": "Apple"}';

-- Expected Output:
-- ┌──────────────────┬─────────┐
-- │ name             │ price   │
-- ├──────────────────┼─────────┤
-- │ iPhone 15 Pro    │ 1199.99 │
-- │ MacBook Pro 16"  │ 2499.99 │
-- └──────────────────┴─────────┘

-- Find products that have USB-C in their features array
SELECT name, price
FROM products
WHERE attributes @> '{"features": ["USB-C"]}';

-- Expected Output:
-- ┌──────────────────┬─────────┐
-- │ name             │ price   │
-- ├──────────────────┼─────────┤
-- │ iPhone 15 Pro    │ 1199.99 │
-- │ Kindle Paperwhite│  149.99 │
-- └──────────────────┴─────────┘

-- Find organic products
SELECT name, price
FROM products
WHERE attributes @> '{"organic": true}';

-- Expected Output:
-- ┌───────────────────┬───────┐
-- │ name              │ price │
-- ├───────────────────┼───────┤
-- │ Organic Green Tea │ 12.99 │
-- └───────────────────┴───────┘


-- ============================================================================
-- EXAMPLE 4: Key Existence Operators — ?, ?|, ?&
-- ============================================================================
-- ?   Does the key exist at the top level?
-- ?|  Does ANY of these keys exist?
-- ?&  Do ALL of these keys exist?

-- Products that have a "storage_gb" attribute
SELECT name, attributes ->> 'storage_gb' AS storage
FROM products
WHERE attributes ? 'storage_gb';

-- Expected Output:
-- ┌───────────────────┬─────────┐
-- │ name              │ storage │
-- ├───────────────────┼─────────┤
-- │ iPhone 15 Pro     │ 256     │
-- │ Samsung Galaxy S24│ 128     │
-- │ MacBook Pro 16"   │ 512     │
-- │ Kindle Paperwhite │ 16      │
-- └───────────────────┴─────────┘

-- Products that have EITHER "ram_gb" OR "chip" key  (any key exists)
SELECT name
FROM products
WHERE attributes ?| ARRAY['ram_gb', 'chip'];

-- Expected Output:
-- ┌─────────────────┐
-- │ name            │
-- ├─────────────────┤
-- │ MacBook Pro 16" │
-- └─────────────────┘

-- Products that have BOTH "brand" AND "color" AND "sizes" (all keys exist)
SELECT name
FROM products
WHERE attributes ?& ARRAY['brand', 'color', 'sizes'];

-- Expected Output:
-- ┌─────────────────┐
-- │ name            │
-- ├─────────────────┤
-- │ Nike Air Max 90 │
-- └─────────────────┘


-- ============================================================================
-- EXAMPLE 5: Updating JSONB — jsonb_set()
-- ============================================================================
-- jsonb_set(target, path, new_value, create_if_missing)

-- Update the color of iPhone
UPDATE products
SET attributes = jsonb_set(attributes, '{color}', '"Titanium Natural"')
WHERE name = 'iPhone 15 Pro';

-- Verify the update
SELECT name, attributes ->> 'color' AS color
FROM products
WHERE name = 'iPhone 15 Pro';

-- Expected Output:
-- ┌───────────────┬──────────────────┐
-- │ name          │ color            │
-- ├───────────────┼──────────────────┤
-- │ iPhone 15 Pro │ Titanium Natural │
-- └───────────────┴──────────────────┘

-- Update a nested value (change battery_mah inside specs)
UPDATE products
SET attributes = jsonb_set(attributes, '{specs, battery_mah}', '3500')
WHERE name = 'iPhone 15 Pro';

-- Add a new key that doesn't exist yet (create_if_missing = true is default)
UPDATE products
SET attributes = jsonb_set(attributes, '{warranty_years}', '2')
WHERE name = 'iPhone 15 Pro';

SELECT name, attributes ->> 'warranty_years' AS warranty
FROM products
WHERE name = 'iPhone 15 Pro';

-- Expected Output:
-- ┌───────────────┬──────────┐
-- │ name          │ warranty │
-- ├───────────────┼──────────┤
-- │ iPhone 15 Pro │ 2        │
-- └───────────────┴──────────┘


-- ============================================================================
-- EXAMPLE 6: Updating JSONB — || (Concatenation) and - (Remove Key)
-- ============================================================================

-- || merges two JSONB objects (right side overwrites left on conflict)
UPDATE products
SET attributes = attributes || '{"on_sale": true, "discount_pct": 15}'
WHERE name = 'Samsung Galaxy S24';

SELECT name, attributes ->> 'on_sale' AS on_sale, attributes ->> 'discount_pct' AS discount
FROM products
WHERE name = 'Samsung Galaxy S24';

-- Expected Output:
-- ┌────────────────────┬─────────┬──────────┐
-- │ name               │ on_sale │ discount │
-- ├────────────────────┼─────────┼──────────┤
-- │ Samsung Galaxy S24 │ true    │ 15       │
-- └────────────────────┴─────────┴──────────┘

-- Remove a key using  -  operator
UPDATE products
SET attributes = attributes - 'discount_pct'
WHERE name = 'Samsung Galaxy S24';

-- Remove a nested key using  #-  operator
UPDATE products
SET attributes = attributes #- '{specs, bluetooth}'
WHERE name = 'Sony WH-1000XM5';

-- Remove an element from an array by index
-- Remove the 2nd feature (index 1) from Sony headphones
UPDATE products
SET attributes = attributes #- '{features, 1}'
WHERE name = 'Sony WH-1000XM5';

SELECT name, attributes -> 'features' AS remaining_features
FROM products
WHERE name = 'Sony WH-1000XM5';

-- Expected Output (LDAC at index 1 removed):
-- ┌──────────────────┬───────────────────────────────────────────┐
-- │ name             │ remaining_features                        │
-- ├──────────────────┼───────────────────────────────────────────┤
-- │ Sony WH-1000XM5  │ ["ANC", "30hr battery", "Multipoint"]    │
-- └──────────────────┴───────────────────────────────────────────┘


-- ============================================================================
-- EXAMPLE 7: Querying JSONB Arrays
-- ============================================================================

-- Expand a JSONB array into rows using jsonb_array_elements()
SELECT
    p.name,
    feature.value AS feature
FROM products p,
     jsonb_array_elements(p.attributes -> 'features') AS feature(value)
WHERE p.name = 'iPhone 15 Pro';

-- Expected Output:
-- ┌───────────────┬────────────────┐
-- │ name          │ feature        │
-- ├───────────────┼────────────────┤
-- │ iPhone 15 Pro │ "Face ID"      │
-- │ iPhone 15 Pro │ "USB-C"        │
-- │ iPhone 15 Pro │ "A17 Pro chip" │
-- └───────────────┴────────────────┘

-- Use jsonb_array_elements_text() for plain text output (no quotes)
SELECT
    p.name,
    feature.value AS feature
FROM products p,
     jsonb_array_elements_text(p.attributes -> 'features') AS feature(value)
WHERE p.category = 'Electronics';

-- Count features per product
SELECT
    name,
    jsonb_array_length(attributes -> 'features') AS num_features
FROM products
WHERE attributes ? 'features';

-- Expected Output:
-- ┌────────────────────┬──────────────┐
-- │ name               │ num_features │
-- ├────────────────────┼──────────────┤
-- │ iPhone 15 Pro      │ 3            │
-- │ Samsung Galaxy S24 │ 3            │
-- │ Sony WH-1000XM5    │ 3            │
-- │ MacBook Pro 16"    │ 3            │
-- │ Kindle Paperwhite  │ 3            │
-- └────────────────────┴──────────────┘


-- ============================================================================
-- EXAMPLE 8: GIN Index on JSONB (Performance)
-- ============================================================================
-- GIN (Generalized Inverted Index) dramatically speeds up JSONB queries
-- that use @>, ?, ?|, ?& operators.

-- Default GIN index — supports @>, ?, ?|, ?&
CREATE INDEX idx_products_attributes ON products USING GIN (attributes);

-- With jsonb_path_ops — smaller index, supports only @> (containment)
-- Best when you primarily query with @>
CREATE INDEX idx_products_attrs_pathops ON products
    USING GIN (attributes jsonb_path_ops);

-- Expression-based index for frequent lookups on a specific key
CREATE INDEX idx_products_brand ON products
    USING BTREE ((attributes ->> 'brand'));

-- Now these queries will use the GIN index:
EXPLAIN (COSTS OFF)
SELECT * FROM products WHERE attributes @> '{"brand": "Apple"}';

-- Expected plan (with enough rows):
-- Bitmap Heap Scan on products
--   Recheck Cond: (attributes @> '{"brand": "Apple"}'::jsonb)
--   ->  Bitmap Index Scan on idx_products_attributes
--         Index Cond: (attributes @> '{"brand": "Apple"}'::jsonb)


-- ============================================================================
-- EXAMPLE 9: JSONB Aggregate Functions
-- ============================================================================

-- jsonb_agg() — Aggregate values into a JSONB array
SELECT jsonb_agg(name) AS all_product_names
FROM products
WHERE category = 'Electronics';

-- Expected Output:
-- ┌────────────────────────────────────────────────────────────────────┐
-- │ all_product_names                                                 │
-- ├────────────────────────────────────────────────────────────────────┤
-- │ ["iPhone 15 Pro","Samsung Galaxy S24","MacBook Pro 16\"",         │
-- │  "Kindle Paperwhite"]                                             │
-- └────────────────────────────────────────────────────────────────────┘

-- jsonb_object_agg() — Aggregate key-value pairs into a JSONB object
SELECT jsonb_object_agg(name, price) AS product_prices
FROM products
WHERE category = 'Electronics';

-- Expected Output:
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ product_prices                                                          │
-- ├──────────────────────────────────────────────────────────────────────────┤
-- │ {"iPhone 15 Pro": 1199.99, "Samsung Galaxy S24": 899.99,               │
-- │  "MacBook Pro 16\"": 2499.99, "Kindle Paperwhite": 149.99}             │
-- └──────────────────────────────────────────────────────────────────────────┘

-- Build a summary of brands and their product counts
SELECT jsonb_object_agg(brand, product_count) AS brand_summary
FROM (
    SELECT attributes ->> 'brand' AS brand, COUNT(*) AS product_count
    FROM products
    GROUP BY attributes ->> 'brand'
) sub;

-- Expected Output:
-- ┌────────────────────────────────────────────────────────────────┐
-- │ brand_summary                                                  │
-- ├────────────────────────────────────────────────────────────────┤
-- │ {"Nike": 1, "Sony": 1, "Apple": 2, "Amazon": 1,              │
-- │  "Samsung": 1, "Twinings": 1}                                 │
-- └────────────────────────────────────────────────────────────────┘


-- ============================================================================
-- EXAMPLE 10: Iterating Over JSONB Keys and Values
-- ============================================================================

-- jsonb_each() — Expand top-level JSONB object into key-value rows (JSONB values)
SELECT key, value
FROM products,
     jsonb_each(attributes) AS kv(key, value)
WHERE name = 'Organic Green Tea';

-- Expected Output:
-- ┌───────────┬────────────┐
-- │ key       │ value      │
-- ├───────────┼────────────┤
-- │ brand     │ "Twinings" │
-- │ origin    │ "Japan"    │
-- │ organic   │ true       │
-- │ weight_g  │ 200        │
-- │ caffeine  │ "low"      │
-- └───────────┴────────────┘

-- jsonb_each_text() — Same but values are returned as TEXT
SELECT key, value
FROM products,
     jsonb_each_text(attributes) AS kv(key, value)
WHERE name = 'Organic Green Tea';

-- jsonb_object_keys() — Get only the top-level keys
SELECT jsonb_object_keys(attributes) AS top_keys
FROM products
WHERE name = 'iPhone 15 Pro';

-- Expected Output:
-- ┌────────────────┐
-- │ top_keys       │
-- ├────────────────┤
-- │ brand          │
-- │ color          │
-- │ specs          │
-- │ features       │
-- │ storage_gb     │
-- │ warranty_years │
-- └────────────────┘

-- jsonb_typeof() — Check the type of a JSONB value
SELECT
    name,
    jsonb_typeof(attributes -> 'brand')    AS brand_type,     -- string
    jsonb_typeof(attributes -> 'features') AS features_type,  -- array
    jsonb_typeof(attributes -> 'specs')    AS specs_type      -- object
FROM products
WHERE name = 'iPhone 15 Pro';

-- Expected Output:
-- ┌───────────────┬────────────┬───────────────┬────────────┐
-- │ name          │ brand_type │ features_type │ specs_type │
-- ├───────────────┼────────────┼───────────────┼────────────┤
-- │ iPhone 15 Pro │ string     │ array         │ object     │
-- └───────────────┴────────────┴───────────────┴────────────┘


-- ============================================================================
-- EXAMPLE 11: JSONB Path Queries (PostgreSQL 12+)
-- ============================================================================
-- SQL/JSON path expressions provide a powerful way to query JSONB

-- jsonb_path_query() — Find values matching a path expression
-- Get all features from all products
SELECT
    name,
    jsonb_path_query(attributes, '$.features[*]') AS feature
FROM products
WHERE name = 'MacBook Pro 16"';

-- Expected Output:
-- ┌─────────────────┬──────────────────────┐
-- │ name            │ feature              │
-- ├─────────────────┼──────────────────────┤
-- │ MacBook Pro 16" │ "Liquid Retina XDR"  │
-- │ MacBook Pro 16" │ "MagSafe"            │
-- │ MacBook Pro 16" │ "HDMI"               │
-- └─────────────────┴──────────────────────┘

-- jsonb_path_exists() — Check if a path exists
SELECT
    name,
    jsonb_path_exists(attributes, '$.specs.battery_mah') AS has_battery_info
FROM products
WHERE category = 'Electronics';

-- jsonb_path_query_first() — Get only the first match
SELECT
    name,
    jsonb_path_query_first(attributes, '$.features[0]') AS first_feature
FROM products
WHERE attributes ? 'features';

-- Filter within path expression — find products with storage > 200
SELECT name, price
FROM products
WHERE jsonb_path_exists(attributes, '$.storage_gb ? (@ > 200)');

-- Expected Output:
-- ┌─────────────────┬─────────┐
-- │ name            │ price   │
-- ├─────────────────┼─────────┤
-- │ iPhone 15 Pro   │ 1199.99 │
-- │ MacBook Pro 16" │ 2499.99 │
-- └─────────────────┴─────────┘


-- ============================================================================
-- EXAMPLE 12: Real-World — User Preferences & Settings System
-- ============================================================================

CREATE TABLE user_profiles (
    user_id       SERIAL PRIMARY KEY,
    username      VARCHAR(50) UNIQUE NOT NULL,
    email         VARCHAR(100) NOT NULL,
    preferences   JSONB DEFAULT '{}'::jsonb,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert users with different preference structures
INSERT INTO user_profiles (username, email, preferences) VALUES
('alice_dev', 'alice@example.com',
 '{"theme": "dark", "language": "en", "timezone": "America/New_York",
   "notifications": {"email": true, "push": true, "sms": false},
   "dashboard": {"widgets": ["calendar", "tasks", "analytics"], "layout": "grid"}}'),

('bob_designer', 'bob@example.com',
 '{"theme": "light", "language": "fr", "timezone": "Europe/Paris",
   "notifications": {"email": true, "push": false, "sms": false},
   "dashboard": {"widgets": ["projects", "chat"], "layout": "list"}}'),

('charlie_pm', 'charlie@example.com',
 '{"theme": "auto", "language": "en", "timezone": "Asia/Tokyo",
   "notifications": {"email": true, "push": true, "sms": true},
   "dashboard": {"widgets": ["calendar", "reports", "team"], "layout": "grid"}}');

-- Create GIN index for fast preference lookups
CREATE INDEX idx_user_preferences ON user_profiles USING GIN (preferences);

-- Query: Find users with dark theme
SELECT username, email
FROM user_profiles
WHERE preferences @> '{"theme": "dark"}';

-- Query: Find users who have push notifications enabled
SELECT username
FROM user_profiles
WHERE preferences #>> '{notifications, push}' = 'true';

-- Query: Find users who have "calendar" widget on their dashboard
SELECT username
FROM user_profiles
WHERE preferences @> '{"dashboard": {"widgets": ["calendar"]}}';

-- Expected Output:
-- ┌────────────┐
-- │ username   │
-- ├────────────┤
-- │ alice_dev  │
-- │ charlie_pm │
-- └────────────┘

-- Update: Change Bob's theme to dark
UPDATE user_profiles
SET preferences = jsonb_set(preferences, '{theme}', '"dark"')
WHERE username = 'bob_designer';

-- Update: Add a new widget to Alice's dashboard
UPDATE user_profiles
SET preferences = jsonb_set(
    preferences,
    '{dashboard, widgets}',
    (preferences #> '{dashboard, widgets}') || '["reports"]'
)
WHERE username = 'alice_dev';

-- Update: Toggle a notification setting
UPDATE user_profiles
SET preferences = jsonb_set(preferences, '{notifications, sms}', 'true')
WHERE username = 'bob_designer';

-- Generate a report: all users and their notification preferences
SELECT
    username,
    preferences ->> 'theme'                         AS theme,
    preferences #>> '{notifications, email}'         AS email_notif,
    preferences #>> '{notifications, push}'          AS push_notif,
    preferences #>> '{notifications, sms}'           AS sms_notif,
    jsonb_array_length(preferences #> '{dashboard, widgets}') AS widget_count
FROM user_profiles
ORDER BY username;

-- Expected Output:
-- ┌──────────────┬───────┬─────────────┬────────────┬───────────┬──────────────┐
-- │ username     │ theme │ email_notif │ push_notif │ sms_notif │ widget_count │
-- ├──────────────┼───────┼─────────────┼────────────┼───────────┼──────────────┤
-- │ alice_dev    │ dark  │ true        │ true       │ false     │ 4            │
-- │ bob_designer │ dark  │ true        │ false      │ true      │ 2            │
-- │ charlie_pm   │ auto  │ true        │ true       │ true      │ 3            │
-- └──────────────┴───────┴─────────────┴────────────┴───────────┴──────────────┘


-- ============================================================================
-- KEY TAKEAWAYS
-- ============================================================================
-- 1. Use JSONB (not JSON) for most use cases — it's faster to query and
--    supports indexing.
--
-- 2. Operator cheat sheet:
--    ->   Get JSONB value by key/index
--    ->>  Get value as TEXT
--    #>   Get JSONB value by path (array of keys)
--    #>>  Get value as TEXT by path
--    @>   Left contains right (containment)
--    ?    Key exists at top level
--    ?|   Any of these keys exist
--    ?&   All of these keys exist
--    ||   Merge/concatenate JSONB
--    -    Remove key (top-level)
--    #-   Remove key by path
--
-- 3. Use jsonb_set() for targeted updates without overwriting the entire doc.
--
-- 4. Create GIN indexes on JSONB columns for fast @> and ? queries.
--    Use jsonb_path_ops for smaller indexes when only @> is needed.
--
-- 5. Use jsonb_path_query() (PostgreSQL 12+) for complex path-based filtering.
--
-- 6. JSONB is perfect for semi-structured data: user preferences, product
--    attributes, API responses, event metadata, and configuration storage.
--
-- 7. Don't store everything in JSONB — use regular columns for data you
--    frequently filter, sort, or join on. Use JSONB for flexible attributes.
-- ============================================================================
