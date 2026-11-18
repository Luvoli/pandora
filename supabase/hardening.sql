-- Durcissement (appliqué le 19/11/2026) : contrôle d'accès hors API, droits minimaux, refus explicite
-- 1) la fonction de contrôle d'accès sort du schéma exposé par l'API (plus appelable via /rpc)
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;
create or replace function private.is_member() returns boolean
  language sql stable security definer set search_path = ''
  as $$ select exists (select 1 from public.allowed_emails a where a.email = lower(coalesce(auth.jwt()->>'email','')) ) $$;
revoke all on function private.is_member() from public, anon;
grant execute on function private.is_member() to authenticated;
drop policy if exists items_all on public.items;
create policy items_all on public.items for all to authenticated using (private.is_member()) with check (private.is_member());
drop policy if exists lists_all on public.lists;
create policy lists_all on public.lists for all to authenticated using (private.is_member()) with check (private.is_member());
drop function if exists public.is_member();
-- 2) fonction de mise à jour de date : chemin fixe, pas exécutable de l'extérieur
alter function public.touch() set search_path = '';
revoke all on function public.touch() from public, anon, authenticated;
-- 3) droits inutiles (TRUNCATE ignore la sécurité par ligne) retirés partout
revoke truncate, trigger, references on all tables in schema public from anon, authenticated;
revoke all on public.allowed_emails from anon, authenticated;
revoke all on public.items, public.lists from anon;
-- 4) les futures tables ne seront pas ouvertes par défaut
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on functions from anon;
alter default privileges in schema public revoke execute on functions from public;
drop policy if exists allowed_emails_none on public.allowed_emails;
create policy allowed_emails_none on public.allowed_emails for all to authenticated, anon using (false) with check (false);
alter function public.only_allowed_signup() set search_path = '';
