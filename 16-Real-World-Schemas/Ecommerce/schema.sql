-- ============================================================
-- E-COMMERCE DATABASE SCHEMA
-- Domain: Online retail platform (customers, products, orders)
-- PostgreSQL 15+
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- ENUM TYPES
-- ────────────────────────────────────────────────────────────

CREATE TYPE order_status AS ENUM (
    'pending', 'confirmed', 'processing', 'shipped',
    'delivered', 'cancelled', 'refunded'
);

CREATE TYPE payment_status AS ENUM (
    'pending', 'completed', 'failed', 'refunded'
);

CREATE TYPE payment_method AS ENUM (
    'credit_card', 'debit_card', 'upi', 'net_banking',
    'wallet', 'cod'
);

-- ────────────────────────────────────────────────────────────
-- 1. CUSTOMERS
-- ────────────────────────────────────────────────────────────
CREATE TABLE customers (
    customer_id    SERIAL         PRIMARY KEY,
    first_name     VARCHAR(50)    NOT NULL,
    last_name      VARCHAR(50)    NOT NULL,
    email          VARCHAR(100)   NOT NULL UNIQUE,
    phone          VARCHAR(20),
    password_hash  VARCHAR(255)   NOT NULL,
    date_of_birth  DATE,
    is_active      BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE customers IS 'Registered customers of the e-commerce platform';

CREATE INDEX idx_customers_email   ON customers (email);
CREATE INDEX idx_customers_phone   ON customers (phone);
CREATE INDEX idx_customers_name    ON customers (last_name, first_name);

-- ────────────────────────────────────────────────────────────
-- 2. CATEGORIES
-- ────────────────────────────────────────────────────────────
CREATE TABLE categories (
    category_id    SERIAL         PRIMARY KEY,
    name           VARCHAR(100)   NOT NULL UNIQUE,
    description    TEXT,
    parent_id      INT            REFERENCES categories(category_id)
                                  ON DELETE SET NULL,
    created_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE categories IS 'Product categories with optional parent for hierarchy';

CREATE INDEX idx_categories_parent ON categories (parent_id);

-- ────────────────────────────────────────────────────────────
-- 3. PRODUCTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE products (
    product_id     SERIAL          PRIMARY KEY,
    name           VARCHAR(200)    NOT NULL,
    description    TEXT,
    sku            VARCHAR(50)     NOT NULL UNIQUE,
    price          NUMERIC(10, 2)  NOT NULL CHECK (price >= 0),
    discount_pct   NUMERIC(5, 2)   NOT NULL DEFAULT 0
                                   CHECK (discount_pct BETWEEN 0 AND 100),
    stock_quantity INT             NOT NULL DEFAULT 0
                                   CHECK (stock_quantity >= 0),
    category_id    INT             NOT NULL
                                   REFERENCES categories(category_id)
                                   ON DELETE RESTRICT,
    image_url      TEXT,
    is_active      BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE products IS 'Product catalog with pricing, stock, and category link';

CREATE INDEX idx_products_category  ON products (category_id);
CREATE INDEX idx_products_sku       ON products (sku);
CREATE INDEX idx_products_price     ON products (price);
CREATE INDEX idx_products_active    ON products (is_active) WHERE is_active = TRUE;

-- ────────────────────────────────────────────────────────────
-- 4. SHIPPING ADDRESSES
-- ────────────────────────────────────────────────────────────
CREATE TABLE shipping_addresses (
    address_id     SERIAL         PRIMARY KEY,
    customer_id    INT            NOT NULL
                                  REFERENCES customers(customer_id)
                                  ON DELETE CASCADE,
    label          VARCHAR(50)    DEFAULT 'Home',
    address_line1  VARCHAR(255)   NOT NULL,
    address_line2  VARCHAR(255),
    city           VARCHAR(100)   NOT NULL,
    state          VARCHAR(100)   NOT NULL,
    postal_code    VARCHAR(20)    NOT NULL,
    country        VARCHAR(100)   NOT NULL DEFAULT 'India',
    is_default     BOOLEAN        NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE shipping_addresses IS 'Customer shipping/delivery addresses';

CREATE INDEX idx_shipping_customer ON shipping_addresses (customer_id);

-- ────────────────────────────────────────────────────────────
-- 5. ORDERS
-- ────────────────────────────────────────────────────────────
CREATE TABLE orders (
    order_id       SERIAL          PRIMARY KEY,
    customer_id    INT             NOT NULL
                                   REFERENCES customers(customer_id)
                                   ON DELETE RESTRICT,
    address_id     INT             REFERENCES shipping_addresses(address_id)
                                   ON DELETE SET NULL,
    status         order_status    NOT NULL DEFAULT 'pending',
    total_amount   NUMERIC(12, 2)  NOT NULL CHECK (total_amount >= 0),
    notes          TEXT,
    ordered_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE orders IS 'Customer orders with status tracking';

CREATE INDEX idx_orders_customer   ON orders (customer_id);
CREATE INDEX idx_orders_status     ON orders (status);
CREATE INDEX idx_orders_date       ON orders (ordered_at DESC);

-- ────────────────────────────────────────────────────────────
-- 6. ORDER ITEMS
-- ────────────────────────────────────────────────────────────
CREATE TABLE order_items (
    item_id        SERIAL          PRIMARY KEY,
    order_id       INT             NOT NULL
                                   REFERENCES orders(order_id)
                                   ON DELETE CASCADE,
    product_id     INT             NOT NULL
                                   REFERENCES products(product_id)
                                   ON DELETE RESTRICT,
    quantity       INT             NOT NULL CHECK (quantity > 0),
    unit_price     NUMERIC(10, 2)  NOT NULL CHECK (unit_price >= 0),
    discount_pct   NUMERIC(5, 2)   NOT NULL DEFAULT 0,
    line_total     NUMERIC(12, 2)  GENERATED ALWAYS AS (
                       quantity * unit_price * (1 - discount_pct / 100)
                   ) STORED
);

COMMENT ON TABLE order_items IS 'Individual line items within an order';

CREATE INDEX idx_order_items_order   ON order_items (order_id);
CREATE INDEX idx_order_items_product ON order_items (product_id);

-- Prevent duplicate product rows in the same order
CREATE UNIQUE INDEX uq_order_product ON order_items (order_id, product_id);

-- ────────────────────────────────────────────────────────────
-- 7. PAYMENTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE payments (
    payment_id        SERIAL          PRIMARY KEY,
    order_id          INT             NOT NULL
                                      REFERENCES orders(order_id)
                                      ON DELETE CASCADE,
    amount            NUMERIC(12, 2)  NOT NULL CHECK (amount > 0),
    method            payment_method  NOT NULL,
    status            payment_status  NOT NULL DEFAULT 'pending',
    transaction_ref   VARCHAR(100)    UNIQUE,
    paid_at           TIMESTAMPTZ,
    created_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE payments IS 'Payment transactions linked to orders';

CREATE INDEX idx_payments_order    ON payments (order_id);
CREATE INDEX idx_payments_status   ON payments (status);

-- ────────────────────────────────────────────────────────────
-- 8. REVIEWS
-- ────────────────────────────────────────────────────────────
CREATE TABLE reviews (
    review_id      SERIAL         PRIMARY KEY,
    product_id     INT            NOT NULL
                                  REFERENCES products(product_id)
                                  ON DELETE CASCADE,
    customer_id    INT            NOT NULL
                                  REFERENCES customers(customer_id)
                                  ON DELETE CASCADE,
    rating         SMALLINT       NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title          VARCHAR(200),
    body           TEXT,
    is_verified    BOOLEAN        NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE reviews IS 'Customer reviews and ratings for products';

CREATE INDEX idx_reviews_product   ON reviews (product_id);
CREATE INDEX idx_reviews_customer  ON reviews (customer_id);
CREATE INDEX idx_reviews_rating    ON reviews (rating);

-- One review per customer per product
CREATE UNIQUE INDEX uq_review_customer_product
    ON reviews (customer_id, product_id);

-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. ENUMs enforce valid status values at the database level
-- 2. GENERATED ALWAYS AS computes line_total automatically
-- 3. CHECK constraints prevent negative prices and invalid ratings
-- 4. Partial index on products (is_active) speeds up active-product queries
-- 5. Self-referencing FK on categories enables unlimited nesting
-- 6. ON DELETE RESTRICT on orders → customers prevents orphan order deletion
-- ============================================================
