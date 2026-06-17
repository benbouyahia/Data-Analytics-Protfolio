-- Migrate legacy installs: single-column PK (id) -> snapshot PK (id, extracted_at).
-- Safe on new installs: table is recreated with composite PK if needed.
ALTER TABLE raw.raw_crypto_data DROP CONSTRAINT IF EXISTS raw_crypto_data_pkey;

ALTER TABLE raw.raw_crypto_data ADD PRIMARY KEY (id, extracted_at);
