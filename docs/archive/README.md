# 보관 문서 (사용하지 말 것)

여기 있는 문서는 **모두 낡았습니다.** 이력 보관용으로만 남겨둡니다.
현재 API 스펙은 서버의 Swagger 문서를 보세요 — `http://100.79.220.29:18080/api/docs/`

## 왜 낡았나

2026년 5~6월에 작성됐고, 이후 API가 `/api/v1/` 네임스페이스로 개편되면서
아래 내용이 전부 현재와 맞지 않습니다.

| 문서 기준 | 현재 |
|---|---|
| `https://quokka-s-team-production.up.railway.app` | `http://100.79.220.29:18080` |
| `/api/auth/login/` | 여행객 `/api/v1/tourist/auth/login/` · 관리자 `/api/v1/staff/auth/login/` |
| `/api/auth/register/` | 관광객 계정은 관리자가 발급 (`/api/trips/{id}/tourists/issue-account/`) |
| 인증 단일 방식 | 여행객 Bearer 토큰 / 관리자 세션 쿠키 + CSRF 로 분리 |

## 파일

- `HiTrip_API_Requirements.{md,docx,pdf}` — 2026-05-25, 서버 재배포 요청 및 초기 API 목록
- `HiTrip_Backend_API_Request.pdf` — 2026-06-04
