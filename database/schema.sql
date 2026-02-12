-- ============================================================================
-- YUURA INTELLIGENCE HUB - DATABASE SCHEMA
-- ============================================================================
-- Purpose: Track Yuura's growth, content, lore, and song performances
-- Database: PostgreSQL (Supabase)
-- Author: Nanafi
-- Created: 2026-02-12
-- ============================================================================

-- Enable UUID extension (Supabase has this by default, but just in case)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- TABLE 1: TALENTS
-- ============================================================================
-- Purpose: Static identity information about the VTuber
-- Frequency: Rarely changes (only on debut or rebranding/redebut)
-- ============================================================================

CREATE TABLE talents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    handle TEXT UNIQUE NOT NULL, -- Twitter/YouTube handle (e.g., @YuuraYozakura)
    youtube_id TEXT UNIQUE NOT NULL, -- Channel ID from YouTube
    debut_date DATE,
    agency TEXT DEFAULT 'Project Livium', -- Her agency
    avatar_url TEXT, -- Profile picture URL
    banner_url TEXT, -- Channel banner URL
    description TEXT, -- About section
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- TABLE 2: SNAPSHOTS
-- ============================================================================
-- Purpose: Time-series channel statistics (the "position" data for velocity math)
-- Frequency: Every 6 hours via cron job
-- Usage: Calculate growth velocity, acceleration, predict milestones
-- ============================================================================

CREATE TABLE snapshots (
    id BIGSERIAL PRIMARY KEY,
    talent_id UUID REFERENCES talents(id) ON DELETE CASCADE,
    sub_count INTEGER NOT NULL,
    view_count BIGINT NOT NULL,
    video_count INTEGER NOT NULL,
    recorded_at TIMESTAMPTZ DEFAULT NOW(),

    -- Prevent duplicate snapshots for the same talent at the same time
    UNIQUE(talent_id, recorded_at)
);

-- Index for time-range queries (e.g., "get last 30 days of snapshots")
CREATE INDEX idx_snapshots_time ON snapshots(talent_id, recorded_at DESC);

-- ============================================================================
-- TABLE 3: CONTENT
-- ============================================================================
-- Purpose: Catalog of all videos/streams (the "lore" sources)
-- Frequency: New videos fetched daily via API
-- ============================================================================

CREATE TABLE content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    talent_id UUID REFERENCES talents(id) ON DELETE CASCADE,
    youtube_video_id TEXT UNIQUE NOT NULL, -- e.g., "dQw4w9WgXcQ"
    title TEXT NOT NULL,
    description TEXT,
    published_at TIMESTAMPTZ NOT NULL,

    -- FORMAT: How was it delivered?
    format TEXT CHECK (format IN ('stream', 'vod', 'short', 'premiere', 'clip')) NOT NULL,

    -- CATEGORY: What was it about? (broad categorization)
    primary_category TEXT CHECK (primary_category IN (
        'music',        -- Karaoke, original songs, covers
        'gaming',       -- Game streams
        'chatting',     -- Free talk, zatsudan
        'special',      -- Menggebu, BTS, special series
        'milestone',    -- Celebrations, anniversaries, important announcements
        'collab',       -- With other VTubers
        'shorts'        -- If she does YouTube Shorts differently than regular content
    )),

    -- Language: Primary language of the stream (important for multilingual content)
    primary_language TEXT CHECK (primary_language IN ('JP', 'ID', 'EN', 'mixed')),

    duration_seconds INTEGER,
    thumbnail_url TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for finding recent content
CREATE INDEX idx_content_published ON content(talent_id, published_at DESC);
-- Index for filtering by category
CREATE INDEX idx_content_category ON content(primary_category) WHERE primary_category IS NOT NULL;
-- Index for filtery by language
CREATE INDEX idx_content_language ON content(primary_language) WHERE primary_language IS NOT NULL;

-- ============================================================================
-- TABLE 4: CONTENT_METRICS
-- ============================================================================
-- Purpose: Track video performance over time (views/likes grow, this captures it)
-- Frequency: Daily updates via cron job
-- Usage: See which content performs best, track viral growth
-- ============================================================================

CREATE TABLE content_metrics (
    id BIGSERIAL PRIMARY KEY,
    content_id UUID REFERENCES content(id) ON DELETE CASCADE,
    view_count BIGINT NOT NULL,
    like_count INTEGER,
    comment_count INTEGER,

    -- Stream-specific metrics (NULL for non-streams)
    peak_ccv INTEGER, -- Peak concurrent viewers
    avg_ccv INTEGER,  -- Average concurrent viewers

    recorded_at TIMESTAMPTZ DEFAULT NOW()
    recorded_date DATE -- Automatically set from recorded_at
);

-- Add the unique constraint AFTER the table, using an index instead:
-- Use DATE type column instead of casting
ALTER TABLE content_metrics ADD COLUMN recorded_date DATE;

-- Update it automatically from recorded_at
CREATE OR REPLACE FUNCTION set_recorded_date()
RETURNS TRIGGER AS $$
BEGIN
    NEW.recorded_date = NEW.recorded_at::date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE TRIGGER set_content_metrics_date
    BEFORE INSERT OR UPDATE ON content_metrics
    FOR EACH ROW EXECUTE FUNCTION set_recorded_date();

-- Now we can create the unique constraint
-- One snapshot per content per day
CREATE UNIQUE INDEX idx_metrics_unique_daily
    ON content_metrics(content_id, recorded_date);

-- Index for time-series queries per video
CREATE INDEX idx_metrics_content_time ON content_metrics(content_id, recorded_at DESC);

