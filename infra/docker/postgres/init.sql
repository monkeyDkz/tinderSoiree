-- ============================================================================
-- TINDER SOIRÉE - SCHEMA PostgreSQL
-- Version: 1.0.0 MVP
-- ============================================================================

-- Extensions requises
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- TYPES ENUM
-- ============================================================================

CREATE TYPE user_gender AS ENUM ('male', 'female', 'non_binary', 'other');
CREATE TYPE orientation_type AS ENUM ('men', 'women', 'everyone');
CREATE TYPE event_status AS ENUM ('draft', 'live', 'closed', 'cancelled');
CREATE TYPE checkin_source AS ENUM ('nfc', 'qr', 'manual', 'deep_link');
CREATE TYPE swipe_action AS ENUM ('like', 'dislike');
CREATE TYPE user_role AS ENUM ('user', 'admin', 'super_admin');

-- ============================================================================
-- TABLE: users
-- ============================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Auth
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255),
    apple_id VARCHAR(255) UNIQUE,

    -- Profil
    first_name VARCHAR(100) NOT NULL,
    birth_date DATE NOT NULL,
    gender user_gender NOT NULL,
    orientation orientation_type NOT NULL DEFAULT 'everyone',
    bio TEXT,

    -- Photos (array de URLs S3, max 6)
    photos JSONB NOT NULL DEFAULT '[]'::jsonb,

    -- Rôle
    role user_role NOT NULL DEFAULT 'user',

    -- Metadata
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_verified BOOLEAN NOT NULL DEFAULT false,
    last_seen_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,

    -- Constraints
    CONSTRAINT check_birth_date CHECK (birth_date <= CURRENT_DATE - INTERVAL '18 years'),
    CONSTRAINT check_photos_limit CHECK (jsonb_array_length(photos) <= 6),
    CONSTRAINT check_auth_method CHECK (
        email IS NOT NULL OR phone IS NOT NULL OR apple_id IS NOT NULL
    )
);

-- Index users
CREATE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_phone ON users(phone) WHERE phone IS NOT NULL;
CREATE INDEX idx_users_apple_id ON users(apple_id) WHERE apple_id IS NOT NULL;
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = true;
CREATE INDEX idx_users_gender_orientation ON users(gender, orientation) WHERE is_active = true;

-- ============================================================================
-- TABLE: events
-- ============================================================================

CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Info événement
    name VARCHAR(255) NOT NULL,
    description TEXT,
    location_name VARCHAR(255) NOT NULL,
    location_address TEXT,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),

    -- Image de couverture
    cover_image_url TEXT,

    -- Timing
    start_at TIMESTAMP WITH TIME ZONE NOT NULL,
    end_at TIMESTAMP WITH TIME ZONE NOT NULL,

    -- Statut
    status event_status NOT NULL DEFAULT 'draft',

    -- Token de jointure
    join_token_secret VARCHAR(64) NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
    join_token_expires_hours INT NOT NULL DEFAULT 2,
    max_participants INT,

    -- Organisateur
    organizer_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT check_dates CHECK (end_at > start_at),
    CONSTRAINT check_token_expiry CHECK (join_token_expires_hours BETWEEN 1 AND 24)
);

-- Index events
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_organizer ON events(organizer_id);
CREATE INDEX idx_events_start_at ON events(start_at);
CREATE INDEX idx_events_status_dates ON events(status, start_at, end_at) WHERE status = 'live';

-- ============================================================================
-- TABLE: checkins
-- ============================================================================

CREATE TABLE checkins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,

    -- Timing
    joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    left_at TIMESTAMP WITH TIME ZONE,

    -- Source d'entrée
    source checkin_source NOT NULL,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Un user ne peut avoir qu'un seul checkin actif par event
    CONSTRAINT unique_active_checkin UNIQUE (user_id, event_id)
);

-- Index checkins
CREATE INDEX idx_checkins_event_active ON checkins(event_id, joined_at) WHERE left_at IS NULL;
CREATE INDEX idx_checkins_user ON checkins(user_id);
CREATE INDEX idx_checkins_event_user ON checkins(event_id, user_id);

-- ============================================================================
-- TABLE: swipes
-- ============================================================================

CREATE TABLE swipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,

    action swipe_action NOT NULL,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Un user ne peut swiper qu'une fois une autre personne par event
    CONSTRAINT unique_swipe UNIQUE (from_user_id, to_user_id, event_id),
    CONSTRAINT no_self_swipe CHECK (from_user_id != to_user_id)
);

