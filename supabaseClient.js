// ============================================================
// ATELIER · Supabase 공통 설정
// 아래 두 값을 본인 프로젝트 값으로 교체하세요.
//   Supabase 대시보드 → Project Settings → API 에서 확인
//   - Project URL        → SUPABASE_URL
//   - anon public key     → SUPABASE_ANON_KEY  (공개돼도 되는 키, service_role 키 아님!)
// ============================================================
const SUPABASE_URL = 'https://lllyjtniltoejsnfajsz.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_8ctDm_qLUFv-vKnvzeR6gQ_ePxVro0j';  // publishable(공개) 키

// supabase-js UMD 번들이 먼저 로드돼 있어야 합니다 (각 html <head>에 CDN 추가됨)
const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// 현재 로그인 사용자 가져오기 (없으면 null)
async function currentUser() {
  const { data: { user } } = await sb.auth.getUser();
  return user;
}

// 로그아웃
async function signOut() {
  await sb.auth.signOut();
}

// 설정 안 된 상태 감지(샘플 값 그대로면 경고)
function supabaseConfigured() {
  return !SUPABASE_URL.includes('YOUR-PROJECT') && !SUPABASE_ANON_KEY.includes('YOUR-ANON');
}
