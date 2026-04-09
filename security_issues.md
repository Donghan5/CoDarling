# CoDarling 보안 이슈 트래커

> 분석일: 2026-04-09
> 상태 범례: 🔴 미해결 · 🟡 진행중 · ✅ 완료

---

## Critical

### C-1 · FCM 디바이스 식별자 비고유
- **상태**: 🔴 미해결
- **파일**: `lib/core/services/push_notification_service.dart`
- **문제**: `_deviceId`를 `Platform.operatingSystem`("android" / "ios")으로 설정 → 동일 OS의 모든 기기가 같은 device_id 공유 → FCM 토큰 덮어쓰기 발생, 멀티 디바이스 사용자에게 알림 유실
- **수정안**: `device_info_plus` 패키지를 사용해 실제 기기 고유 ID(Android: `androidId`, iOS: `identifierForVendor`) 사용

### C-2 · prompt_replies INSERT RLS에 커플 멤버십 검증 없음 (IDOR)
- **상태**: 🔴 미해결
- **파일**: `supabase/migrations/20260407000000_initial_schema.sql` (INSERT 정책)
- **문제**: 현재 INSERT 정책이 `auth.uid() = user_id`만 확인 → 인증된 유저가 **다른 커플의 `prompt_id`**로 답변 삽입 가능
- **수정안**:
  ```sql
  drop policy if exists "Users can insert their own replies" on public.prompt_replies;
  create policy "Users can insert their own replies"
    on public.prompt_replies for insert
    with check (
      auth.uid() = user_id
      and prompt_id in (
        select p.id from public.prompts p
        join public.couples c on c.id = p.couple_id
        where c.user_id_1 = auth.uid() or c.user_id_2 = auth.uid()
      )
    );
  ```

### C-3 · prompts 테이블에 INSERT/UPDATE/DELETE RLS 정책 없음
- **상태**: 🔴 미해결
- **파일**: `supabase/migrations/20260407000000_initial_schema.sql` (prompts 섹션)
- **문제**: `prompts` 테이블에 SELECT 정책만 존재 → 아무 인증 유저가 프롬프트를 직접 생성/수정/삭제 가능. 프롬프트는 관리자가 삽입해야 하는 데이터.
- **수정안**:
  ```sql
  -- 클라이언트에서 INSERT/UPDATE/DELETE 전면 차단
  create policy "Deny client insert on prompts"
    on public.prompts for insert with check (false);
  create policy "Deny client update on prompts"
    on public.prompts for update using (false);
  create policy "Deny client delete on prompts"
    on public.prompts for delete using (false);
  ```

---

## High

### H-1 · 파일 업로드 — 확장자만 검증, MIME 타입 미검증
- **상태**: 🔴 미해결
- **파일**: `lib/features/photo/data/datasources/photo_remote_datasource.dart:50`
- **문제**: `file.path.split('.').last`로 확장자만 확인 → `malware.php.jpg` 같은 파일 통과 가능. 실제 파일 시그니처(magic bytes) 검증 없음.
- **수정안**: `mime` 패키지로 MIME 타입 검증 추가, Supabase Storage 정책에서도 `allowed_mime_types` 설정

### H-2 · 파일 크기 제한이 클라이언트 전용
- **상태**: 🔴 미해결
- **파일**: `lib/features/photo/data/datasources/photo_remote_datasource.dart:56`
- **문제**: 10MB 제한이 Flutter 앱 코드에만 존재 → Supabase API 직접 호출 시 우회 가능, 스토리지 남용 및 DoS 가능성
- **수정안**: `supabase/config.toml`의 `[storage]` 섹션에서 `file_size_limit = "10MiB"` 설정 (현재 50MiB로 설정됨 — 10MiB로 축소 필요)

### H-3 · FCM 에러 응답 원문 로깅
- **상태**: 🔴 미해결
- **파일**: `supabase/functions/push-notification/index.ts:168`
- **문제**: FCM HTTP 에러 응답 body를 그대로 throw → Supabase 함수 로그에 민감 정보 포함 가능
- **수정안**:
  ```typescript
  // Before
  throw new Error(`FCM error ${res.status}: ${errorBody}`);
  // After
  console.error(`[push] FCM error ${res.status}`, res.status);
  throw new Error(`FCM request failed (${res.status})`);
  ```

