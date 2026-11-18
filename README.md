# Victorious Detailing Chatbot Knowledge Base

Hybrid PostgreSQL + MongoDB data layer for a customer-service chatbot.
Term group project: Dominic Corraro, Matthew Kingtongyong, Eric Costa.

## What is in this repo

| File | What it does |
| --- | --- |
| `sql/01_schema.sql` | Creates the 10 PostgreSQL tables with keys and constraints |
| `sql/02_seed.sql` | Loads the real price list and a set of test questions |
| `sql/03_queries.sql` | Eight queries: retrieval, transactional, aggregation, BI reporting |
| `sql/04_star_schema.sql` | Builds the reporting star schema and runs the ETL |
| `sql/05_verify.sql` | Row counts and checks that prove the database is populated |
| `mongo/kb_articles.json` | FAQ documents for the MongoDB `kb_articles` collection |
| `docs/expected_output.txt` | Output of `05_verify.sql` from a clean build |

## How to build it

PostgreSQL 16:

```bash
createdb victorious_kb
psql -d victorious_kb -f sql/01_schema.sql
psql -d victorious_kb -f sql/02_seed.sql
psql -d victorious_kb -f sql/03_queries.sql
psql -d victorious_kb -f sql/04_star_schema.sql
psql -d victorious_kb -f sql/05_verify.sql
```

In pgAdmin: create a database named `victorious_kb`, open the Query Tool,
and run each file in the same order.

MongoDB:

```bash
mongoimport --uri "<your Atlas connection string>" --db victorious_kb \
  --collection kb_articles --jsonArray --file mongo/kb_articles.json
```

## Build evidence

Output from a clean build on PostgreSQL 16.15 (scripts 01–04, then 05_verify.sql):

| Screenshot | Shows |
| --- | --- |
| [01_tables.png](docs/screenshots/01_tables.png) | All 10 tables created |
| [02_verify.png](docs/screenshots/02_verify.png) | Row counts, full price list, 0 orphan rows, junction table rows |
| [03_unanswered_view.png](docs/screenshots/03_unanswered_view.png) | Reporting view of unanswered questions |

## Status

- Loaded: categories, services, vehicle sizes, prices, job times, business hours,
  service area, test questions.
- The $15 travel fee (drives over 30 minutes) is stored as a row in `service`
  under the `Fees` category, so the price lives in one place.
- `package` and `package_service` are empty because the business does not offer
  bundles today. The tables are kept so bundles can be added later.- The questions in `chat_query` are test data written by the group, not real customers.
- FAQ answer text in `mongo/kb_articles.json` still has to be written.
