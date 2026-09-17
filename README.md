# Hi Trip 🧳

> 여행사가 진행하는 단체여행을 위한 iOS 앱 — 참가자와 인솔 담당자가 같은 앱을 씁니다.

App Store 심사 제출 버전 **1.0.0 (빌드 8)** · 태그 `v1.0.0` · iOS 16.0+ · iPhone 전용

<br>

## 프로젝트 소개

여행사에서 발급한 계정으로 로그인하면 그 여행의 일정·공지·안전 안내를 한 곳에서 확인합니다.
앱에는 회원가입이 없습니다. 계정은 여행사 SaaS에서 발급하고, **어느 홈으로 갈지는 서버가 인정한 계정 종류로 정합니다(앱이 추측하지 않음).**

| 역할 | 화면 |
|------|------|
| 여행객 (tourist) | 오늘·다음 일정, 전체 일정, 주변 스팟 지도, 채팅, 공지, 현지 표현, 긴급 통역 연결 |
| 안내사 (staff) | 담당 여행 현황, 일정 수정, 공지 작성, 안전 관리, 지도 범위 설정, 채팅, 알림 센터 |

두 역할은 **인증 방식부터 다릅니다.** 여행객은 Bearer 토큰, 안내사는 세션 쿠키 + CSRF입니다.
한 앱에서 두 인증을 함께 다루는 것이 이 프로젝트의 핵심 제약이었습니다.

<br>

## 기술 스택

| 구분 | 선택 | 이유 |
|------|------|------|
| UI | SwiftUI | 선언형 UI, iOS 16 타깃 |
| 비동기 | RxSwift (Single/Observable) | Repository → UseCase → ViewModel 흐름 통일. 일부 진입점은 async/await 병행 |
| 네트워크 | URLSession 직접 래핑 | 요청 빌드·에러 분류·재시도 정책을 직접 다루기 위해 (Moya/Alamofire 미사용) |
| DI | 생성자 주입 + Protocol | 테스트에서 Stub·Mock 교체. `AppDIContainer`가 실서버/목 구현을 스위치 |
| 저장 | Keychain (`AfterFirstUnlockThisDeviceOnly`) | 토큰이 백업·기기 이전으로 복사되지 않도록 |
| 지도 | KakaoMaps SDK | 주변 스팟·안전 구역(원형 지오펜스) 표시 |
| 패키지 | SPM | RxSwift, KakaoMapsSDK |

서버는 별도 저장소(Python/DRF)이며 앱은 OpenAPI 스키마를 계약으로 사용합니다.

<br>

## 아키텍처

**Clean Architecture + MVVM.** 레이어 간 의존은 Protocol로만 연결합니다.

```
View (SwiftUI)
  └─ ViewModel (@MainActor, @Published)
       └─ UseCase (입력 검증·비즈니스 규칙)
            └─ RepositoryProtocol
                 ├─ RemoteRepository (NetworkService)
                 └─ MockRepository   (서버 없이 실행·스크린샷용)
```

- `APIEnvironment.current`를 `.mock`으로 바꾸면 **서버 없이 전체 앱이 동작**합니다. 목 데이터는 고정 날짜를 박지 않고 오늘 기준 상대 날짜로 만듭니다.
- 화면 부품 중 여행객·안내사가 공유하는 것은 `Features/Common/`에 둡니다. 역할별로 다른 판정 로직은 각 ViewModel에 남깁니다.

<br>

## 기술적으로 해결한 문제

### 1. 여행지 시간대 기준 "오늘" — `TripClock`

**문제.** 홈과 전체 일정이 서로 다른 일차를 보여주고, 한국 시간 새벽 0~9시에는 하루 전 일차가 나왔습니다.

**원인.** 서버가 `today_day_number`를 UTC로 계산했고, 앱은 화면마다 오늘을 따로 구했습니다. 응답 시점 값이라 화면을 오래 켜 두면 굳기도 했습니다.

**해결.** 시각에 따라 바뀌는 판정을 `Core/Formatting/TripClock.swift` 한 곳으로 모았습니다.

```swift
TripClock(startDate:endDate:timeZoneID:now:)   // now 주입 → 새벽 시각 테스트 가능
  .todayDayNumber / .phase / .progress / .remainingDays
  .isAfterNow(dayNumber:startTime:)
```

시간대는 기기가 아니라 **여행 데이터**로 다룹니다(`trip.timezone`, 없으면 Asia/Seoul). 해외 여행에서도 현지 날짜로 맞기 때문입니다. 백엔드에도 `timezone` 필드와 `localdate()` 기준 계산을 요청해 반영했습니다.

경계값은 테스트로 고정했습니다. 04:02 KST가 2일차인지, 마지막 날·종료 후, 진행률 0.4 등.

