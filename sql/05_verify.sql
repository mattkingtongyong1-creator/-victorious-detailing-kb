-- 05_verify.sql
-- Proof the database is built and populated. Screenshot this output for the proposal.

-- Row count for every table
SELECT 'service_category' AS table_name, COUNT(*) AS row_count FROM service_category
UNION ALL SELECT 'service',             COUNT(*) FROM service
UNION ALL SELECT 'vehicle_size',        COUNT(*) FROM vehicle_size
UNION ALL SELECT 'service_price',       COUNT(*) FROM service_price
UNION ALL SELECT 'package',             COUNT(*) FROM package
UNION ALL SELECT 'package_service',     COUNT(*) FROM package_service
UNION ALL SELECT 'service_area',        COUNT(*) FROM service_area
UNION ALL SELECT 'business_hours',      COUNT(*) FROM business_hours
UNION ALL SELECT 'chat_query',          COUNT(*) FROM chat_query
UNION ALL SELECT 'chat_query_document', COUNT(*) FROM chat_query_document;

-- The price list as stored
SELECT s.name AS service, c.name AS category, v.label AS vehicle_size,
       p.price_usd, p.est_minutes
FROM service_price p
JOIN service s          USING (service_id)
JOIN service_category c USING (category_id)
JOIN vehicle_size v     USING (size_id)
ORDER BY s.service_id, v.size_id;

-- Integrity check: every price row points at a real service and size (expect 0)
SELECT COUNT(*) AS orphan_price_rows
FROM service_price p
LEFT JOIN service s      ON s.service_id = p.service_id
LEFT JOIN vehicle_size v ON v.size_id    = p.size_id
WHERE s.service_id IS NULL OR v.size_id IS NULL;

-- 1NF check: each returned article is its own row
SELECT q.query_id, q.question_text, d.doc_id, d.rank
FROM chat_query q
JOIN chat_query_document d USING (query_id)
ORDER BY q.query_id, d.rank;
