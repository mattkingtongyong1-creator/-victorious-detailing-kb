-- 01_schema.sql
-- Victorious Detailing chatbot knowledge base: PostgreSQL schema (3NF)
-- Run first. Safe to re-run: it drops and rebuilds every table.

DROP TABLE IF EXISTS chat_query_document, chat_query, business_hours, service_area,
                     package_service, package, service_price, vehicle_size,
                     service, service_category CASCADE;

-- Groups services (Packages, Add-ons)
CREATE TABLE service_category (
    category_id  SMALLINT     PRIMARY KEY,
    name         VARCHAR(40)  NOT NULL UNIQUE
);

-- One row per service offered
CREATE TABLE service (
    service_id         SMALLINT      PRIMARY KEY,
    category_id        SMALLINT      NOT NULL REFERENCES service_category(category_id),
    name               VARCHAR(60)   NOT NULL UNIQUE,
    short_description  VARCHAR(200),
    is_active          BOOLEAN       NOT NULL DEFAULT TRUE   -- soft delete
);

CREATE TABLE vehicle_size (
    size_id  SMALLINT     PRIMARY KEY,
    label    VARCHAR(40)  NOT NULL UNIQUE
);

-- Price and time depend on BOTH service and vehicle size, so they get their own table
CREATE TABLE service_price (
    service_id   SMALLINT      NOT NULL REFERENCES service(service_id),
    size_id      SMALLINT      NOT NULL REFERENCES vehicle_size(size_id),
    price_usd    NUMERIC(7,2)  NOT NULL CHECK (price_usd > 0),
    est_minutes  SMALLINT      CHECK (est_minutes > 0),      -- NULL = not timed yet
    PRIMARY KEY (service_id, size_id)
);

-- Bundles of services
CREATE TABLE package (
    package_id   SMALLINT      PRIMARY KEY,
    name         VARCHAR(60)   NOT NULL UNIQUE,
    description  VARCHAR(200)
);

-- Junction table: which services are in each bundle
CREATE TABLE package_service (
    package_id  SMALLINT  NOT NULL REFERENCES package(package_id) ON DELETE CASCADE,
    service_id  SMALLINT  NOT NULL REFERENCES service(service_id),
    PRIMARY KEY (package_id, service_id)
);

-- Towns and cities served on Long Island.
-- The travel fee depends on drive time, not on the town, so it is stored once
-- as a row in service / service_price instead of being repeated here.
CREATE TABLE service_area (
    area_id  SMALLINT     PRIMARY KEY,
    town     VARCHAR(60)  NOT NULL,
    county   VARCHAR(10)  NOT NULL CHECK (county IN ('Nassau', 'Suffolk')),
    UNIQUE (town, county)
);

-- 0 = Sunday ... 6 = Saturday
CREATE TABLE business_hours (
    day_of_week  SMALLINT  PRIMARY KEY CHECK (day_of_week BETWEEN 0 AND 6),
    open_time    TIME      NOT NULL,
    close_time   TIME      NOT NULL,
    CHECK (close_time > open_time)
);

-- Log of every chatbot question (question text only, no customer details)
CREATE TABLE chat_query (
    query_id       INT           GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asked_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    question_text  VARCHAR(500)  NOT NULL,
    service_id     SMALLINT      REFERENCES service(service_id),   -- NULL = no service matched
    answered       BOOLEAN       NOT NULL DEFAULT FALSE,
    response_ms    INT           CHECK (response_ms >= 0)          -- filled by the retrieval layer
);

-- Junction table that replaces the old doc_ids[] array (1NF fix).
-- One row per article returned for a question.
CREATE TABLE chat_query_document (
    query_id  INT       NOT NULL REFERENCES chat_query(query_id) ON DELETE CASCADE,
    doc_id    CHAR(24)  NOT NULL CHECK (doc_id ~ '^[0-9a-f]{24}$'),  -- MongoDB ObjectId as text
    rank      SMALLINT  NOT NULL CHECK (rank BETWEEN 1 AND 3),
    PRIMARY KEY (query_id, doc_id),
    UNIQUE (query_id, rank)
);

CREATE INDEX idx_chat_query_asked_at ON chat_query (asked_at);
CREATE INDEX idx_chat_query_service  ON chat_query (service_id);
