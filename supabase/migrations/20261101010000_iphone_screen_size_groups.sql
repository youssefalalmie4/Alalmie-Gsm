-- Apple iPhone display diagonal cohorts for screen protector discovery.
-- Primary source for current cohorts: https://support.apple.com/en-us/108044
-- Shared diagonal is a size hint only, not a guarantee that a protector fits.
insert into public.protector_groups (group_code, brand, family, joker, source_snapshot)
values
  ('APPLE-SIZE-3.5', 'Apple', 'iPhone (1st generation),iPhone 3G,iPhone 3GS,iPhone 4,iPhone 4s', '', date '2026-11-01'),
  ('APPLE-SIZE-4.0', 'Apple', 'iPhone 5,iPhone 5c,iPhone 5s,iPhone SE (1st generation)', '', date '2026-11-01'),
  ('APPLE-SIZE-4.7', 'Apple', 'iPhone 6,iPhone 6s,iPhone 7,iPhone 8,iPhone SE (2nd generation),iPhone SE (3rd generation)', '', date '2026-11-01'),
  ('APPLE-SIZE-5.42', 'Apple', 'iPhone 12 mini,iPhone 13 mini', '', date '2026-11-01'),
  ('APPLE-SIZE-5.5', 'Apple', 'iPhone 6 Plus,iPhone 6s Plus,iPhone 7 Plus,iPhone 8 Plus', '', date '2026-11-01'),
  ('APPLE-SIZE-5.85', 'Apple', 'iPhone X,iPhone XS,iPhone 11 Pro', '', date '2026-11-01'),
  ('APPLE-SIZE-6.06', 'Apple', 'iPhone XR,iPhone 11,iPhone 12,iPhone 12 Pro,iPhone 13,iPhone 13 Pro,iPhone 14,iPhone 16e,iPhone 17e', '', date '2026-11-01'),
  ('APPLE-SIZE-6.12', 'Apple', 'iPhone 14 Pro,iPhone 15,iPhone 15 Pro,iPhone 16', '', date '2026-11-01'),
  ('APPLE-SIZE-6.27', 'Apple', 'iPhone 16 Pro,iPhone 17,iPhone 17 Pro', '', date '2026-11-01'),
  ('APPLE-SIZE-6.46', 'Apple', 'iPhone XS Max,iPhone 11 Pro Max', '', date '2026-11-01'),
  ('APPLE-SIZE-6.55', 'Apple', 'iPhone Air', '', date '2026-11-01'),
  ('APPLE-SIZE-6.68', 'Apple', 'iPhone 12 Pro Max,iPhone 13 Pro Max,iPhone 14 Plus', '', date '2026-11-01'),
  ('APPLE-SIZE-6.69', 'Apple', 'iPhone 14 Pro Max,iPhone 15 Plus,iPhone 15 Pro Max,iPhone 16 Plus', '', date '2026-11-01'),
  ('APPLE-SIZE-6.86', 'Apple', 'iPhone 16 Pro Max,iPhone 17 Pro Max', '', date '2026-11-01')
on conflict (group_code, brand, family) do update
set joker = excluded.joker, source_snapshot = excluded.source_snapshot;
