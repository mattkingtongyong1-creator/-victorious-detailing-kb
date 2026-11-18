-- 04_star_schema.sql
-- Small star schema for reporting on the chatbot log (OLAP side).
-- Safe to re-run: it rebuilds the analytics schema from the operational tables.

DROP SCHEMA IF EXISTS analytics CASCADE;
CREATE SCHEMA analytics;

CREATE TABLE analytics.dim_date (
    date_key      INT          PRIMARY KEY,          -- yyyymmdd
    full_date     DATE         NOT NULL UNIQUE,
    day_name      VARCHAR(10)  NOT NULL,
    week_of_year  SMALLINT     NOT NULL,
    month_name    VARCHAR(10)  NOT NULL
);

-- Denormalized on purpose: category name sits next to the service name
CREATE TABLE analytics.dim_service (
    service_key    SMALLINT     PRIMARY KEY,         -- 0 = no service matched
    service_name   VARCHAR(60)  NOT NULL,
    category_name  VARCHAR(40)  NOT NULL
);

CREATE TABLE analytics.dim_topic (
    topic_key   SMALLINT     PRIMARY KEY,
    topic_name  VARCHAR(20)  NOT NULL UNIQUE
);

CREATE TABLE analytics.fact_chat_query (
    query_id       INT       PRIMARY KEY,
    date_key       INT       NOT NULL REFERENCES analytics.dim_date(date_key),
    service_key    SMALLINT  NOT NULL REFERENCES analytics.dim_service(service_key),
    topic_key      SMALLINT  NOT NULL REFERENCES analytics.dim_topic(topic_key),
    hour_of_day    SMALLINT  NOT NULL,
    answered       SMALLINT  NOT NULL CHECK (answered IN (0, 1)),
    docs_returned  SMALLINT  NOT NULL,
    response_ms    INT
);

-- ===== ETL: extract from the operational tables, transform, load =====

INSERT INTO analytics.dim_topic VALUES
    (1, 'Pricing'), (2, 'Aftercare'), (3, 'Booking'), (4, 'Other');

INSERT INTO analytics.dim_service
SELECT 0, 'No service matched', 'None'
UNION ALL
SELECT s.service_id, s.name, c.name
FROM service s JOIN service_category c USING (category_id);

INSERT INTO analytics.dim_date
SELECT DISTINCT
       TO_CHAR(d, 'YYYYMMDD')::INT,
       d,
       TRIM(TO_CHAR(d, 'Day')),
       EXTRACT(WEEK FROM d)::SMALLINT,
       TRIM(TO_CHAR(d, 'Month'))
FROM (SELECT (asked_at AT TIME ZONE 'America/New_York')::DATE AS d FROM chat_query) x;

INSERT INTO analytics.fact_chat_query
SELECT q.query_id,
       TO_CHAR(q.asked_at AT TIME ZONE 'America/New_York', 'YYYYMMDD')::INT,
       COALESCE(q.service_id, 0),
       CASE                                           -- simple keyword tagging
           WHEN q.question_text ~* '(how much|price|cost)'        THEN 1
           WHEN q.question_text ~* '(last|wax|clay|aftercare)'    THEN 2
           WHEN q.question_text ~* '(book|appointment|schedule)'  THEN 3
           ELSE 4
       END,
       EXTRACT(HOUR FROM q.asked_at AT TIME ZONE 'America/New_York')::SMALLINT,
       q.answered::INT,
       (SELECT COUNT(*) FROM chat_query_document d WHERE d.query_id = q.query_id),
       q.response_ms
FROM chat_query q;

-- ===== Reports on the star schema =====

-- Questions and unanswered rate by topic
SELECT t.topic_name,
       COUNT(*)                                   AS questions,
       ROUND(100.0 * (1 - AVG(f.answered)), 1)    AS pct_unanswered
FROM analytics.fact_chat_query f
JOIN analytics.dim_topic t USING (topic_key)
GROUP BY t.topic_name
ORDER BY questions DESC;

-- Questions by category and service
SELECT s.category_name, s.service_name, COUNT(*) AS questions
FROM analytics.fact_chat_query f
JOIN analytics.dim_service s USING (service_key)
GROUP BY s.category_name, s.service_name
ORDER BY questions DESC, s.service_name;
