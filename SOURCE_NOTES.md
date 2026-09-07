# 소스 구성

현재 대상은 Project Reignition Windows v1.0.2입니다. 공식 모드 로더가 번역을 등록하므로 게임 DLL·본편 PCK 수정은 없습니다.

- `translation/Locale.ko.csv`: 현재 번역 원본. `korean-pack-project`의 사본과 동일하게 유지합니다.
- `korean-pack-project/staging/text korean.tres`: 본편 LocalizationResource 형식으로 ko 등록.
- `KoreanLocalization.gd.txt`: 폰트 처리기 생성. 별도 Translation 생성·등록 없음.
- `KoreanFontController.gd.txt`: 한글 Label 폰트, 일시정지 스타일, 언어 이름 표시를 적용. PCK에서는 KoreanFontWatcher.gd로 포함.
- `scripts`: 현재 CSV에서 한글 글리프를 수집하는 비트맵 아틀라스 생성기.
- `extras/100-percent`: 선택 다운로드용 생성 검수 세이브 및 분리 적용 안내.
- `installer`: v1.0.2용 PCK 설치·제거 스크립트. DLL과 세이브를 변경하지 않고 기존 PCK를 백업·복원합니다.
- `legacy/v0.2`: 과거 v1.0.1 DLL 패치 소스·설치기·번역·빌드 자료. 현재 게임에 적용하지 않습니다. 원래 폴더 배치가 필요한 과거 빌드는 v0.2 태그를 체크아웃하세요.

향후 로더 및 LocalizationResource API, Label 이름/종류, 본편 폰트 경로, 번역 키가 변경되면 재검수 또는 수정이 필요합니다. v1.0.3 이후 호환은 미검증입니다.
