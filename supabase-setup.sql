-- CESAR MEDICAL AESTHETICS — Supabase setup. Run ONCE in SQL Editor (safe to re-run).
-- Security model:
--  * Visitors (anon) cannot read/insert/update/delete the table. They can only call submit_appointment(),
--    which validates input and always stores status = 'pending'.
--  * Only users listed in public.admins can read appointments and change their status.
--  * Nobody can add themselves to public.admins through the API (no insert policy, no grants).

-- 1. Administrators ---------------------------------------------------------
create table if not exists public.admins(
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now());
alter table public.admins enable row level security;
revoke all on public.admins from anon, authenticated;
grant select on public.admins to authenticated;
drop policy if exists admins_read_own on public.admins;
create policy admins_read_own on public.admins for select to authenticated
  using (user_id = (select auth.uid()));

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select exists(select 1 from public.admins where user_id = (select auth.uid())) $$;
revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- 2. Appointments -----------------------------------------------------------
create table if not exists public.appointments(
  id uuid primary key default gen_random_uuid(),
  customer_name text not null check (char_length(customer_name) between 2 and 120),
  phone text not null check (phone ~ '^\+?[0-9 ()\-.]{6,20}$'),
  email text check (email is null or (char_length(email) <= 200 and email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')),
  service text not null check (char_length(service) between 2 and 120),
  appointment_date date not null,
  appointment_time time not null,
  message text check (message is null or char_length(message) <= 1000),
  status text not null default 'pending' check (status in ('pending','confirmed','rejected','cancelled','completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now());
create index if not exists appt_when_idx on public.appointments(appointment_date, appointment_time);
create index if not exists appt_status_idx on public.appointments(status);

create or replace function public.touch_updated_at() returns trigger
language plpgsql set search_path = public as
$$ begin new.updated_at := now(); return new; end $$;
drop trigger if exists appt_touch on public.appointments;
create trigger appt_touch before update on public.appointments
  for each row execute function public.touch_updated_at();

alter table public.appointments enable row level security;
revoke all on public.appointments from anon, authenticated;
grant select on public.appointments to authenticated;
grant update (status) on public.appointments to authenticated;   -- admins can change ONLY the status

drop policy if exists appt_admin_select on public.appointments;
create policy appt_admin_select on public.appointments for select to authenticated
  using (public.is_admin());
drop policy if exists appt_admin_update on public.appointments;
create policy appt_admin_update on public.appointments for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- 3. Public booking function (the ONLY thing visitors can do) ---------------
create or replace function public.submit_appointment(
  p_name text, p_phone text, p_email text, p_service text,
  p_date date, p_time time, p_message text default null)
returns uuid language plpgsql security definer set search_path = public as
$$
declare v uuid;
begin
  if p_date is null or p_time is null or p_date < current_date - 1 then
    raise exception 'invalid date';
  end if;
  if exists(select 1 from public.appointments
            where phone = btrim(p_phone) and appointment_date = p_date
              and service = btrim(p_service) and status in ('pending','confirmed')) then
    raise exception 'duplicate request';
  end if;
  insert into public.appointments(customer_name, phone, email, service, appointment_date, appointment_time, message)
  values (btrim(p_name), btrim(p_phone), nullif(btrim(coalesce(p_email,'')),''), btrim(p_service),
          p_date, p_time, nullif(btrim(coalesce(p_message,'')),''))
  returning id into v;             -- status is never taken from the browser: it defaults to 'pending'
  return v;
end $$;
revoke all on function public.submit_appointment(text,text,text,text,date,time,text) from public;
grant execute on function public.submit_appointment(text,text,text,text,date,time,text) to anon, authenticated;

-- 4. Realtime (optional; respects the policies above) ----------------------
do $$ begin alter publication supabase_realtime add table public.appointments;
exception when others then null; end $$;

-- 5. FIRST ADMINISTRATOR ------------------------------------------------------
-- a) Dashboard > Authentication > Users > Add user (email + password, tick "Auto Confirm User").
-- b) Replace the email below, remove the leading "--", and run it in the SQL Editor:
-- insert into public.admins(user_id) select id from auth.users where email = 'YOU@EXAMPLE.COM';
