# tomayaken_app

A new Flutter project.

## 避難所マップ

アプリ起動後、現在地を中心にGoogle Mapsを表示し、
`GET /api/v1/shelters` で取得した避難所をピン表示します。ピンを選択すると
`GET /api/v1/shelters/{shelterId}` から詳細を取得してカードに表示します。

APIの接続先は`--dart-define=API_BASE_URL=<URL>`で指定できます。未指定時は
`http://localhost:8080`を使用します。

Google Mapsを利用するには、Google CloudでMaps SDK for Android/iOSを有効化し、
APIキーを設定してください。Androidは`-PgoogleMapsApiKey=<KEY>`、
iOSは`Info.plist`の`GOOGLE_MAPS_API_KEY`へ設定します。APIキーはリポジトリへ
コミットしないでください。

### 後で実施する設定

- [ ] Google Cloudプロジェクトを作成または選択する
- [ ] Maps SDK for Android / iOSを有効化する
- [ ] APIキーを発行し、AndroidとiOSへ安全に設定する
- [ ] APIキーのアプリ制限・API制限・課金設定を確認する
- [ ] 実機またはエミュレータでGoogle Mapsの表示を確認する

```shell
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

避難所データには少なくとも`id`（または`shelterId`）、`name`（または
`shelterName`）、`latitude`、`longitude`が必要です。混雑状況は`crowding`、
`congestion`、`status`のいずれか、距離は`distanceMeters`または`distance`を
利用できます。

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
