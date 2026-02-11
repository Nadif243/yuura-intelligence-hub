-- ============================================================================
-- SEED DATA: Initial Yuura Information
-- ============================================================================
-- Run this AFTER schema.sql to populate initial talent data
-- ============================================================================

-- Insert Yuura's basic info
-- TODO: Replace placeholder values with actual data from her channel
INSERT INTO talents (name, handle, youtube_id, debut_date, description)
VALUES (
    'Yuura Yozakura',
    '@YuuraYozakura',
    'UC0ZYul2i5OcyKbdKB2v1O2w',-- externalId: UCrmtSeYObZJNG6OIC7Pw-_A
    '2022-09-27',
    'おや、よく来たの。わしは夜桜優空じゃ。以後、お見知り置きよ! よこそ、夜桜旅館へ！
    Selamat datang di penginapanku semua, namaku Yuura！ Senang bertemu kalian！'
);

-- Insert initial milestone targets
-- These will be updated with predictions once you have data
INSERT INTO milestones (talent_id, target_subs, status)
SELECT
    id,
    target,
    'pending'
FROM talents, (VALUES (50000), (75000), (100000), (150000), (200000)) AS t(target)
WHERE name = 'Yuura Yozakura';

-- Verify data was inserted
SELECT * FROM talents;
SELECT * FROM milestones;
