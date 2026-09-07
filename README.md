# Project Reignition 한국어 모드

**한국어 모드 v0.3.1 · Project Reignition Windows v1.0.2 대응**

공식 언어 모드 기능으로 한국어 번역과 글꼴을 제공합니다. 압축을 풀고 **설치.bat을 더블클릭**하면 됩니다. 수동 설치도 `Korean.pck` 하나만 복사하면 됩니다. 예전 DLL 교체 설치기는 v1.0.1 이하용 레거시입니다.

## 다운로드

- [간편 설치 ZIP — 권장](https://github.com/nonunsaram/project-reignition-korean/releases/download/v0.3.1/Project-Reignition-Korean-v0.3.1-v1.0.2.zip)
- [한국어 모드 Korean.pck — 수동 설치](https://github.com/nonunsaram/project-reignition-korean/releases/download/v0.3.1/Korean.pck)
- [100% 세이브 — 선택 다운로드](https://github.com/nonunsaram/project-reignition-korean/releases/download/v0.3.1/Project-Reignition-100-percent-v1.0.2.zip)
- [v0.3.1 배포 페이지](https://github.com/nonunsaram/project-reignition-korean/releases/tag/v0.3.1) · [SHA-256 확인값](https://github.com/nonunsaram/project-reignition-korean/releases/download/v0.3.1/SHA256SUMS.txt)

GitHub의 `Source code` ZIP은 설치 파일이 아닙니다. 파일명에 `Project-Reignition-Korean`이 들어간 간편 설치 ZIP을 받으세요. 100% 세이브는 모드 사용에 필수가 아닙니다.

## 간편 설치 — 게임 v1.0.2

1. 간편 설치 ZIP을 새 폴더에 모두 압축 해제합니다. ZIP 안에서 바로 실행하지 마세요.
2. 게임을 완전히 종료하고 `설치.bat`을 더블클릭합니다.
3. 완료 메시지가 나오면 게임에서 `Options → Mods`의 **Language Mods**를 켜고 재시작합니다.
4. `Options → Language → Text Language`에서 **한국어**를 선택합니다.

기본 사용자 데이터 경로가 아닌 `saveLocation.txt`를 사용하는 경우 `Project Reignition.exe`가 있는 **게임 폴더를 `설치.bat` 위로 끌어다 놓으세요.** 설치기가 해당 설정의 위치를 읽습니다. 제거할 때도 같은 게임 폴더를 `제거.bat` 위로 끌어다 놓으면 됩니다.

설치기는 기존 `Korean.pck`가 다를 경우 사용자 데이터 폴더의 `ReignitionKorean_Backup_v0.3`에 백업합니다. `제거.bat`은 설치한 파일이 이후 바뀌지 않았을 때만 제거하고 이전 파일을 복원합니다. 게임 DLL·본편 PCK·세이브는 수정하지 않습니다.

## 수동 설치

1. 게임을 완전히 종료합니다.
2. 탐색기 주소 표시줄에 다음 경로를 붙여넣습니다.

   `%APPDATA%\Godot\app_userdata\Sonic and the Secret Rings Remake\mods\lang`

3. 이 폴더에 `Korean.pck`를 넣습니다. `mods` 또는 `lang` 폴더가 없으면 만드세요. 기존 `Korean.pck`는 다른 폴더에 백업한 뒤 교체하세요.
4. 게임에서 `Options → Mods`의 **Language Mods**를 켜고 게임을 다시 시작합니다.
5. `Options → Language → Text Language`에서 **한국어**를 선택합니다.

`saveLocation.txt`로 사용자 데이터 위치를 바꿨다면 **그 위치의 `mods\lang`**에 넣어야 합니다. 기본 설치 위치는 게임 실행 파일 옆이 아닙니다. Godot 설치, 폰트 개별 설치, DLL·본편 PCK 교체는 필요하지 않습니다.

한국어가 목록에 없으면 설치 경로, Language Mods 활성화 여부, 재시작 여부와 게임 버전을 확인하세요. `Korean.pck.pck` 등 파일 이름이 중복되지 않았는지도 확인하세요.

### 이전 DLL 패치에서 전환

v0.1/v0.2의 `설치.bat`을 v1.0.2에 실행하지 마세요. **새 폴더에 원본 게임 v1.0.2를 준비한 뒤** 위 방식으로 설치하는 것이 가장 확실합니다. 기존 게임 폴더에 섞인 DLL이나 레거시 백업 DLL을 v1.0.2로 복사하지 마세요. 예전 게임에 패치를 제거하려면 해당 버전의 제거기를 그 예전 게임 폴더에만 사용하세요. 사용자 데이터의 세이브는 보존하세요.

### 제거

게임을 종료한 뒤 설치 위치의 `Korean.pck`만 빼면 됩니다. 세이브나 다른 모드 파일은 삭제하지 마세요.

## 100% 세이브 — 선택 사항

레벨 99, 어드벤처 111개 금메달, 파이어 소울 129개, 세계 링 7개, 스킬 54개 확인, 스페셜북 업적 30개, 타임 어택 해금을 설정한 **검수용 생성 세이브**입니다. 실제 플레이로 달성한 기록이 아니며 모든 게임 요소의 완전 달성을 보장하는 의미는 아닙니다.

한국어 모드와 별도 ZIP으로 배포하며 `saves/save00.dat`, `saves/shared.dat`, 적용 안내만 포함합니다. 개인 설정·게임 파일·개인 세이브 백업은 포함하지 않습니다. **기존 기록을 보존하는 분리 프로필 적용을 권장**합니다.

→ [100% 세이브 적용·복원 방법](extras/100-percent/README.md)

## 변경 사항과 검수 범위

- v1.0.2 공식 언어 로더 사용. 게임 DLL과 본편 PCK를 수정하지 않습니다.
- Froggy 관련 3문장을 **개구리 군**으로 교정했습니다.
- 정상 재생성한 `.translation`을 사용하며, 별도 Translation 객체로 대사를 덮어쓰던 임시 코드는 없습니다.
- 한국어 본문·자막·메뉴용 폰트와 비트맵 글꼴을 포함합니다. 한글 글꼴 및 언어 이름 표시를 보정하는 스크립트는 PCK 안에 포함됩니다.
- 번역 CSV 2,413행과 실제 TranslationServer 결과 대조를 통과했습니다. 이 수에는 빈 번역 68행의 원문 키 반환 검사가 포함됩니다.
- 실제 v1.0.2 실행과 화면 확인을 수행했습니다. 모든 스테이지·다른 모드 조합·모든 화면을 전수 검사한 것은 아닙니다.
- 일부 실행 종료 시 객체 정리 경고가 기록되며, 모드를 끈 원본에서도 재현됐습니다.

`Korean.pck`: **15,355,600바이트**

SHA-256: `AF4E70DE3844933D10FEEF2B591B2DB59811886FF76DD344C90D48DD661804D2`

## 버전 호환성과 레거시

| 게임 버전 | 사용할 배포 | 설치 방식 |
| --- | --- | --- |
| v1.0.2 | [한국어 모드 v0.3.1](https://github.com/nonunsaram/project-reignition-korean/releases/tag/v0.3.1) | 설치.bat 또는 Korean.pck 수동 설치 |
| v1.0.1 | [레거시 패치 v0.2](https://github.com/nonunsaram/project-reignition-korean/releases/tag/v0.2) | 해당 버전 전용 DLL 설치기 |
| v1.0.0 | [레거시 패치 v0.1](https://github.com/nonunsaram/project-reignition-korean/releases/tag/v0.1) | 해당 버전 전용 DLL 설치기 |
| v1.0.3 이후 | 미검증 | 업데이트 후 호환성 확인 필요 |

향후 번역 키가 추가되면 번역 갱신이, 언어 로더·UI·폰트 경로가 변경되면 보조 코드 수정이 필요할 수 있습니다. 미래 버전 자동 호환은 보장하지 않습니다.

이전 소스와 설치 안내는 [legacy/v0.2](legacy/v0.2/README.md)에 보존했습니다. 기존 태그와 릴리스도 유지합니다.

## 개발 및 라이선스

[빌드 방법](BUILDING.md) · [소스 구성](SOURCE_NOTES.md) · [타사 고지](THIRD_PARTY_NOTICES.md)

번역 원본은 `translation/Locale.ko.csv`입니다. 게임 본편은 포함하지 않습니다. Project Reignition은 SEGA와 무관한 팬 프로젝트이며 관련 권리는 각 권리자에게 있습니다.
