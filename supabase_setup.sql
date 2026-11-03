-- ============================================================
-- ATELIER 쇼핑몰 · Supabase 초기 설정 스크립트
-- 사용법: Supabase 대시보드 → SQL Editor → New query → 전체 붙여넣기 → Run
-- ============================================================

-- ─────────────────────────────────────────────
-- 1. profiles : 회원 추가 정보 (auth.users 와 1:1)
--    (이메일/비밀번호는 Supabase Auth가 관리하므로 여기 두지 않음)
-- ─────────────────────────────────────────────
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text,
  phone       text,
  marketing   boolean default false,
  created_at  timestamptz default now()
);

-- ─────────────────────────────────────────────
-- 2. addresses : 배송지 (회원당 여러 개, 기본 배송지 지정 가능)
-- ─────────────────────────────────────────────
create table if not exists public.addresses (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  recipient   text not null,          -- 받는 분
  phone       text not null,          -- 연락처
  zip         text not null,          -- 우편번호
  addr1       text not null,          -- 기본 주소
  addr2       text,                   -- 상세 주소
  memo        text,                   -- 배송 요청사항
  is_default  boolean default false,  -- 기본 배송지 여부
  created_at  timestamptz default now()
);

-- ─────────────────────────────────────────────
-- 3. orders : 주문 (헤더)
-- ─────────────────────────────────────────────
create table if not exists public.orders (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references auth.users(id) on delete set null,
  buyer_name   text,
  buyer_phone  text,
  buyer_email  text,
  ship_recipient text,
  ship_phone   text,
  ship_zip     text,
  ship_addr1   text,
  ship_addr2   text,
  ship_memo    text,
  pay_method   text,                  -- 카드 / 무통장 / 카카오페이 / 네이버페이
  total        integer not null,      -- 총 결제금액
  status       text default '결제완료', -- 결제완료 / 배송중 / 배송완료 / 취소
  created_at   timestamptz default now()
);

-- ─────────────────────────────────────────────
-- 4. order_items : 주문 상세 (주문 1건에 상품 N개)
-- ─────────────────────────────────────────────
create table if not exists public.order_items (
  id         uuid primary key default gen_random_uuid(),
  order_id   uuid not null references public.orders(id) on delete cascade,
  product_id text,                    -- 코드상의 상품 식별자(상품명 등)
  name       text not null,
  price      integer not null,
  qty        integer default 1
);

-- ============================================================
-- RLS (Row Level Security) : 로그인한 본인 데이터만 접근 허용
-- ★ 이 설정이 없으면 다른 사람 데이터가 노출됩니다. 반드시 실행하세요.
-- ============================================================

-- profiles
alter table public.profiles enable row level security;
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

-- addresses
alter table public.addresses enable row level security;
create policy "addresses_select_own" on public.addresses
  for select using (auth.uid() = user_id);
create policy "addresses_insert_own" on public.addresses
  for insert with check (auth.uid() = user_id);
create policy "addresses_update_own" on public.addresses
  for update using (auth.uid() = user_id);
create policy "addresses_delete_own" on public.addresses
  for delete using (auth.uid() = user_id);

-- orders
alter table public.orders enable row level security;
create policy "orders_select_own" on public.orders
  for select using (auth.uid() = user_id);
create policy "orders_insert_own" on public.orders
  for insert with check (auth.uid() = user_id);

-- order_items : 부모 주문의 소유자만 접근
alter table public.order_items enable row level security;
create policy "order_items_select_own" on public.order_items
  for select using (
    exists (select 1 from public.orders o
            where o.id = order_items.order_id and o.user_id = auth.uid())
  );
create policy "order_items_insert_own" on public.order_items
  for insert with check (
    exists (select 1 from public.orders o
            where o.id = order_items.order_id and o.user_id = auth.uid())
  );

-- ============================================================
-- 회원가입 시 profiles 행 자동 생성 트리거
-- (가입할 때 넘긴 name/phone/marketing 메타데이터를 profiles에 복사)
-- ============================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, phone, marketing)
  values (
    new.id,
    new.raw_user_meta_data ->> 'name',
    new.raw_user_meta_data ->> 'phone',
    coalesce((new.raw_user_meta_data ->> 'marketing')::boolean, false)
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 완료!