-- ============================================================================
-- TABLE 5: SONGS
-- ============================================================================
-- Purpose: Canonical list of all songs (originals + covers)
-- Frequency: Manually added when new song discovered
-- ============================================================================

CREATE TABLE songs (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    original_artist TEXT, -- NULL if Yuura's original
    is_original BOOLEAN DEFAULT FALSE, -- TRUE if Yuura wrote it

    -- Metadata
    genre TEXT,
    language TEXT CHECK (language IN ('JP', 'ID', 'EN', 'other')),

    first_sung_at TIMESTAMPTZ, -- When Yuura first sang this song

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prevent duplicate songs (case-insensitive check on title + artist)
CREATE UNIQUE INDEX idx_songs_unique
    ON songs(title, COALESCE(original_artist, ''));

-- Index for searching songs by title
CREATE INDEX idx_songs_title_search ON songs USING gin(to_tsvector('simple', title));

-- ============================================================================
-- TABLE 6: SONG_PERFORMANCES
-- ============================================================================
-- Purpose: Track every time a song was sung (junction table: songs ↔ content)
-- Frequency: Manually added as you tag streams
-- Usage: "How many times has she sung this?", "What songs in this stream?"
-- ============================================================================

CREATE TABLE song_performances (
    id BIGSERIAL PRIMARY KEY,
    song_id BIGINT REFERENCES songs(id) ON DELETE CASCADE,
    content_id UUID REFERENCES content(id) ON DELETE CASCADE,

    timestamp_in_video INTEGER, -- Seconds into the video (optional)

    -- Your quality assessment
    performance_quality TEXT CHECK (performance_quality IN (
        'flawless',  -- Perfect execution
        'decent',    -- Good performance
        'for_fun',   -- Casual, not serious
        'practice',  -- Practicing new song
        'emotional', -- Really felt it, even if not perfect
        'unrated'    -- Haven't assessed yet
    )) DEFAULT 'unrated',

    notes TEXT, -- Optional context (e.g., "First time singing this", "Requested by chat")

    performed_at TIMESTAMPTZ, -- Calculated from content.published_at + timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index: "All performances of song X"
CREATE INDEX idx_performances_song ON song_performances(song_id, performed_at DESC);

-- Index: "All songs in stream Y"
CREATE INDEX idx_performances_content ON song_performances(content_id);

-- ============================================================================
-- TABLE 7: LORE_TAGS
-- ============================================================================
-- Purpose: Metadata and lore extraction from content
-- Frequency: Manual initially, semi-automated later
-- Usage: Searchable lore database, content categorization
-- ============================================================================

CREATE TABLE lore_tags (
    id BIGSERIAL PRIMARY KEY,
    content_id UUID REFERENCES content(id) ON DELETE CASCADE,

    -- Type of tag
    tag_type TEXT CHECK (tag_type IN (
        'series',     -- Menggebu, Popping
        'game',       -- Minecraft, Valorant, etc.
        'collab',     -- Squad Kocak, individual collab partners
        'topic',      -- General subject matter
        'lore',       -- Project Livium worldbuilding, character background
        'milestone',  -- Subscriber goals, anniversaries
        'mood',       -- Chill stream, high energy, emotional, etc.
        'reference'   -- References to other content/creators
    )) NOT NULL,

    tag_value TEXT NOT NULL, -- e.g., 'Project Livium', 'Minecraft', 'anniversary'

    timestamp_in_video INTEGER, -- Where in video this appears (optional)

    -- How was this tag created?
    extraction_method TEXT CHECK (extraction_method IN (
        'manual',    -- You tagged it
        'keyword',   -- Script found keyword in title/description
        'ai',        -- AI extraction from transcript
        'community'  -- Submitted by fans (future feature)
    )) DEFAULT 'manual',

    confidence_score FLOAT CHECK (confidence_score BETWEEN 0 AND 1), -- For AI extractions

    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index: "All tags of type X"
CREATE INDEX idx_lore_type ON lore_tags(tag_type, tag_value);
-- Index: "All tags for content Y"
CREATE INDEX idx_lore_content ON lore_tags(content_id);
-- Full-text search on tag values (for searching lore)
CREATE INDEX idx_lore_search ON lore_tags USING gin(to_tsvector('english', tag_value));

-- ============================================================================
-- TABLE 8: MILESTONES
-- ============================================================================
-- Purpose: Track subscriber goals and predictions
-- Frequency: Updated when predictions recalculated
-- Usage: "When will she hit 100K?", milestone countdown
-- ============================================================================

CREATE TABLE milestones (
    id BIGSERIAL PRIMARY KEY,
    talent_id UUID REFERENCES talents(id) ON DELETE CASCADE,
    target_subs INTEGER NOT NULL,

    status TEXT CHECK (status IN (
        'pending',    -- Haven't reached it yet
        'predicted',  -- Have a prediction for it
        'achieved'    -- Already hit this milestone
    )) DEFAULT 'pending',

    predicted_date DATE, -- When we think it'll be reached
    prediction_confidence FLOAT, -- How confident we are (based on R² or similar)

    achieved_at TIMESTAMPTZ, -- Actual timestamp when reached

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Each milestone target should be unique per talent
CREATE UNIQUE INDEX idx_milestones_unique
    ON milestones(talent_id, target_subs);

-- Index for finding next milestone
CREATE INDEX idx_milestones_pending ON milestones(talent_id, target_subs)
    WHERE status IN ('pending', 'predicted');

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables that have updated_at
CREATE TRIGGER update_talents_updated_at BEFORE UPDATE ON talents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_content_updated_at BEFORE UPDATE ON content
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_songs_updated_at BEFORE UPDATE ON songs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_milestones_updated_at BEFORE UPDATE ON milestones
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