### H-4 · FCM 만료 토큰 삭제 시 user_id 미포함
- **상태**: 🔴 미해결
- **파일**: `supabase/functions/push-notification/index.ts:94`
- **문제**: 만료/무효 토큰 삭제 쿼리가 `token`만으로 DELETE → 이론적으로 다른 유저의 동일 토큰이 삭제될 수 있음
- **수정안**:
  ```typescript
  // Before
  .delete().in("token", invalidTokens)
  // After
  .delete().in("token", invalidTokens).eq("user_id", userId)
  ```

---

## Medium

### M-1 · 날짜 계산에 로컬 타임존 사용
- **상태**: 🔴 미해결
- **파일**: `lib/core/utils/date_utils.dart:10`
- **문제**: `DateTime.now()`가 기기 로컬 타임존 기준 → 롱디스턴스 커플이 서로 다른 "오늘" 기준으로 사진 잠금 판단 → 한 명은 이미 내일인데 다른 한 명은 어제 취급
- **수정안**:
  ```dart
  // Before
  static String todayIso() => toIsoDate(DateTime.now());
  // After
  static String todayIso() => toIsoDate(DateTime.now().toUtc());
  ```

### M-2 · Supabase 프로젝트 ref 소스코드 하드코딩
- **상태**: 🔴 미해결
- **파일**: `lib/core/constants/app_constants.dart:9`
- **문제**: `supabaseProjectRef = 'ecdshhuvypmgxalpriab'` 공개 저장소에 노출 → 스토리지 버킷 URL, Edge Function URL 추측 가능
- **수정안**: `String.fromEnvironment('SUPABASE_PROJECT_REF')`로 dart-define 주입, 또는 `supabaseUrl`에서 파싱

### M-3 · 인증 상태 스트림 에러 silent failure
- **상태**: 🔴 미해결
- **파일**: `lib/features/auth/data/datasources/auth_remote_datasource.dart:28`
- **문제**: `authStateChanges`의 `asyncMap` 내 예외를 catch해 `null` 반환 → DB 오류 시 사용자가 로그인 실패 원인을 알 수 없고 UI에 아무 피드백 없음
- **수정안**: 에러 타입에 따라 재시도 로직 또는 UI 에러 상태 전파

---

## Low

### L-1 · debugPrint로 내부 에러 구조 로깅
- **상태**: 🔴 미해결
- **파일**: 모든 repository catch 블록 (`[XxxRepo] method error: $e`)
- **문제**: `kDebugMode`에서만 출력되지만, 연결된 기기 로그(`adb logcat`) 접근 시 내부 오류 구조 노출 가능
- **수정안**: 프로덕션 배포 전 Firebase Crashlytics 등 구조화 로깅으로 대체 검토

---

## 이미 수정된 항목

| 항목 | 마이그레이션 | 비고 |
|------|-------------|------|
| `reactions` SELECT `using(true)` 전체 공개 | `20260408000001_security_fixes.sql` | ✅ — **대시보드 수동 적용 필요** |
| `photos` INSERT에 커플 멤버십 검증 없음 | `20260409000000_security_hardening.sql` | ✅ — **대시보드 수동 적용 필요** |
| `reactions` INSERT에 타겟 소유권 검증 없음 | `20260409000000_security_hardening.sql` | ✅ — **대시보드 수동 적용 필요** |
| 초대 코드 만료 RLS 미적용 | `20260409000000_security_hardening.sql` | ✅ — **대시보드 수동 적용 필요** |
| `prompt_replies` UPDATE/DELETE 정책 없음 | `20260409000001_prompt_rls_fixes.sql` | ✅ — **대시보드 수동 적용 필요** |
| 로그인 화면 테스트 비밀번호 하드코딩 | dart-define으로 외부화 | ✅ 완료 |

> ⚠️ "대시보드 수동 적용 필요" 항목들은 마이그레이션 파일은 존재하지만 Supabase 대시보드 SQL 에디터에서 직접 실행했는지 확인 필요.

---

## 수정 우선순위 요약

```
즉시 (Critical)
  C-2  prompt_replies INSERT RLS 강화    → SQL 마이그레이션
  C-3  prompts INSERT/UPDATE/DELETE 차단  → SQL 마이그레이션
  C-1  FCM 디바이스 고유 ID              → device_info_plus 패키지

다음 스프린트 (High/Medium)
  H-2  Storage 파일 크기 서버 제한       → supabase/config.toml 수정
  H-1  MIME 타입 검증 추가               → mime 패키지
  M-1  날짜 UTC 통일                     → date_utils.dart 1줄 수정
  H-3  FCM 에러 로그 sanitize            → push-notification/index.ts
  H-4  토큰 삭제 쿼리 user_id 추가      → push-notification/index.ts
```
