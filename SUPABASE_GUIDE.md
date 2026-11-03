# ATELIER × Supabase 연동 가이드

localStorage 기반 데모를 실제 DB·인증으로 바꾸기 위한 설정 순서입니다.
아래 1~4단계만 하면 바로 동작합니다.

## 1. Supabase 프로젝트 만들기
1. https://supabase.com 가입 → **New project** 생성
2. 프로젝트가 만들어지면 좌측 메뉴 **Project Settings → API** 로 이동
3. 두 값을 복사해 둡니다
   - **Project URL** (예: `https://abcd1234.supabase.co`)
   - **anon public** 키 (`service_role` 키 아님! anon public 키만 사용)

> service_role 키는 모든 보안을 우회하는 키라 프론트 코드·깃에 절대 넣지 마세요.

## 2. 데이터베이스 테이블 만들기
1. 좌측 메뉴 **SQL Editor → New query**
2. 프로젝트의 `supabase_setup.sql` 파일 내용을 전부 복사해 붙여넣기
3. **Run** 클릭 → "Success" 가 나오면 테이블 4개 + 보안정책(RLS) + 가입 트리거가 생성됩니다
   - `profiles`, `addresses`, `orders`, `order_items`

## 3. 코드에 키 넣기
`supabaseClient.js` 파일을 열고 맨 위 두 값을 1단계에서 복사한 값으로 교체합니다.

```js
const SUPABASE_URL = 'https://abcd1234.supabase.co';   // ← 본인 Project URL
const SUPABASE_ANON_KEY = 'eyJhbGciOi...';             // ← 본인 anon public key
```

## 4. 이메일 인증 설정 (중요)
- **Authentication → Providers → Email** 이 기본 활성화돼 있습니다.
- 테스트 편하게 하려면 **Authentication → Sign In / Providers → Email → "Confirm email" 끄기**
  → 가입 즉시 로그인됩니다. (실서비스에서는 켜는 걸 권장)
- 로컬 파일(`file://`)에서 열면 인증 리디렉션이 제한될 수 있어요. 아래 "실행 방법" 참고.

---

## 실행 방법 (로컬)
`file://` 로 바로 열면 일부 브라우저에서 Supabase 요청이 막힐 수 있습니다. 간단한 로컬 서버로 여세요.

```powershell
# 프로젝트 폴더에서 (Python 설치돼 있으면)
python -m http.server 5500
# 브라우저에서 http://localhost:5500/index.html 접속
```

VS Code를 쓰면 **Live Server** 확장으로 index.html을 "Open with Live Server" 해도 됩니다.

Supabase 대시보드 **Authentication → URL Configuration → Site URL / Redirect URLs** 에
`http://localhost:5500` 을 추가해 두면 인증 리디렉션이 매끄럽습니다.

---

## 무엇이 어디에 저장되나
| 데이터 | 저장 위치 |
|---|---|
| 회원(이메일/비밀번호) | Supabase **Auth** (비밀번호 안전 해시 저장) |
| 이름·휴대폰·마케팅 동의 | `profiles` 테이블 (가입 시 트리거가 자동 생성) |
| 기본 배송지 | `addresses` 테이블 (본인 것만 조회·수정 가능) |
| 주문 / 주문 상품 | `orders` / `order_items` 테이블 |
| 장바구니(결제 전) | 브라우저 localStorage (로그인 없이 담기 위함) |

주문을 확인·관리하려면 Supabase 대시보드 **Table Editor → orders** 에서 볼 수 있습니다.

---

## 아직 안 한 것 (원하면 이어서)
- **소셜 로그인(카카오/네이버/구글)**: `login.html`에 버튼 UI는 있고, `social()` 함수가 주석으로 준비돼 있어요.
  Supabase **Authentication → Providers** 에서 해당 제공자 OAuth 키를 등록한 뒤 버튼에 연결하면 됩니다.
- **실제 결제(PG) 연동**: 현재 결제는 주문만 기록하고 실제 청구는 없습니다. 토스페이먼츠·포트원 등 연동 필요.
- **상품을 DB로 이전**: 지금은 상품이 `index.html` 코드 배열에 있습니다. `products` 테이블로 옮기면 코드 수정 없이 상품 관리가 가능합니다.

## 보안 체크
- `anon key`는 공개돼도 안전한 키입니다 (RLS가 데이터를 지켜줌).
- RLS 정책 덕분에 로그인한 **본인 데이터만** 조회·수정됩니다. `supabase_setup.sql`을 꼭 실행해 RLS를 켜세요.
