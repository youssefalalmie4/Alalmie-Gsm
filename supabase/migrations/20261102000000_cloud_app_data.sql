-- Cloud catalogs and per-account application state for Smart Match Pro.
-- Public catalogs are read-only to app clients; private state is isolated by auth.uid().
create table if not exists public.compatibility_catalog (
  record_id text primary key,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.gsm_catalog (
  model_code text primary key,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_app_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.compatibility_catalog enable row level security;
alter table public.gsm_catalog enable row level security;
alter table public.user_app_state enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='compatibility_catalog' and policyname='smp_public_read_compatibility_catalog') then
    create policy smp_public_read_compatibility_catalog on public.compatibility_catalog for select to anon, authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='gsm_catalog' and policyname='smp_public_read_gsm_catalog') then
    create policy smp_public_read_gsm_catalog on public.gsm_catalog for select to anon, authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_app_state' and policyname='smp_read_own_app_state') then
    create policy smp_read_own_app_state on public.user_app_state for select to authenticated using (auth.uid() = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_app_state' and policyname='smp_insert_own_app_state') then
    create policy smp_insert_own_app_state on public.user_app_state for insert to authenticated with check (auth.uid() = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_app_state' and policyname='smp_update_own_app_state') then
    create policy smp_update_own_app_state on public.user_app_state for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_app_state' and policyname='smp_delete_own_app_state') then
    create policy smp_delete_own_app_state on public.user_app_state for delete to authenticated using (auth.uid() = user_id);
  end if;
end $$;

grant usage on schema public to anon, authenticated;
grant select on public.compatibility_catalog, public.gsm_catalog to anon, authenticated;
grant select, insert, update, delete on public.user_app_state to authenticated;

insert into public.compatibility_catalog(record_id,payload) values
  ('r201', '{"id":"r201","category":"الشاشات","icon":"▣","model":"realme 10 Pro+ 5G / OPPO Reno 9 / Reno 9 Pro","part":"وحدة شاشة OLED مع اللمس","code":"LCD-REAL-10-PR-PLS-5G-CP-B-LED","deviceCode":"RMX3686/RMX3687 · PHM110/PGX110","fit":"مذكور لدى مورد","level":"conditional","date":"2026-11-01","notes":"كتالوج المورد يدرج وحدة شاشة OLED مع اللمس لهذه الموديلات. يختلف تركيب الإطار وإصدار القطعة بين البائعين؛ طابق الفلاتة ورقم الجزء قبل التركيب.","source":"SearchZIP · قوائم موردين","url":"https://searchzip.ru/liberty/model/realme-10-pro-plus/"}'::jsonb),
  ('r202', '{"id":"r202","category":"البطاريات","icon":"▰","model":"realme 10 Pro+ 5G / realme 11 4G","part":"بطارية BLP951 · 4,890 mAh اسمي / 5,000 mAh نموذجي","code":"BLP951","deviceCode":"RMX3686 · RMX3636","fit":"مذكور لدى مورد","level":"conditional","date":"2026-11-01","notes":"قائمة المورد تذكر BLP951 للموديلين. تقرير اعتماد RMX3686 يذكر BLP951 للموديل الأساسي فقط، ولا يثبت وحده توافق Realme 11 4G. طابق الجهد والموصل قبل التركيب.","source":"TechComponentes · كتالوج مورد","url":"https://www.techcomponentes.com/es/realme-11-4g-rmx3636/24637-bateria-blp951-4-890-mah-realme-10-pro-5g-realme-11-4g.html","secondaryUrl":"https://fcc.report/FCC-ID/2AUYFRMX3686/6194357.pdf"}'::jsonb),
  ('r203', '{"id":"r203","category":"الكاميرات","icon":"◎","model":"realme 9 4G / realme 10 Pro 5G / realme 10 Pro+ 5G","part":"وحدة الكاميرا الخلفية 108MP","code":"054313","deviceCode":"RMX3521 · RMX3661 · RMX3686/RMX3687","fit":"مذكور لدى مورد","level":"conditional","date":"2026-11-01","notes":"كتالوج المورد يدرج وحدة كاميرا خلفية 108MP لهذه الموديلات. طابق شكل الوحدة ورقم القطعة والموصل مع القطعة الأصلية.","source":"SearchZIP · قوائم موردين","url":"https://searchzip.ru/liberty/model/realme-10-pro-plus/"}'::jsonb),
  ('r204', '{"id":"r204","category":"واقيات الشاشة","icon":"◈","model":"realme 10 Pro+ / 11 Pro / 11 Pro+ / 12 Pro / 12 Pro+","part":"زجاج حماية UV","code":"058071","deviceCode":"RMX3686/RMX3687 · RMX3771 · RMX3741 · RMX3842 · RMX3840","fit":"مذكور لدى مورد","level":"conditional","date":"2026-11-01","notes":"قائمة المورد تذكر زجاج حماية UV لهذه الموديلات. هذا واقٍ خارجي وليس وحدة الشاشة؛ طابق القصّة وفتحات الكاميرا قبل الاستخدام.","source":"SearchZIP · قوائم موردين","url":"https://searchzip.ru/liberty/model/realme-10-pro-plus/"}'::jsonb),
  ('r205', '{"id":"r205","category":"الشاشات","icon":"▣","model":"realme 10 Pro+ / realme 11 Pro / realme 11 Pro+","part":"زجاج وحدة الشاشة مع OCA (ليس شاشة كاملة)","code":"070215–070217","deviceCode":"RMX3686/RMX3687 · RMX3771 · RMX3741","fit":"مذكور لدى مورد","level":"conditional","date":"2026-11-01","notes":"كتالوج المورد يدرج زجاج وحدة الشاشة مع OCA لهذه الموديلات؛ هذا ليس تجميعة شاشة كاملة. يلزم التأكد من نوع اللوحة والنسخة قبل العمل.","source":"SearchZIP · قوائم موردين","url":"https://searchzip.ru/liberty/model/realme-10-pro-plus/"}'::jsonb)
on conflict (record_id) do update set payload=excluded.payload, updated_at=now();

insert into public.gsm_catalog(model_code,payload) values
  ('RMX3686', '{"code":"RMX3686","aliases":["Realme 10 Pro+ 5G"],"brand":"realme","name":"realme 10 Pro+ 5G","specs":[["المعالج","MediaTek Dimensity 1080 5G، ثماني النواة حتى 2.6GHz"],["معالج الرسوميات","Mali-G68"],["الذاكرة العشوائية","6GB أو 8GB (حسب النسخة)"],["التخزين","128GB أو 256GB (حسب النسخة)"],["الشاشة","AMOLED منحنية، 6.7 بوصة"],["الدقة والتحديث","2412 × 1080، حتى 120Hz"],["الكاميرات الخلفية","108MP رئيسية + كاميرتان مساعدتان"],["الكاميرا الأمامية","16MP"],["البطارية والشحن","5000mAh (typ)؛ شحن 67W"],["الاتصال اللاسلكي","Wi-Fi 6/5/4؛ Bluetooth 5.2"],["الشبكات","5G SA/NSA؛ راجع نطاقات النسخة الإقليمية بالمصدر الرسمي"],["SIM والمنافذ","شريحتا Nano SIM؛ منفذ USB Type-C"],["الأبعاد والوزن","161.5 × 73.9mm؛ السمك والوزن يختلفان حسب اللون"],["الصوت","سماعتان ستيريو؛ Hi-Res Audio"],["المستشعرات","بصمة داخل الشاشة، جيروسكوب، تقارب، إضاءة، تسارع"],["النظام عند الإطلاق","realme UI 4.0 / Android 13"]],"source":"صفحة مواصفات realme الرسمية","url":"https://www.realme.com/global/realme-10-pro-plus/specs","verified":"مواصفات الشركة المصنّعة"}'::jsonb),
  ('SM-A546UZKBUSC', '{"code":"SM-A546UZKBUSC","aliases":["SM-A546U","Galaxy A54 5G"],"brand":"Samsung","name":"Samsung Galaxy A54 5G (نسخة US Cellular)","specs":[["المعالج","Samsung Exynos 1380، ثماني النواة"],["الذاكرة العشوائية","6GB"],["التخزين","128GB؛ يدعم microSD حتى 1TB"],["الشاشة","Super AMOLED، 6.4 بوصة"],["الدقة والتحديث","2340 × 1080، 120Hz"],["الكاميرات الخلفية","50MP مع OIS + 12MP واسعة + 5MP ماكرو"],["الكاميرا الأمامية","32MP"],["البطارية والشحن","5000mAh؛ شحن سلكي 25W"],["النظام عند الإطلاق","Android 13 / One UI 5.1"],["الاتصال","5G، Wi-Fi 6، Bluetooth 5.2، NFC؛ نطاقات US Cellular موضحة بالمصدر"],["الأبعاد والوزن","158.2 × 76.7 × 8.2mm؛ 202g"],["الحماية","IP67؛ Gorilla Glass 5 أمامًا وخلفًا"],["المنافذ","USB Type-C؛ لا يوجد منفذ سماعة 3.5mm"],["المستشعرات","تسارع، جيروسكوب، بوصلة، Hall، إضاءة، تقارب افتراضي، بارومتر"]],"source":"ورقة مواصفات Samsung الرسمية (نسخة US Cellular)","url":"https://image-us.samsung.com/SamsungUS/samsungbusiness/pdf/spec-sheets/a54/HHP_A545G_DATA_USCC.pdf","verified":"مواصفات الشركة المصنّعة؛ نسخة إقليمية محددة"}'::jsonb)
on conflict (model_code) do update set payload=excluded.payload, updated_at=now();
