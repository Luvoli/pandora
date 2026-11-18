create table if not exists public.lists (
  id text primary key,
  state jsonb not null default '{}'::jsonb,
  summary jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by text,
  seed jsonb -- contenu de départ des listes (Paris, Monde), chargé après connexion
);
alter table public.lists enable row level security;
drop policy if exists lists_all on public.lists;
create policy lists_all on public.lists for all to authenticated using (public.is_member()) with check (public.is_member());
grant select, insert, update, delete on public.lists to authenticated;
grant all on public.lists to service_role;
drop trigger if exists lists_touch on public.lists;
create trigger lists_touch before update on public.lists for each row execute function public.touch();
alter table public.lists replica identity full;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and tablename='lists') then
    alter publication supabase_realtime add table public.lists;
  end if;
end $$;
-- Le contenu (listes, prénoms) est ajouté directement dans la base, jamais dans ce dépôt.
