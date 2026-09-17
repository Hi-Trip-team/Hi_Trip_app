# HiTrip iOS 앱 — 필요 API 목록

> **작성일:** 2026-05-25
> **대상:** 백엔드 서버 담당
> **Base URL:** `https://quokka-s-team-production.up.railway.app`

---

## 1. 현재 상태: 서버 접속 불가

서버가 `404 Application not found`를 반환하고 있습니다.
iOS 앱에서 모든 API 호출이 실패하는 상태이므로, **서버 재배포가 우선 필요**합니다.

---

## 2. 이미 연결 완료된 API (서버 복구 시 바로 동작)

| 도메인 | Method | Endpoint | 용도 |
|--------|--------|----------|------|
| Auth | POST | `/api/auth/login/` | 로그인 |
| Auth | POST | `/api/auth/register/` | 회원가입 |
| Auth | POST | `/api/auth/logout/` | 로그아웃 |
| Auth | GET | `/api/auth/profile/` | 프로필 조회 |
| Auth | PUT | `/api/auth/profile/` | 프로필 수정 |
| Auth | GET | `/api/auth/travelers/` | 여행객 목록 |
| Auth | GET | `/api/auth/staff/` | 스태프 목록 |
| Trips | GET | `/api/trips/` | 여행 목록 |
| Trips | POST | `/api/trips/` | 여행 생성 |
| Trips | GET | `/api/trips/:id/` | 여행 상세 |
| Trips | PUT | `/api/trips/:id/` | 여행 수정 |
| Trips | DELETE | `/api/trips/:id/` | 여행 삭제 |
| Trips | POST | `/api/trips/:id/assign-manager/` | 매니저 배정 |
| Participants | GET | `/api/trips/:trip_pk/participants/` | 참여자 목록 |
| Participants | POST | `/api/trips/:trip_pk/participants/` | 참여자 추가 |
| Schedules | GET | `/api/trips/:trip_pk/schedules/` | 일정 목록 |
| Schedules | POST | `/api/trips/:trip_pk/schedules/` | 일정 생성 |
| Schedules | GET | `/api/trips/:trip_pk/schedules/:id/` | 일정 상세 |
| Schedules | PUT | `/api/trips/:trip_pk/schedules/:id/` | 일정 수정 |
| Schedules | DELETE | `/api/trips/:trip_pk/schedules/:id/` | 일정 삭제 |
| Schedules | POST | `/api/trips/:trip_pk/schedules/rebalance-day/` | AI 일정 재조정 |
| Places | GET | `/api/places/` | 장소 목록 |
| Places | GET | `/api/places/:id/` | 장소 상세 |
| Recommendations | GET | `/api/recommendations/` | AI 추천 장소 |
| Categories | GET | `/api/categories/` | 카테고리 목록 |
| Categories | GET | `/api/categories/:id/` | 카테고리 상세 |

---

## 3. 신규 필요 API (현재 서버에 없음)

### 3-1. 할일(Todo) CRUD — 우선순위: 높음

앱에서 여행별 할일 관리 기능이 있으나, 서버 API가 없어 로컬 저장 중입니다.

| Method | Endpoint | Request Body | Response |
|--------|----------|-------------|----------|
| GET | `/api/trips/:trip_pk/todos/` | — | `[Todo]` |
| POST | `/api/trips/:trip_pk/todos/` | `{ title, section, date, is_completed }` | `Todo` |
| PUT | `/api/trips/:trip_pk/todos/:id/` | `{ title, section, date, is_completed }` | `Todo` |
| DELETE | `/api/trips/:trip_pk/todos/:id/` | — | `204` |

**Todo 모델:**
```json
{
  "id": 1,
  "title": "여권 챙기기",
  "section": "before_trip",
  "date": "2025-07-01",
  "is_completed": false,
  "trip": 1,
  "created_at": "2025-06-15T10:00:00Z"
}
```
- `section` 값: `"before_trip"`, `"during_trip"`, `"after_trip"`

---

### 3-2. 이벤트(Event) CRUD — 우선순위: 높음

캘린더에 표시되는 개인 일정 이벤트. 서버 API 없이 로컬 저장 중입니다.

| Method | Endpoint | Request Body | Response |
|--------|----------|-------------|----------|
| GET | `/api/trips/:trip_pk/events/` | — | `[Event]` |
| POST | `/api/trips/:trip_pk/events/` | `{ title, start_time, end_time, category }` | `Event` |
| PUT | `/api/trips/:trip_pk/events/:id/` | `{ title, start_time, end_time, category }` | `Event` |
| DELETE | `/api/trips/:trip_pk/events/:id/` | — | `204` |

**Event 모델:**
```json
{
  "id": 1,
  "title": "공항 출발",
  "start_time": "2025-07-01T09:00:00Z",
  "end_time": "2025-07-01T11:00:00Z",
  "category": "transport",
  "trip": 1
}
```
- `category` 값: `"meal"`, `"activity"`, `"transport"`, `"accommodation"`, `"other"`

---

### 3-3. 공지사항(Notice) — 우선순위: 높음

여행사 → 여행객에게 전달하는 공지. 홈 화면에 대표 공지로 노출됩니다.

