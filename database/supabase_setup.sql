-- Pharmory Database Setup for Supabase
-- Run this script in your Supabase SQL editor

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable full text search for Turkish if available
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create medications table
CREATE TABLE IF NOT EXISTS medications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT DEFAULT '',
    usage TEXT DEFAULT '',
    dosage TEXT DEFAULT '',
    side_effects TEXT[] DEFAULT '{}',
    warnings TEXT[] DEFAULT '{}',
    indications TEXT[] DEFAULT '{}',
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_verified BOOLEAN DEFAULT FALSE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_medications_name ON medications (name);
CREATE INDEX IF NOT EXISTS idx_medications_name_trgm ON medications USING gin(name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_medications_created_at ON medications (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_medications_updated_at ON medications (updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_medications_verified ON medications (is_verified);

-- Create full text search index for Turkish (if available)
CREATE INDEX IF NOT EXISTS idx_medications_name_fts ON medications USING gin(to_tsvector('turkish', name));
CREATE INDEX IF NOT EXISTS idx_medications_description_fts ON medications USING gin(to_tsvector('turkish', description));

-- Create feedback table for tracking user feedback
CREATE TABLE IF NOT EXISTS medication_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medication_id UUID REFERENCES medications(id) ON DELETE CASCADE,
    feedback_type TEXT NOT NULL CHECK (feedback_type IN ('incorrect', 'incomplete', 'outdated', 'other')),
    additional_info TEXT,
    user_ip INET,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for feedback queries
CREATE INDEX IF NOT EXISTS idx_feedback_medication_id ON medication_feedback (medication_id);
CREATE INDEX IF NOT EXISTS idx_feedback_created_at ON medication_feedback (created_at DESC);

-- Create search analytics table (optional)
CREATE TABLE IF NOT EXISTS search_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    search_term TEXT NOT NULL,
    found BOOLEAN DEFAULT FALSE,
    user_ip INET,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for analytics
CREATE INDEX IF NOT EXISTS idx_analytics_search_term ON search_analytics (search_term);
CREATE INDEX IF NOT EXISTS idx_analytics_created_at ON search_analytics (created_at DESC);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_medications_updated_at ON medications;
CREATE TRIGGER update_medications_updated_at
    BEFORE UPDATE ON medications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to search medications with fuzzy matching
CREATE OR REPLACE FUNCTION search_medications(search_term TEXT, limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    usage TEXT,
    dosage TEXT,
    side_effects TEXT[],
    warnings TEXT[],
    indications TEXT[],
    image_url TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    is_verified BOOLEAN,
    similarity_score REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.name,
        m.description,
        m.usage,
        m.dosage,
        m.side_effects,
        m.warnings,
        m.indications,
        m.image_url,
        m.created_at,
        m.updated_at,
        m.is_verified,
        similarity(m.name, search_term) as similarity_score
    FROM medications m
    WHERE 
        m.name ILIKE '%' || search_term || '%'
        OR similarity(m.name, search_term) > 0.3
        OR to_tsvector('turkish', m.name) @@ plainto_tsquery('turkish', search_term)
    ORDER BY 
        CASE 
            WHEN m.name ILIKE search_term || '%' THEN 1
            WHEN m.name ILIKE '%' || search_term || '%' THEN 2
            ELSE 3
        END,
        similarity(m.name, search_term) DESC,
        m.updated_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Insert some sample medications for testing (Turkish medications)
INSERT INTO medications (name, description, usage, dosage, side_effects, warnings, indications, is_verified) VALUES
    (
        'Parol',
        'Ağrı kesici ve ateş düşürücü ilaç. Parasetamol etken maddesi içerir.',
        'Hafif ve orta şiddetteki ağrılar, ateş düşürücü olarak kullanılır.',
        'Yetişkinlerde günde 3-4 kez, 500-1000 mg. Maksimum günlük doz 4000 mg.',
        ARRAY['Mide bulantısı', 'Alerjik reaksiyonlar', 'Karaciğer hasarı (yüksek dozlarda)'],
        ARRAY['Karaciğer hastalığı olanlarda dikkatli kullanılmalı', 'Alkol ile birlikte kullanılmamalı', 'Hamilelik ve emzirme döneminde doktor kontrolünde kullanılmalı'],
        ARRAY['Baş ağrısı', 'Diş ağrısı', 'Kas ağrıları', 'Ateş', 'Soğuk algınlığı semptomları'],
        true
    ),
    (
        'Aspirin',
        'Asetilsalisilik asit içeren ağrı kesici, ateş düşürücü ve kan sulandırıcı ilaç.',
        'Ağrı, ateş ve inflamasyon tedavisinde, kan pıhtılaşmasını önlemek için kullanılır.',
        'Ağrı için: 500-1000 mg, 4-6 saatte bir. Kalp koruma için: günlük 75-100 mg.',
        ARRAY['Mide irritasyonu', 'Mide kanaması', 'Kulak çınlaması', 'Alerjik reaksiyonlar'],
        ARRAY['Mide ülseri olanlarda kullanılmamalı', '18 yaş altında grip ve suçiçeği için kullanılmamalı', 'Kan sulandırıcı ilaç kullananlar dikkatli olmalı'],
        ARRAY['Baş ağrısı', 'Kas ağrıları', 'Kalp krizi korunması', 'İnme korunması', 'Ateş'],
        true
    )
ON CONFLICT DO NOTHING;

-- Create RLS (Row Level Security) policies if needed
-- ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE medication_feedback ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE search_analytics ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions for anon and authenticated users
GRANT SELECT ON medications TO anon, authenticated;
GRANT INSERT, UPDATE ON medications TO authenticated;
GRANT ALL ON medication_feedback TO anon, authenticated;
GRANT ALL ON search_analytics TO anon, authenticated;

-- Grant usage on sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Create API helper functions
CREATE OR REPLACE FUNCTION get_medication_by_name(med_name TEXT)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    usage TEXT,
    dosage TEXT,
    side_effects TEXT[],
    warnings TEXT[],
    indications TEXT[],
    image_url TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    is_verified BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id, m.name, m.description, m.usage, m.dosage,
        m.side_effects, m.warnings, m.indications, m.image_url,
        m.created_at, m.updated_at, m.is_verified
    FROM medications m
    WHERE LOWER(m.name) = LOWER(med_name)
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to log search analytics
CREATE OR REPLACE FUNCTION log_search(term TEXT, found_result BOOLEAN, user_ip_addr INET DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
    INSERT INTO search_analytics (search_term, found, user_ip)
    VALUES (term, found_result, user_ip_addr);
END;
$$ LANGUAGE plpgsql;

-- Create a view for medication statistics
CREATE OR REPLACE VIEW medication_stats AS
SELECT 
    COUNT(*) as total_medications,
    COUNT(*) FILTER (WHERE is_verified = true) as verified_medications,
    COUNT(*) FILTER (WHERE is_verified = false) as unverified_medications,
    MAX(updated_at) as last_updated
FROM medications;

GRANT SELECT ON medication_stats TO anon, authenticated;

-- Setup complete
SELECT 'Pharmory database setup completed successfully!' as message;
