# tomayaken_app

A new Flutter project.

## 利用者登録

初回起動時にUUID v4を生成して端末へ保存し、入力された名前を
`PUT /api/v1/users/{userId}` へ送信します。登録に成功すると初回アンケートへ
遷移します。UUIDは`shared_preferences`に保存されるため、アプリを再起動しても
同じ利用者IDを使用します。

APIの接続先は`--dart-define=API_BASE_URL=<URL>`で指定できます。未指定時は
`http://localhost:8080`を使用します。

```shell
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
