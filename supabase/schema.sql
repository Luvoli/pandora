create table if not exists public.items (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);
create table if not exists public.allowed_emails (email text primary key);
-- les adresses autorisées sont ajoutées directement dans la base, jamais dans ce dépôt public
-- insert into public.allowed_emails values ('…'),('…');
alter table public.allowed_emails enable row level security;

create or replace function public.is_member() returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.allowed_emails where email = lower(coalesce(auth.jwt()->>'email','')));
$$;

alter table public.items enable row level security;
drop policy if exists items_all on public.items;
create policy items_all on public.items for all to authenticated using (public.is_member()) with check (public.is_member());

-- seules les deux adresses peuvent créer un compte
create or replace function public.only_allowed_signup() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not exists(select 1 from public.allowed_emails where email = lower(new.email)) then
    raise exception 'Adresse non autorisée';
  end if;
  return new;
end $$;
drop trigger if exists only_allowed_signup on auth.users;
create trigger only_allowed_signup before insert on auth.users for each row execute function public.only_allowed_signup();

create or replace function public.touch() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end $$;
drop trigger if exists items_touch on public.items;
create trigger items_touch before update on public.items for each row execute function public.touch();

alter table public.items replica identity full;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and tablename='items') then
    alter publication supabase_realtime add table public.items;
  end if;
end $$;
-- petite table pour le ping anti-pause (lisible par tous, sans données)
create table if not exists public.ping (id int primary key, at timestamptz default now());
insert into public.ping values (1) on conflict do nothing;
alter table public.ping enable row level security;
drop policy if exists ping_read on public.ping;
create policy ping_read on public.ping for select to anon, authenticated using (true);
