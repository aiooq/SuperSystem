BEGIN TRANSACTION;

-- Таблица: country
CREATE TABLE IF NOT EXISTS n.country (id INTEGER PRIMARY KEY UNIQUE NOT NULL, name TEXT, code TEXT, currency TEXT, currency_symbol TEXT, url_name TEXT);

-- Таблица: event
CREATE TABLE IF NOT EXISTS n.event (id INTEGER PRIMARY KEY UNIQUE NOT NULL, type INTEGER NOT NULL, sector INTEGER NOT NULL, frequency INTEGER NOT NULL, time_mode INTEGER NOT NULL, country_id INTEGER NOT NULL REFERENCES country (id) ON DELETE CASCADE ON UPDATE CASCADE, unit INTEGER NOT NULL, importance INTEGER NOT NULL, multiplier INTEGER NOT NULL, digits INTEGER NOT NULL, source_url TEXT, event_code TEXT, name TEXT);

-- Таблица: event_change
CREATE TABLE IF NOT EXISTS n.event_change (id INTEGER PRIMARY KEY UNIQUE NOT NULL, count INTEGER);

-- Таблица: value
CREATE TABLE IF NOT EXISTS n.value (id INTEGER PRIMARY KEY UNIQUE NOT NULL, event_id INTEGER NOT NULL REFERENCES event (id) ON DELETE CASCADE ON UPDATE CASCADE, time INTEGER NOT NULL, period INTEGER NOT NULL, revision INTEGER NOT NULL, actual_value REAL, prev_value REAL, revised_prev_value REAL, forecast_value REAL, impact_type INTEGER NOT NULL);

-- Индекс: value_sort_time
CREATE INDEX IF NOT EXISTS n.value_sort_by_event_id_time ON value (event_id,time);

COMMIT TRANSACTION;
