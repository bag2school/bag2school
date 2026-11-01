-- Bag2School V13.9
-- Family join requests

create table if not exists public.family_join_requests (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  invitation_code_id uuid references public.family_invitation_codes(id) on delete set null,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint family_join_requests_status_check
    check (status in ('pending', 'approved', 'rejected'))
);

create index if not exists family_join_requests_family_id_idx
  on public.family_join_requests(family_id);

create index if not exists family_join_requests_profile_id_idx
  on public.family_join_requests(profile_id);

create index if not exists family_join_requests_invitation_code_id_idx
  on public.family_join_requests(invitation_code_id);

alter table public.family_join_requests enable row level security;

drop policy if exists family_join_requests_select_own on public.family_join_requests;
create policy family_join_requests_select_own
on public.family_join_requests
for select
to authenticated
using (
  profile_id = (select auth.uid())
);

drop policy if exists family_join_requests_insert_own on public.family_join_requests;
create policy family_join_requests_insert_own
on public.family_join_requests
for insert
to authenticated
with check (
  profile_id = (select auth.uid())
);

drop policy if exists family_join_requests_update_owner on public.family_join_requests;
create policy family_join_requests_update_owner
on public.family_join_requests
for update
to authenticated
using (
  public.is_family_owner(family_id)
)
with check (
  public.is_family_owner(family_id)
);

grant select, insert on public.family_join_requests to authenticated;
grant update on public.family_join_requests to authenticated;