### 2. 한 앱에서 두 가지 인증 — Bearer와 세션 쿠키 + CSRF

**문제.** 안내사 쪽에서 일정 저장·공지 작성이 "로그인이 필요합니다"(403)로 실패하고, 채팅 전송도 막혔습니다.

**원인.** 두 가지가 겹쳐 있었습니다.
1. 안내사의 Keychain 값은 "로그인했음"을 표시하는 마커인데 모든 요청에 `Bearer`로 실려 나갔습니다.
2. 로그인 **전에** 받은 CSRF 토큰을 정적 변수에 들고 계속 썼습니다. Django는 로그인 시 CSRF를 새로 발급(rotate)해서 쿠키만 최신이었습니다.

**해결.** `buildRequest`에서 역할에 따라 인증을 나누고, CSRF는 쿠키 값을 우선했습니다.

```swift
if keychain.getUserType() != UserType.guide.rawValue, let token = keychain.getToken() {
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
}
if endpoint.method != .get, let csrf = csrfCookieValue() ?? NetworkService.csrfToken {
    request.setValue(csrf, forHTTPHeaderField: "X-CSRFToken")
    request.setValue(baseURL, forHTTPHeaderField: "Referer")   // HTTPS에서 Django가 Referer도 검사
}
```

첨부 업로드는 `NetworkService`를 거치지 않는 별도 PUT이라 같은 규칙을 그쪽에도 넣어야 했습니다. `Referer`가 빠져 사진만 실패하던 문제가 여기서 나왔습니다.

### 3. 채팅에서 "내 메시지" 판정

**문제.** 안내사가 보낸 메시지가 상대 말풍선으로 보였고, 여행객 단체방에서는 다른 사람 메시지가 내 것으로 보였습니다.

**원인.** 서버 `sender_role`은 `tourist | manager | admin`인데 앱은 `staff`와 비교했습니다. 여행객 쪽은 역할만 비교해서 단체방의 모든 여행객이 "나"가 됐습니다.

**해결.** 역할을 정규화하고, 같은 역할이 여러 명일 수 있는 경우에는 보낸 사람 id까지 비교합니다.

```swift
let senderSide = (senderRole == "tourist") ? "tourist" : "staff"
```

여행객은 로그인 응답에 채팅 `sender`와 같은 사용자 id가 없어서, **내가 보낸 메시지의 응답에서 id를 학습해 저장**하는 방식으로 먼저 막고, 백엔드에 `user_id` 추가를 요청해 정식으로 해결했습니다. 학습 방식은 첫 전송 전을 위한 예비 수단으로 남겨 두었습니다.

### 4. 강제 업데이트 버전 비교

**문제.** 앱 버전 `1.0`, 서버 최소 버전 `1.0.0`. 서버에 스토어 주소가 채워지는 순간 **최신 사용자 전원에게 닫을 수 없는 업데이트 팝업**이 뜰 수 있었습니다.

**원인.** `String.compare(_:options: .numeric)`은 짧은 쪽을 낮게 봅니다. `"1.0" < "1.0.0" == true`.

**해결.** 점 단위 숫자 비교로 바꾸고 자리 수를 맞췄습니다. 앱 표기도 `1.0.0`으로 통일하고 경계값을 테스트로 고정했습니다.

```swift
XCTAssertFalse(AppVersionChecker.isVersion("1.0", lowerThan: "1.0.0"))
XCTAssertTrue(AppVersionChecker.isVersion("1.9.0", lowerThan: "1.10.0"))
```

스토어 주소가 없으면 팝업 자체를 띄우지 않습니다. 동작하지 않는 버튼만 있는 팝업으로 앱이 막히는 상황을 막기 위해서입니다.

### 5. 앱 번들에서 카카오 REST 키 제거

주변 스팟 중 서버가 지원하지 않는 카테고리를 카카오 로컬 API로 직접 부르면서, **REST 키가 앱 번들에 포함**됐습니다. 번들에서 추출해 쿼터를 소진시킬 수 있는 상태였습니다.

서버에 카테고리 7종을 추가해 달라고 요청해 모든 카테고리를 서버 API로 옮기고 `KakaoLocalService`를 삭제했습니다. 반경·정렬·개수가 기존과 같은지(2km·거리순·15개) 스키마 기본값으로 확인했습니다.

### 6. 중복 UI 통합

여행객과 안내사 화면에 같은 UI가 따로 있어서, 한쪽을 고치면 다른 쪽이 어긋났습니다. 키보드 가림·일정 카드·여백·검색창을 두 번씩 고치는 일이 반복됐습니다.

화면 전체를 합치는 대신 **부품만 공통화**했습니다. 역할마다 다른 기능(개인 일정 ⋯ 메뉴, 장소 검색, 채팅 필터)이 많아 화면을 합치면 분기가 계속 늘어나기 때문입니다.

