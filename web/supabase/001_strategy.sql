-- Additive migration: preserve the connected project's existing profile fields/policies.
alter table public.profiles add column if not exists iron_quality text not null default 'medium' check (iron_quality in ('low','medium','high'));
create table public.saves (user_id uuid primary key references auth.users(id) on delete cascade,game_state jsonb not null check (jsonb_typeof(game_state)='object' and octet_length(game_state::text)<200000),updated_at timestamptz not null default now());
create table public.leaderboard (user_id uuid primary key references auth.users(id) on delete cascade,hero_name text not null default '' check (length(hero_name)<=48),score bigint not null default 0 check(score>=0),days_survived integer not null default 1 check(days_survived>=1));
alter table public.saves enable row level security;
alter table public.leaderboard enable row level security;
create policy "iron_own_saves" on public.saves for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy "iron_public_rankings" on public.leaderboard for select to anon,authenticated using (true);
create policy "iron_insert_ranking" on public.leaderboard for insert to authenticated with check ((select auth.uid())=user_id);
create policy "iron_update_ranking" on public.leaderboard for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy "iron_delete_ranking" on public.leaderboard for delete to authenticated using ((select auth.uid())=user_id);
create policy "iron_create_own_profile" on public.profiles for insert to authenticated with check ((select auth.uid())=id);
grant select,insert,update,delete on public.saves,public.leaderboard to authenticated;
grant select on public.leaderboard to anon;
create index iron_leaderboard_score on public.leaderboard(score desc);
create function public.iron_save_timestamp() returns trigger language plpgsql set search_path=public as $$ begin NEW.updated_at=now(); return NEW; end; $$;
create trigger iron_save_timestamp before update on public.saves for each row execute function public.iron_save_timestamp();
