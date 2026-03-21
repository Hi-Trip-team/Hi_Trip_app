# Hi Trip 🧳

> 관광 안내사와 관광객을 연결하는 여행 SaaS 플랫폼

**2026 한국관광공사 × 카카오 관광데이터 활용 공모전** 출품예정

<br>

## 프로젝트 소개

Hi Trip은 관광 안내사(Guide)와 관광객(Tourist)을 매칭하여
일정 관리, 실시간 채팅, 스팟 추천, 건강/긴급 연락 기능을 제공하는 iOS 앱입니다.

### 주요 기능

| 기능 | 설명 |
|------|------|
| 인증 | 로그인 / 회원가입 (4단계) / 자동 로그인 |
| 일정 관리 | 안내사-관광객 일정 공유 및 CRUD |
| 실시간 채팅 | 안내사 ↔ 관광객 1:1 메시지 |
| 스팟 추천 | TourAPI + KakaoMap 기반 관광지 추천 |
| 긴급 연락 | 건강 데이터 연동, 긴급 상황 대응 |

<br>

## 기술 스택

### iOS (이 저장소)

| 구분 | 기술 | 선택 이유 |
|------|------|-----------|
| UI | SwiftUI | 선언형 UI, 빠른 프로토타이핑 |
| 반응형 | RxSwift / RxCocoa | Input/Output 패턴 기반 MVVM |
| 네트워크 | URLSession 직접 구현 | 동작 원리 이해 (Moya/Alamofire 미사용) |
| DI | 생성자 주입 (Protocol) | DIP 원칙 적용 (Swinject 미사용) |
| 보안 저장 | Keychain Services | 토큰 하드웨어 암호화 저장 |
| 지도 | KakaoMaps SDK | 공모전 필수 요구사항 |
| 관광 데이터 | TourAPI | 공모전 필수 요구사항 |
| 패키지 관리 | Swift Package Manager | |

### Backend

| 구분 | 기술 |
|------|------|
| 서버 | Python (별도 저장소) |
| API | RESTful API |

<br>

## 아키텍처

**Clean Architecture + MVVM**

```
┌──────────────────────────────────────────┐
│            Presentation Layer            │
│  ┌──────────┐       ┌────────────────┐   │
│  │   View   │ ───── │   ViewModel    │   │
│  │ (SwiftUI)│       │ (RxSwift I/O)  │   │
│  └──────────┘       └───────┬────────┘   │
├─────────────────────────────┼────────────┤
│              Domain Layer   │            │
│  ┌──────────┐       ┌───────┴────────┐   │
│  │  Entity  │       │    UseCase     │   │
│  │  (Model) │       │  (비즈니스 로직)   │   │
│  └──────────┘       └───────┬────────┘   │
│                             │ Protocol   │
├─────────────────────────────┼────────────┤
│               Data Layer    │            │
│  ┌───────────────┐   ┌──────┴─────────┐  │
│  │ NetworkService│   │   Repository   │  │
│  │ (URLSession)  │   │    (구현체)      │  │
│  └───────────────┘   └───────┬────────┘  │
│                      ┌───────┴────────┐  │
│                      │KeychainManager │  │
│                      └────────────────┘  │
└──────────────────────────────────────────┘
```

<br>

## 폴더 구조

```
HiTrip/
├── App/                          # 앱 진입점, 라우터
│   ├── HiTripApp.swift
│   ├── AppDelegate.swift
│   ├── AppRouter.swift
│   └── RootView.swift
├── Core/                         # 공통 인프라
│   ├── DI/                       # 의존성 주입 컨테이너
│   ├── Extensions/               # Color, String 등 Extension
│   ├── Network/                  # URLSession 래퍼, API 엔드포인트
│   └── Utils/                    # Keychain 등 유틸리티
├── Domain/                       # 비즈니스 로직 (순수 Swift)
│   ├── Entities/                 # 데이터 모델
│   ├── Repositories/             # Repository Protocol
│   └── UseCases/                 # 비즈니스 규칙
├── Data/                         # 데이터 접근 구현체
│   └── Repositories/             # Protocol 구현 (API + Keychain)
├── Features/                     # 기능별 UI
│   ├── Auth/
│   │   ├── ViewModels/
│   │   └── Views/
│   ├── Schedule/
│   │   ├── ViewModels/
│   │   └── Views/
│   └── Profile/
│       └── Views/
└── Resources/                    # Assets, 리소스 파일
```

<br>

## 구현 로드맵

### Phase 1 — 인증 플로우 ✅
- [x] Xcode 프로젝트 초기 설정
- [x] Core Network layer (URLSession + RxSwift)
- [x] Domain layer (Entity, Protocol, UseCase)
- [x] Data layer (Repository, Keychain)
- [x] Login UI + ViewModel + Design System
- [x] SignUp 4단계 플로우
- [x] Unit Tests (LoginUseCase + SignUpUseCase)

### Phase 2 — 일정 관리 + 프로필 ✅
- [x] Schedule Entity + Repository Protocol + UseCase
- [x] ScheduleRepository 메모리 기반 CRUD 구현
- [x] ScheduleViewModel (CRUD 상태 관리)
- [x] ScheduleListView / CreateView / DetailView
- [x] Schedule DI 연결 + HomeView 탭 교체
- [x] ProfileView (프로필 조회 + 로그아웃)
- [x] HomeView 프로필 탭 연결

### Phase 3 — 실시간 채팅
- [ ] WebSocket 기반 1:1 채팅
- [ ] 메시지 UI (안내사/관광객 뷰)

### Phase 4 — 지도 + 스팟 추천
- [ ] KakaoMaps SDK 연동
- [ ] TourAPI 관광지 검색

### Phase 5 — 건강 + 긴급 연락
- [ ] HealthKit 연동
- [ ] 긴급 연락 플로우

### Phase 6 — 마무리
- [ ] 푸시 알림 (APNs)
- [ ] 성능 최적화, 접근성

<br>

## 설치 및 실행

### 요구사항

- Xcode 16.0+
- iOS 16.6+
- Swift 5.0+

### 실행 방법

```bash
git clone https://github.com/Hi-Trip-team/Hi_Trip_app.git
cd Hi_Trip_app/HiTrip
open HiTrip.xcodeproj
```

> SPM 의존성(RxSwift, RxCocoa)은 프로젝트 열 때 자동으로 resolve됩니다.

<br>

## Git Convention

### Commit Message

```
feat:     새로운 기능 추가
fix:      버그 수정
refactor: 리팩토링 (기능 변경 없음)
test:     테스트 코드
chore:    빌드/설정 변경
docs:     문서 변경
style:    코드 포맷팅 (기능 변경 없음)
```

### Branch Strategy

```
main ── develop ── feature/기능명
                └─ fix/버그명
```

<br>

## 팀

| 역할 | 담당 |
|------|------|
| iOS 개발 | 이 저장소 |
| Backend (Python) | 별도 저장소 |

<br>

## 라이선스

이 프로젝트는 2025 관광데이터 활용 공모전 출품을 위해 제작되었습니다.
