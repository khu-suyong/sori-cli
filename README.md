# Sori CLI
> A CLI application for Sori

## Usage

- `status`: `auth`
- `auth`: `refresh`, `start`, `callback`
- `user`: `get`, `update`
- `workspace`: `list`, `create`, `get`, `folder-*`, `note-*`, `note-transcribe`
- `server`: `list`, `create`, `get`, `update`, `delete`

## Notes

- 기본 서버 주소는 `http://localhost:8080/api/v1` 입니다.
- 필요하다면 `SORI_BASE_URL` 환경 변수를 통해 기본 주소를 덮어쓸 수 있습니다.
- 토큰/설정은 기본적으로 `~/.config/sori/config.json` (또는 OS에 따른 설정 디렉터리) 에 저장되며 `SORI_CONFIG_PATH` 로 위치를 바꿀 수 있습니다.
