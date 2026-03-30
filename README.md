# 각도기 (Protractor App)

카메라 화면 위에 반원형 각도기를 겹쳐서, 실제 장면과 함께 각도를 재볼 수 있는 Flutter 앱입니다.

---

## 주요 기능

| | |
|--|--|
| **라이브 카메라** | 후면 카메라 프리뷰 위에 각도기 오버레이 |
| **제스처** | 한 손가락으로 위치·회전·크기 조절 (핀치/회전) |
| **촬영·배경** | 셔터로 현재 화면을 고정하거나, 갤러리에서 이미지를 불러와 배경으로 사용 |
| **초기화** | 각도기 위치·회전·크기를 기본값으로 되돌리기 |
| **세로 고정** | 세로 모드만 사용 (`portraitUp`) |

각도기는 0°~180° 눈금과 중앙 기준선을 `CustomPainter`로 그립니다.

---

## 기술 스택

- [Flutter](https://flutter.dev/) (Dart SDK `^3.11.4`)
- [`camera`](https://pub.dev/packages/camera) — 카메라 프리뷰·촬영
- [`image_picker`](https://pub.dev/packages/image_picker) — 갤러리에서 이미지 선택

---

## 사전 요구 사항

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 설치
- **iOS / Android 실기기 또는 에뮬레이터** — 카메라·갤러리 기능은 모바일에서 테스트하는 것이 가장 자연스럽습니다.
- **macOS 데스크톱**으로 실행할 경우: Xcode가 설치되어 있고 `xcodebuild`가 동작해야 합니다 (`xcode-select`로 개발자 디렉터리 지정).
- **웹**은 카메라·파일 접근이 브라우저·권한 설정에 따라 제한될 수 있습니다.

---

## 실행 방법

```bash
cd protractor_app
flutter pub get
flutter run
```

연결된 기기가 여러 개이면 목록에서 선택하거나, 특정 기기를 지정할 수 있습니다.

```bash
flutter devices          # 목록 확인
flutter run -d chrome    # 웹 (Chrome)
flutter run -d macos       # macOS 데스크톱
```

---

## 프로젝트 구조

```
lib/
  main.dart    # 앱 진입점, 카메라·각도기 UI·ProtractorPainter
```

---

## 버전

`pubspec.yaml` 기준: **1.0.0+1**

---

## 참고

- Flutter 공식 문서: [https://docs.flutter.dev/](https://docs.flutter.dev/)
- 첫 실행 전 `flutter doctor`로 환경을 점검하면 기기·라이선스 문제를 줄일 수 있습니다.
