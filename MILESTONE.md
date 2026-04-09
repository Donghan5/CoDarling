# CoDarling 개발 마일스톤

## 현재 상태 (2026-04-08 기준)

### 완료된 것들

#### 환경 & 빌드
- [x] Flutter SDK 3.29.3, Supabase CLI v2.84.2
- [x] Android 에뮬레이터 (Pixel_8, API 37, emulator-5554)
- [x] APK 빌드 + 배포 성공
- [x] `run.sh` — `flutter run --dart-define-from-file=.dart_define.json`

#### 백엔드 (Supabase)
- [x] DB 마이그레이션 적용됨 (모두 Supabase 대시보드 SQL 에디터에서 직접 실행)
  - `20260407000000_initial_schema.sql` — 전체 스키마 + RLS
  - `20260408000000_fix_couple_join_policy.sql` — 커플 초대 수락 RLS 버그 수정
  - `20260408000001_security_fixes.sql` — 반응/사진/스토리지 RLS 강화
  - `20260408100000_app_metrics.sql` — 클라이언트 텔레메트리 버퍼 테이블
- [x] Storage 버킷 `photos` (private + RLS)
- [x] Edge Function `metrics` 배포 + 정상 동작 확인

#### 기능
- [x] Google OAuth 로그인 (더미 유저 버튼도 포함 — DEV_TEST_PASSWORD)
- [x] 커플 초대 코드 생성 / 수락 (6자리, 7일 만료)
- [x] 오늘의 사진 업로드 (Lock 화면 → 업로드 → 파트너 사진 공개)
- [x] Signed URL로 사진 불러오기 (7일 만료)

#### 보안
- [x] 파일 타입/크기 검증 (10MB, jpg/jpeg/png/webp/heic)
- [x] 에러 메시지 sanitize (`_toUserMessage()`)
- [x] 라우터 가드 (이미 커플인 유저 → `/couple-setup` 접근 차단)
- [x] `.gitignore`에 `.dart_define.json`, `tools/`, `run.sh` 포함

#### 모니터링
- [x] `MetricsService` — 모든 repository 호출을 wrap, 30초마다 flush
- [x] Supabase Edge Function `/metrics` — Prometheus 형식 응답
- [x] 메트릭 엔드포인트 인증: `METRICS_SECRET` (supabase secrets에 등록됨)
- [x] 로깅 기반으로 전환 (Grafana Cloud 연동 계획 제거)

---

## 다음 작업 목록

### 1순위 — 핵심 기능 완성

#### 반응 이모지 (Reaction)
- [x] `ReactionRemoteDataSource.addReaction()` / `getReactions()` / `removeReaction()` 구현
- [x] `ReactionRepositoryImpl` 구현 (metrics 포함)
- [x] `ReactionBar` 위젯 — 이모지별 카운트, 내 반응 하이라이트, + 버튼으로 피커
- [x] `TodayPhotoCard`에 `showReactions` 옵션 추가 (파트너 사진에 적용)
- [x] 실시간 업데이트 (Supabase Realtime 구독 — PostgresChangeEvent)

#### 오늘의 질문 (Daily Prompt)
- [x] `PromptRemoteDataSource.getTodayPrompt()` / `submitReply()` 구현
- [x] 홈 화면에 질문 카드 표시
- [x] 두 사람 모두 답변 시 서로 답변 공개 (사진 lock과 동일한 패턴)

#### 달력 뷰
- [x] 지난 날짜의 사진 목록 불러오기 (albumPhotosProvider 재사용, 날짜별 그룹핑)
- [x] 월별 달력 UI + 날짜 탭 → 해당 날 사진 보기 (BottomSheet)

### 2순위 — 완성도

#### 푸시 알림
- [x] `firebase_core`, `firebase_messaging` 패키지 추가
- [x] `fcm_tokens` 테이블 마이그레이션 (`20260409100000_fcm_tokens.sql`)
- [x] `PushNotificationService` — 토큰 저장/갱신/삭제, 탭 이벤트 처리
- [x] Edge Function `push-notification` — DB Webhook → FCM HTTP v1
- [x] `main.dart`에 Firebase 초기화 + auth 상태 연동
- [ ] **수동 작업 필요** (아래 참고)

#### E2E 테스트
- [x] 위젯 테스트 14개 (LoginScreen, PromptCard, HomeScreen)
- [x] `integration_test/app_test.dart` — 실 디바이스 smoke test skeleton
- [ ] Firebase 연동 완료 후 실 디바이스 E2E 실행 검증

---

## 빠른 참고

### 앱 실행
```bash
cd ~/CoDarling
bash run.sh
# 또는
flutter run -d emulator-5554 --dart-define-from-file=.dart_define.json
```

### 에뮬레이터 시작
```bash
~/Android/Sdk/emulator/emulator -avd Pixel_8 -no-snapshot-load &
```

### APK 빌드 + 설치
```bash
flutter build apk --debug --dart-define-from-file=.dart_define.json
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.example.codarling/.MainActivity
```

### 푸시 알림 설정 (수동 작업)

**1. Firebase 프로젝트 생성**
- https://console.firebase.google.com → 새 프로젝트 → Android 앱 등록 (패키지: `com.codarling.codarling`)
- `google-services.json` 다운로드 → `android/app/google-services.json`에 배치 (gitignore됨)

**2. Service Account 키 등록**
- Firebase Console → Project Settings → Service accounts → Generate new private key
- 다운로드한 JSON 파일 전체 내용을 Supabase에 등록:
```bash
~/.local/bin/supabase secrets set FCM_SERVICE_ACCOUNT_KEY='<JSON 파일 내용>' --project-ref ecdshhuvypmgxalpriab
```

**3. DB 마이그레이션 적용**
- Supabase Dashboard → SQL Editor에서 `supabase/migrations/20260409100000_fcm_tokens.sql` 실행

**4. Edge Function 배포**
```bash
~/.local/bin/supabase functions deploy push-notification --project-ref ecdshhuvypmgxalpriab --no-verify-jwt
```

**5. DB Webhook 설정**
- Supabase Dashboard → Database → Webhooks → Create webhook
  - Name: `photo_insert_push_notification`
  - Table: `photos` / Event: `INSERT`
  - Type: Supabase Edge Functions → `push-notification`

### 주요 파일 경로
| 항목 | 경로 |
|------|------|
| 앱 진입점 | `lib/main.dart` |
| 라우터 | `lib/core/router/app_router.dart` |
| MetricsService | `lib/core/services/metrics_service.dart` |
| Edge Function | `supabase/functions/metrics/index.ts` |
| 자격 증명 | `.dart_define.json` (gitignored) |
| DB 마이그레이션 | `supabase/migrations/` |
