-- ============================================================================
-- SEED DATA: Initial Yuura Information
-- ============================================================================

-- Yuura's basic info
INSERT INTO talents (name, handle, youtube_id, debut_date, agency, description)
VALUES (
    'Yuura Yozakura',
    '@YuuraYozakura',
    'UCrmtSeYObZJNG6OIC7Pw-_A',
    '2022-09-27',
    'おや、よく来たの。わしは夜桜優空じゃ。以後、お見知り置きよ! よこそ、夜桜旅館へ！
    Selamat datang di penginapanku semua, namaku Yuura！ Senang bertemu kalian！'
);

-- Insert initial milestone targets
-- These will be updated with predictions once we have data
INSERT INTO milestones (talent_id, target_subs, status)
SELECT
    id,
    target,
    'pending'
FROM talents, (VALUES
    (25000),   -- Very close!
    (30000),   -- Short-term
    (40000),   -- Medium-term
    (50000),   -- Major goal
    (67000),   -- Funny goal
    (75000),   -- Long-term
    (100000)   -- Dream goal
) AS t(target)
WHERE name = 'Yuura Yozakura';

-- Verify data was inserted
SELECT * FROM talents;
SELECT * FROM milestones;