```
Features/Common/Trip/
├── TodayScheduleSection.swift   # 홈 진행률 카드 ~ 전체일정 링크
└── TripDetailComponents.swift   # 여행 카드·일차 머리·점선 버튼·시트·시간 칸
```

판정 로직은 각 ViewModel에 두고, 공통 부품은 `ScheduleSummary` 같은 표시용 모델만 받습니다.

### 7. 그 밖의 문제들

| 문제 | 해결 |
|------|------|
| 시트가 키보드에 가림 | `ignoresSafeArea(edges:)` → `.ignoresSafeArea(.container, edges: .bottom)`. 키보드가 뜨면 홈 인디케이터 여백도 줄임 |
| 시간 휠이 위아래 요소와 겹침 | 고정 높이 컨테이너 + `clipped()`를 공통 부품으로 |
| 지도 핀을 눌러도 반응 없음 | 지도 단위 핸들러는 카카오 기본 POI만 받음 → 우리 핀은 `poi.addPoiTappedEventHandler`로 개별 등록 |
| 일정 추가 시 `day/order` 중복 오류 | `order`를 보내지 않아 서버 기본값 0과 충돌 → 그 일차의 최대 order + 1 전송 |
| 목록 미리보기가 "새로운 채팅방"으로만 보임 | 첨부만 있는 메시지는 본문이 비어 있음 → `message_type`·`attachments[].media_type`으로 "사진"·"음성 메시지" 표기 |
| 오프라인 전송 | 연결이 없으면 큐에 쌓고 재연결 시 순서대로 전송. 쓰기 요청은 자동 재시도하지 않음(성공 여부 불명확) |

<br>

## 네트워크 정책

```swift
config.timeoutIntervalForRequest = 15     // 기본 60초는 서버가 멈췄을 때 사용자가 1분을 기다림
config.timeoutIntervalForResource = 60
```

- **조회(GET)만 자동 재시도**합니다. 1초 → 2초 간격 2회. 저장·전송은 성공 여부가 불분명할 때 반복하면 안 되므로 제외합니다.
- 재시도 대상은 연결 오류뿐입니다. 응답 대기 초과는 이미 15초를 기다린 뒤라 다시 걸지 않습니다.
- HTTP 상태코드를 `HiTripError`로 분류하고, 서버 본문의 `detail`·필드 오류·`remaining_attempts` 같은 값을 파싱해 화면 문구로 씁니다.
- 401(토큰 만료)·안내사 403(세션 만료)은 `NotificationCenter`로 알려 라우터가 로그인 화면으로 되돌립니다.

<br>

## 보안 · 프라이버시

- **Release 로그 차단.** `print`가 Release에서도 동작해 로그인 응답의 Bearer 토큰과 개인정보가 기기 콘솔에 남았습니다. `NetworkService.log`로 DEBUG 전용 출력으로 바꾸고, 응답 본문의 `*token*`·`*password*` 값을 정규식으로 마스킹합니다.
- **Keychain**은 `AfterFirstUnlockThisDeviceOnly`. 백그라운드 접근은 유지하면서 백업·기기 이전으로 토큰이 복사되지 않게 합니다.
- **키·연락처는 커밋하지 않습니다.** `APIKeys.swift`, `AppContacts.swift`는 `.gitignore` 대상이고 템플릿만 저장소에 둡니다.
- **`PrivacyInfo.xcprivacy`** 로 수집 항목(이름·연락처·정밀 위치·사진/영상·음성·대화)과 UserDefaults 등 사용 이유를 선언합니다.
- **채팅 신고·차단**(App Store 가이드라인 1.2). 메시지를 길게 눌러 신고, 헤더 메뉴에서 차단·해제.
- 위치는 **When In Use만** 요청하고, 거부해도 일정·공지는 그대로 씁니다. 홈 상단에 제한 배너만 표시합니다.
- 푸시를 넣지 않는 동안에는 **알림 권한을 요청하지 않습니다.** 기능 없이 권한만 요구하면 심사에서 지적받습니다.

<br>

## 테스트

```bash
xcodebuild test -scheme HiTrip -destination 'platform=iOS Simulator,name=iPhone 17'
```

| 대상 | 확인하는 것 |
|------|-------------|
| `TripClockTests` | 새벽 시각의 일차, 해외 시간대, 여행 전/마지막 날/종료 후, 진행률, `isAfterNow` |
| `AppVersionCheckerTests` | `1.0` vs `1.0.0`, `1.9` vs `1.10` 등 버전 비교 경계 |
| `LoginUseCaseTests` | 입력 검증, 남은 시도 횟수 전달, 실패 분기 (`StubAuthRepository`) |

시각에 의존하는 로직은 `now`를 주입해 재현합니다. 목 데이터에도 고정 날짜를 박지 않습니다.

