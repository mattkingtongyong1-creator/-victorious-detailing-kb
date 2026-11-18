-- 02_seed.sql
-- Loads the real Victorious Detailing price list (from the owner's notes)
-- plus a small set of test questions. Run after 01_schema.sql.

BEGIN;

INSERT INTO service_category (category_id, name) VALUES
    (1, 'Packages'),
    (2, 'Add-ons');

INSERT INTO service (service_id, category_id, name) VALUES
    (1, 1, 'Basic'),
    (2, 1, 'Standard'),
    (3, 1, 'Premium'),
    (4, 2, 'Clay bar'),
    (5, 2, 'Wax'),
    (6, 2, 'Steam clean'),
    (7, 2, 'Engine bay');

INSERT INTO vehicle_size (size_id, label) VALUES
    (1, 'Smaller car'),
    (2, 'Larger vehicle');

-- Packages: price and time change with vehicle size (6 rows)
INSERT INTO service_price (service_id, size_id, price_usd, est_minutes) VALUES
    (1, 1,  60.00, 150),   -- Basic, smaller car: 2.5 hours
    (1, 2,  80.00, 270),   -- Basic, larger vehicle: 4.5 hours
    (2, 1, 150.00, 150),
    (2, 2, 185.00, 270),
    (3, 1, 300.00, 270),
    (3, 2, 360.00, 270);

-- Add-ons: same price for both sizes; times not recorded yet (8 rows)
INSERT INTO service_price (service_id, size_id, price_usd) VALUES
    (4, 1, 36.00), (4, 2, 36.00),
    (5, 1, 50.00), (5, 2, 50.00),
    (6, 1, 78.00), (6, 2, 78.00),
    (7, 1, 86.00), (7, 2, 86.00);

-- Travel fee: $15, charged only when the drive is over 30 minutes
INSERT INTO service_category (category_id, name) VALUES (3, 'Fees');

INSERT INTO service (service_id, category_id, name, short_description) VALUES
    (8, 3, 'Travel fee', 'Charged only when the drive is over 30 minutes');

INSERT INTO service_price (service_id, size_id, price_usd) VALUES
    (8, 1, 15.00), (8, 2, 15.00);

-- Service area: all of Long Island (every town and city in Nassau and Suffolk)
INSERT INTO service_area (area_id, town, county) VALUES
    (1,  'Hempstead',       'Nassau'),
    (2,  'North Hempstead', 'Nassau'),
    (3,  'Oyster Bay',      'Nassau'),
    (4,  'Glen Cove',       'Nassau'),
    (5,  'Long Beach',      'Nassau'),
    (6,  'Babylon',         'Suffolk'),
    (7,  'Brookhaven',      'Suffolk'),
    (8,  'East Hampton',    'Suffolk'),
    (9,  'Huntington',      'Suffolk'),
    (10, 'Islip',           'Suffolk'),
    (11, 'Riverhead',       'Suffolk'),
    (12, 'Shelter Island',  'Suffolk'),
    (13, 'Smithtown',       'Suffolk'),
    (14, 'Southampton',     'Suffolk'),
    (15, 'Southold',        'Suffolk');

-- Open Monday to Friday, 8 a.m. to 2 p.m. Closed weekends (no row = closed).
INSERT INTO business_hours (day_of_week, open_time, close_time) VALUES
    (1, '08:00', '14:00'),
    (2, '08:00', '14:00'),
    (3, '08:00', '14:00'),
    (4, '08:00', '14:00'),
    (5, '08:00', '14:00');

-- TEST DATA: sample chatbot questions written by the group (not real customers).
-- Unanswered ones are the topics the current bot cannot handle.
INSERT INTO chat_query (asked_at, question_text, service_id, answered) VALUES
    ('2026-11-02 12:05-05', 'How much is the Basic package for a small car?',          1,    TRUE),
    ('2026-11-02 12:40-05', 'How much is Standard for a larger vehicle?',              2,    TRUE),
    ('2026-11-03 12:15-05', 'What does Premium cost for an SUV?',                      3,    TRUE),
    ('2026-11-03 12:52-05', 'How long does a Premium detail take?',                    3,    TRUE),
    ('2026-11-04 12:10-05', 'How long does the wax last?',                             5,    TRUE),
    ('2026-11-04 13:20-05', 'Why does my car need a clay bar treatment?',              4,    TRUE),
    ('2026-11-05 12:33-05', 'How much is the engine bay cleaning?',                    7,    TRUE),
    ('2026-11-05 18:45-05', 'How much is steam cleaning?',                             6,    TRUE),
    ('2026-11-06 12:02-05', 'Can you get scratches out?',                              NULL, FALSE),
    ('2026-11-06 12:48-05', 'What products do you use?',                               NULL, FALSE),
    ('2026-11-09 12:27-05', 'Do you price match?',                                     NULL, FALSE),
    ('2026-11-09 12:55-05', 'How much is wax and how long does it last?',              5,    TRUE),
    ('2026-11-10 09:30-05', 'How long does Standard take on a small car?',             2,    TRUE),
    ('2026-11-10 12:18-05', 'Is Premium worth it over Standard?',                      3,    FALSE),
    ('2026-11-11 12:44-05', 'What is the price for Standard on a sedan?',              2,    TRUE);

-- Articles returned for each question. doc_id values match _id in mongo/kb_articles.json.
INSERT INTO chat_query_document (query_id, doc_id, rank) VALUES
    (5,  '6741a0000000000000000001', 1),   -- wax article
    (6,  '6741a0000000000000000002', 1),   -- clay bar article
    (12, '6741a0000000000000000001', 1);

COMMIT;
