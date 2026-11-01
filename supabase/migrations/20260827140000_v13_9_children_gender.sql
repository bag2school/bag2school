-- =========================================================
-- Bag2School V13.9-P.3.1
-- Child gender foundation
--
-- Used for:
-- - Default child avatar selection
-- - Gender-aware UI presentation
--
-- Avatar upload remains restricted to:
-- Owner + Parent/Guardian
-- =========================================================

alter table public.children
add column if not exists gender text;