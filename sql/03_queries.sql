-- 03_queries.sql
-- Eight queries across the four categories in the proposal.

-- ===== RETRIEVAL (chatbot lookups) =====

-- Q1. "How much is Standard for a larger vehicle?"
SELECT s.name AS service, v.label AS vehicle_size, p.price_usd, p.est_minutes
FROM service s
JOIN service_price p ON p.service_id = s.service_id
JOIN vehicle_size  v ON v.size_id    = p.size_id
WHERE s.is_active
  AND s.name  ILIKE '%standard%'
  AND v.label ILIKE '%larger%';

-- Q2. Full price list, the way the chatbot would read it back
SELECT c.name AS category, s.name AS service, v.label AS vehicle_size, p.price_usd
FROM service_category c
JOIN service s       ON s.category_id = c.category_id
JOIN service_price p ON p.service_id  = s.service_id
JOIN vehicle_size v  ON v.size_id     = p.size_id
WHERE s.is_active
ORDER BY c.category_id, p.price_usd, v.size_id;

-- ===== TRANSACTIONAL (CRUD) =====

-- Q3. Raise the wax price in one place; every answer uses the new price.
--     Rolled back here so the demo data stays the same.
BEGIN;
UPDATE service_price SET price_usd = 55.00 WHERE service_id = 5;
SELECT s.name, p.size_id, p.price_usd
FROM service_price p JOIN service s USING (service_id)
WHERE s.name = 'Wax';
ROLLBACK;

-- Q4. Retire a service without deleting its history (soft delete). Rolled back.
BEGIN;
UPDATE service SET is_active = FALSE WHERE name = 'Steam clean';
SELECT name, is_active FROM service ORDER BY service_id;
ROLLBACK;

-- ===== AGGREGATION =====

-- Q5. Average, lowest and highest price by category
SELECT c.name AS category,
       COUNT(DISTINCT s.service_id)  AS services,
       ROUND(AVG(p.price_usd), 2)    AS avg_price,
       MIN(p.price_usd)              AS min_price,
       MAX(p.price_usd)              AS max_price
FROM service_category c
JOIN service s       ON s.category_id = c.category_id
JOIN service_price p ON p.service_id  = s.service_id
GROUP BY c.name
ORDER BY avg_price DESC;

-- Q6. Services that cost more for a larger vehicle, and by how much
SELECT s.name,
       MAX(p.price_usd) - MIN(p.price_usd) AS size_upcharge
FROM service s
JOIN service_price p ON p.service_id = s.service_id
GROUP BY s.name
HAVING MAX(p.price_usd) > MIN(p.price_usd)
ORDER BY size_upcharge DESC;

-- ===== BI REPORTING =====

-- Q7. Most-asked-about services, ranked
SELECT s.name AS service,
       COUNT(*) AS questions,
       RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
FROM chat_query q
JOIN service s ON s.service_id = q.service_id
GROUP BY s.name
ORDER BY rnk, s.name;

-- Q8. Questions per hour, with the share left unanswered
WITH by_hour AS (
    SELECT EXTRACT(HOUR FROM asked_at AT TIME ZONE 'America/New_York')::INT AS hour_of_day,
           COUNT(*)                                AS questions,
           COUNT(*) FILTER (WHERE NOT answered)    AS unanswered
    FROM chat_query
    GROUP BY 1
)
SELECT hour_of_day, questions, unanswered,
       ROUND(100.0 * unanswered / questions, 1) AS pct_unanswered
FROM by_hour
ORDER BY questions DESC, hour_of_day;

-- Reporting view the owner can check every two weeks
CREATE OR REPLACE VIEW v_unanswered_questions AS
SELECT query_id, asked_at, question_text
FROM chat_query
WHERE NOT answered
ORDER BY asked_at DESC;

SELECT * FROM v_unanswered_questions;
