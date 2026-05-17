-- Flood Finder — sensor_readings table
-- Paste this whole file into Supabase → SQL Editor → New query → Run.
-- Safe to re-run: uses CREATE TABLE IF NOT EXISTS.

create table if not exists public.sensor_readings (
  id            bigserial primary key,
  created_at    timestamptz not null default now(),

  -- environment
  temperature   double precision,        -- °C
  pressure      double precision,        -- hPa
  distance_cm   double precision,        -- raw ultrasonic distance to surface
  tilt_angle    double precision,        -- degrees off vertical (from MPU-6050)

  -- location
  gps_lat       double precision,
  gps_lng       double precision,

  -- power
  battery_voltage double precision,
  battery_percent integer,
  is_charging     boolean default false,

  -- radio
  tx_mode       text,                    -- 'lora' or 'wifi'
  lora_rssi     integer,                 -- dBm, nullable when tx_mode='wifi'
  wifi_rssi     integer,                 -- dBm, nullable when tx_mode='lora'

  -- test fixture: lets the seeder mark rows it inserted, so the
  -- "Wipe test data" button (or this query) can clean them up later:
  --   delete from public.sensor_readings where test_run = true;
  test_run      boolean default false
);

create index if not exists idx_sensor_readings_created_at_desc
  on public.sensor_readings (created_at desc);

-- Row-Level Security: enable, then add explicit policies for the
-- dashboard (anon select) and the device/seeder (anon insert).
alter table public.sensor_readings enable row level security;

drop policy if exists "sensor_readings_anon_select" on public.sensor_readings;
create policy "sensor_readings_anon_select"
  on public.sensor_readings
  for select
  to anon
  using (true);

drop policy if exists "sensor_readings_anon_insert" on public.sensor_readings;
create policy "sensor_readings_anon_insert"
  on public.sensor_readings
  for insert
  to anon
  with check (true);

-- Allow anon DELETE only for rows tagged test_run=true (lets the
-- seeder's Wipe button work without exposing the full table to delete).
drop policy if exists "sensor_readings_anon_delete_testrun" on public.sensor_readings;
create policy "sensor_readings_anon_delete_testrun"
  on public.sensor_readings
  for delete
  to anon
  using (test_run = true);

-- Trigger PostgREST to reload its schema cache so the new table shows up immediately
notify pgrst, 'reload schema';