| Method | Endpoint | Request Body | Response |
|--------|----------|-------------|----------|
| GET | `/api/trips/:trip_pk/notices/` | — | `[Notice]` |
| POST | `/api/trips/:trip_pk/notices/` | `{ title, content, is_important, is_representative }` | `Notice` |
| GET | `/api/trips/:trip_pk/notices/:id/` | — | `Notice` |

**Notice 모델:**
```json
{
  "id": 1,
  "title": "집합 안내",
  "content": "오전 9시 로비 집합 — 우산 꼭 챙겨주세요!",
  "date": "2025-07-01T08:00:00Z",
  "is_important": true,
  "is_representative": true,
  "trip": 1
}
```

---

### 3-4. 미션(Mission) — 우선순위: 중간

AI가 생성하는 일일 미션. 홈 화면 "오늘의 미션" 영역에 표시됩니다.

| Method | Endpoint | Request Body | Response |
|--------|----------|-------------|----------|
| GET | `/api/trips/:trip_pk/missions/` | — | `[Mission]` |
| GET | `/api/trips/:trip_pk/missions/today/` | — | `[Mission]` |
| POST | `/api/trips/:trip_pk/missions/` | `{ content, date }` | `Mission` |
| PATCH | `/api/trips/:trip_pk/missions/:id/` | `{ is_completed: true }` | `Mission` |

**Mission 모델:**
```json
{
  "id": 1,
  "content": "제주 명소 3곳 방문하기",
  "date": "2025-07-01",
  "is_completed": false,
  "trip": 1
}
```

---

### 3-5. 채팅(Chat) — 우선순위: 중간

여행 그룹 내 채팅 기능. 현재 메모리 저장(Mock)으로 동작 중입니다.

| Method | Endpoint | Request Body | Response |
|--------|----------|-------------|----------|
| GET | `/api/chat/rooms/` | — | `[ChatRoom]` |
| POST | `/api/chat/rooms/` | `{ name, participant_ids }` | `ChatRoom` |
| DELETE | `/api/chat/rooms/:id/` | — | `204` |
| GET | `/api/chat/rooms/:room_id/messages/` | `?page=1` | `[Message]` |
| POST | `/api/chat/rooms/:room_id/messages/` | `{ content }` | `Message` |
| POST | `/api/chat/rooms/:room_id/read/` | — | `200` |

**ChatRoom 모델:**
```json
{
  "id": 1,
  "name": "제주 여행방",
  "participants": [1, 2, 3],
  "last_message": "내일 일정 확인해주세요",
  "last_message_at": "2025-07-01T18:30:00Z",
  "unread_count": 3
}
```

**Message 모델:**
```json
{
  "id": 1,
  "room": 1,
  "sender": 1,
  "sender_name": "김안내",
  "content": "내일 일정 확인해주세요",
  "created_at": "2025-07-01T18:30:00Z",
  "is_read": false
}
```

> 실시간 기능은 추후 WebSocket으로 확장 예정. 우선 REST API로 구현 요청합니다.

---

### 3-6. 긴급 연락처(Emergency) — 우선순위: 낮음

프리셋 번호(112, 119 등) + 여행사 커스텀 연락처. 현재 하드코딩 상태입니다.

| Method | Endpoint | Request Body | Response |
|--------|----------|-------------|----------|
| GET | `/api/trips/:trip_pk/emergency-contacts/` | — | `[EmergencyContact]` |
| POST | `/api/trips/:trip_pk/emergency-contacts/` | `{ name, phone, category }` | `EmergencyContact` |
| PUT | `/api/trips/:trip_pk/emergency-contacts/:id/` | `{ name, phone, category }` | `EmergencyContact` |
| DELETE | `/api/trips/:trip_pk/emergency-contacts/:id/` | — | `204` |

**EmergencyContact 모델:**
```json
{
  "id": 1,
  "name": "현지 가이드",
  "phone": "010-1234-5678",
  "category": "guide",
  "is_preset": false,
  "trip": 1
}
```
- `category` 값: `"police"`, `"fire"`, `"ambulance"`, `"embassy"`, `"guide"`, `"hotel"`, `"custom"`

---

### 3-7. 인증 보조 API — 우선순위: 낮음

| Method | Endpoint | Request Body | Response | 용도 |
|--------|----------|-------------|----------|------|
| POST | `/api/auth/token/refresh/` | `{ token }` | `{ token }` | 토큰 갱신 |
| POST | `/api/auth/check-nickname/` | `{ nickname }` | `{ is_available, message }` | 닉네임 중복확인 |

---

## 4. 요약

| 구분 | API 수 | 상태 |
|------|--------|------|
| 연결 완료 | 26개 | 서버 복구 시 즉시 동작 |
| 신규 필요 (높음) | 12개 | Todo, Event, Notice |
| 신규 필요 (중간) | 10개 | Mission, Chat |
| 신규 필요 (낮음) | 6개 | Emergency, Auth 보조 |
| **합계** | **54개** | |

### 요청 사항

1. **서버 재배포** — 현재 404 상태, 복구 필요
2. **높음 우선순위 API 먼저** — Todo, Event, Notice (홈 화면 핵심 기능)
3. **응답 형식 통일** — snake_case JSON, ISO8601 날짜, 페이지네이션은 `?page=N`
4. **에러 응답 형식** — `{ "status": "error", "code": 400, "message": "..." }` 형태 권장