-- Index swipes
CREATE INDEX idx_swipes_to_from_event ON swipes(to_user_id, from_user_id, event_id) WHERE action = 'like';
CREATE INDEX idx_swipes_from_event ON swipes(from_user_id, event_id);
CREATE INDEX idx_swipes_event ON swipes(event_id);

-- ============================================================================
-- TABLE: matches
-- ============================================================================

CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Toujours user1_id < user2_id pour éviter les doublons
    user1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,

    -- Statut du chat
    is_active BOOLEAN NOT NULL DEFAULT true,

    -- Dernier message
    last_message_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Un seul match possible entre 2 users pour un event
    CONSTRAINT unique_match UNIQUE (user1_id, user2_id, event_id),
    CONSTRAINT ordered_users CHECK (user1_id < user2_id)
);

-- Index matches
CREATE INDEX idx_matches_user1 ON matches(user1_id) WHERE is_active = true;
CREATE INDEX idx_matches_user2 ON matches(user2_id) WHERE is_active = true;
CREATE INDEX idx_matches_event ON matches(event_id);
CREATE INDEX idx_matches_last_message ON matches(last_message_at DESC NULLS LAST) WHERE is_active = true;

-- ============================================================================
-- TABLE: messages
-- ============================================================================

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Contenu
    content TEXT NOT NULL,

    -- Statut lecture
    read_at TIMESTAMP WITH TIME ZONE,

    -- Type de message
    message_type VARCHAR(20) NOT NULL DEFAULT 'text',

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT check_content_not_empty CHECK (length(trim(content)) > 0)
);

-- Index messages
CREATE INDEX idx_messages_match ON messages(match_id, created_at DESC);
CREATE INDEX idx_messages_unread ON messages(match_id, sender_id) WHERE read_at IS NULL;

-- ============================================================================
-- TABLE: refresh_tokens
-- ============================================================================

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    token_hash VARCHAR(64) NOT NULL,

    device_info JSONB DEFAULT '{}'::jsonb,

    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT unique_token UNIQUE (token_hash)
);

-- Index refresh_tokens
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id) WHERE revoked_at IS NULL;
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens(expires_at) WHERE revoked_at IS NULL;

-- ============================================================================
-- TABLE: reports
-- ============================================================================

CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reported_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_id UUID REFERENCES events(id) ON DELETE SET NULL,

    reason VARCHAR(50) NOT NULL,
    description TEXT,

    -- Traitement
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Index reports
CREATE INDEX idx_reports_status ON reports(status) WHERE status = 'pending';
CREATE INDEX idx_reports_reported ON reports(reported_user_id);

-- ============================================================================
-- TABLE: device_tokens (Push Notifications)
-- ============================================================================

CREATE TYPE device_platform AS ENUM ('ios', 'android', 'web');

CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    token VARCHAR(512) NOT NULL,
    platform device_platform NOT NULL,

    is_active BOOLEAN NOT NULL DEFAULT true,
    last_used_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Un token unique par user
    CONSTRAINT unique_user_token UNIQUE (user_id, token)
);

-- Index device_tokens
CREATE INDEX idx_device_tokens_user ON device_tokens(user_id) WHERE is_active = true;
CREATE INDEX idx_device_tokens_token ON device_tokens(token);

-- Trigger updated_at
CREATE TRIGGER update_device_tokens_updated_at
    BEFORE UPDATE ON device_tokens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- FONCTIONS ET TRIGGERS
-- ============================================================================

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_events_updated_at
    BEFORE UPDATE ON events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Fonction pour mettre à jour last_message_at sur match
CREATE OR REPLACE FUNCTION update_match_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE matches
    SET last_message_at = NEW.created_at
    WHERE id = NEW.match_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_match_last_message_trigger
    AFTER INSERT ON messages
    FOR EACH ROW EXECUTE FUNCTION update_match_last_message();

-- ============================================================================
-- VUES UTILITAIRES
-- ============================================================================

-- Vue: Checkins actifs
CREATE VIEW active_checkins AS
SELECT
    c.*,
    u.first_name,
    u.gender,
    u.orientation,
    u.photos,
    u.bio,
    u.birth_date
FROM checkins c
JOIN users u ON c.user_id = u.id
WHERE c.left_at IS NULL
  AND u.is_active = true;
