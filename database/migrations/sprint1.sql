-- Ajout des colonnes pour la table bracelets
ALTER TABLE bracelets
ADD COLUMN IF NOT EXISTS device_type VARCHAR(50),
ADD COLUMN IF NOT EXISTS platform VARCHAR(50),
ADD COLUMN IF NOT EXISTS provisioned BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS refresh_token VARCHAR(255);

-- Création de la table sos_alerts
CREATE TABLE IF NOT EXISTS sos_alerts (
    id_sos SERIAL PRIMARY KEY,
    bracelet_id INT REFERENCES bracelets(id_bracelet) ON DELETE CASCADE,
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    severity VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
