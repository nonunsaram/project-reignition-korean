# v1.0.2 한국어 모드 빌드

현재 배포는 게임 소스나 DLL을 빌드하지 않습니다. 레거시 DLL 패치는 `legacy/v0.2` 또는 원래 `v0.2` 태그를 참고하세요.

1. Python과 Pillow, Godot 4.7 Standard를 준비합니다.
2. `translation/Locale.ko.csv`를 수정한 뒤 `korean-pack-project/Locale.ko.csv`에 동일하게 복사합니다. 두 사본이 일치해야 합니다.
3. 저장소 루트에서 아래 아틀라스 생성기를 실행합니다.

   ```powershell
   python scripts/build_korean_bonus_bitmap_font.py
   python scripts/build_korean_skill_select_bitmap_font.py
   ```

4. Godot에 `--headless --editor --path korean-pack-project --import --log-file <쓰기 가능한 절대 로그 경로>`를 전달해 CSV·폰트·아틀라스를 가져옵니다.
5. `Locale.ko.ko.translation` 생성 성공을 확인한 다음 `--headless --path korean-pack-project --script build_pack.gd --log-file <절대 로그 경로> -- <새 PCK 절대 출력 경로>`로 빌드합니다.
6. `verify_pack.gd`로 번역과 폰트 로딩을 확인하고 `verify_translation.gd`에 PCK 절대 경로를 전달해 CSV/TranslationServer 대조를 수행합니다. 두 스크립트 모두 `--headless --path korean-pack-project --script <스크립트 이름> --log-file <절대 로그 경로> -- <PCK 절대 경로>`로 실행합니다. 실제 게임 검수 후 배포하며 기존 배포본을 바로 덮어쓰지 마세요.

작업 환경에서 기본 `user://logs` 초기화 실패 후 signal 11이 발생한 사례가 있으므로 로그 경로와 쓰기 권한을 확인하세요. CSV 변경 뒤 예전 `.translation`을 재사용하면 수정이 반영되지 않습니다.

배포 파일은 Release 자산이며 `.godot`, import 캐시, 게임 파일, 사용자 세이브나 로그를 소스에 커밋하지 않습니다. `extras/100-percent/saves`만 별도로 공개한 생성 검수 데이터입니다.
