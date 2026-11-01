-- Bag2School V13.9
-- Profile identity and family relationship.
--
-- profiles:
--   gender          = user identity
--   preferred_title = how Bagi addresses the user
--
-- family_members:
--   relationship    = relationship within the family

alter table public.profiles
  add column if not exists gender text;

alter table public.profiles
  add column if not exists preferred_title text;

alter table public.family_members
  add column if not exists relationship text;