<br>

## 폴더 구조

```
HiTrip/
├── App/                    # 진입점, AppRouter, 홈 컨테이너
├── Core/
│   ├── Config/             # AppLinks · APIKeys/AppContacts(커밋 제외)
│   ├── DesignSystem/       # 색·폰트·간격 토큰, 공통 컴포넌트
│   ├── DI/                 # AppDIContainer
│   ├── Formatting/         # AppDate, TripClock
│   ├── Network/            # NetworkService, Endpoints, DTOs
│   ├── Storage/            # Keychain, 동의 기록
│   └── System/             # 권한, 버전 확인
├── Domain/                 # Entity · RepositoryProtocol · UseCase
├── Data/Repositories/      # Remote(실서버) / Mock(목 데이터)
├── Features/
│   ├── Auth/               # 스플래시, 로그인, 약관 동의
│   ├── Chat/               # 채팅방·말풍선·음성 재생 (역할 공용)
│   ├── Common/             # 로그아웃, 정책 링크, 공통 지도
│   ├── Common/Trip/        # 홈 오늘의 일정 · 전체 일정 공통 부품
│   ├── Tourist/            # 여행객 전용
│   └── Guide/              # 안내사 전용
├── Info.plist
└── PrivacyInfo.xcprivacy
```

<br>

## 설치 및 실행

### 요구사항

Xcode 16.0+ · iOS 16.0+ · Swift 5.0

```bash
git clone https://github.com/Hi-Trip-team/Hi_Trip_app.git
cd Hi_Trip_app/HiTrip
open HiTrip.xcodeproj
```

SPM 의존성(RxSwift, KakaoMapsSDK)은 프로젝트를 열 때 자동으로 받아집니다.

### 커밋하지 않는 설정 파일

| 파일 | 내용 | 템플릿 |
|------|------|--------|
| `HiTrip/Core/Config/APIKeys.swift` | 카카오 네이티브 앱 키(지도 SDK) | `APIKeys.example.txt` |
| `HiTrip/Core/Config/AppContacts.swift` | 통역 전화번호, 문의 이메일, 약관·개인정보처리방침 주소 | `AppContacts.example.txt` |

값이 비면 해당 버튼이 동작하지 않습니다. 제출용 빌드 머신에도 같은 값이 필요합니다.

<br>

## 코드 규칙

- **날짜·시각 판정은 `TripClock`으로.** 화면에서 따로 계산하지 않습니다.
- **사실 데이터는 서버 값 그대로.** 일정·안전 상태·겹침 경고·읽음 여부는 서버 판정을 따릅니다.
- **iOS 16 지원.** `navigationDestination(unwrapping:)`, 단일 인자 `onChange` 등 `Core/Extensions/View+iOS16Compat.swift`의 헬퍼를 씁니다.
- 라이트 모드 고정, 세로 고정, iPhone 전용.
- 폴더가 파일 시스템과 동기화되어 있어 파일을 추가하면 Xcode가 자동 인식합니다.

<br>

## Git Convention

```
feat / fix / refactor / test / chore / docs / style
```

```
main ── develop ── feat/기능명
                └─ fix/버그명
                └─ refactor/대상
```

작업 묶음마다 이슈 하나, 브랜치 하나, PR 하나. 한 PR 안에서도 커밋은 기능 단위로 나눕니다.
출시 시점에 `develop`을 `main`에 병합하고 `vX.Y.Z` 태그를 답니다.

<br>

## 출시 준비

App Store 심사를 위해 정리한 항목입니다.

- 채팅 신고·차단, `PrivacyInfo.xcprivacy`, 홈에서 약관·개인정보처리방침·문의 접근
- 약관 동의를 **계정 기준**으로 판정(같은 기기에서 다른 계정으로 로그인하면 다시 동의). 기기 기준이면 그 계정의 동의 이력이 서버에 남지 않습니다
- 알림 권한 요청 제거, 세로 고정, iPhone 전용, 강제 업데이트 버전 비교 수정
- 계정이 여행사 발급이라 심사용 데모 계정을 준비하고 심사 노트에 확인 절차를 적습니다

<br>

## 문서

| 문서 | 내용 |
|------|------|
| `docs/QA_안내사.md` | 안내사 화면 QA 기록 |
| `docs/서버요청_2026-09-11.md` | 백엔드 요청 항목 |
| `docs/기획확정요청_2026-09-11.md` | 기획 확인 필요 항목 |
| `docs/검증불가_데이터요청.md` | 데이터가 없어 검증하지 못한 항목 |

트러블슈팅은 GitHub 이슈에 원인·해결 중심으로 남깁니다.

<br>

## 라이선스

2026 관광데이터 활용 공모전 출품작으로 시작해 App Store 출시를 준비하고 있습니다.
