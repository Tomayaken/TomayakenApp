# tomayaken_app

## 近くの避難所

起動後はアンケート画面を表示します。災害対応中に「避難所一覧」ボタンを押すと、現在地を取得して避難所を距離順に表示します。
アンケート送信は現在地取得のきっかけにはなりません。
アンケート内容のサーバー送信は既存どおり未実装です。
位置情報は一覧の取得時だけ使用します。拒否時は案内ダイアログを表示し、再取得できます。
Chromeではサイトの位置情報を許可してください（HTTPSまたはlocalhostが必要）。

### 災害開始の検知

- スプラッシュ終了後、`GET /api/v1/disasters/active`を確認します。
- アプリ表示中は、応答完了から30秒後に次の確認を行います。バックグラウンドでは停止し、復帰時に再確認します。
- `{"disaster": null}`ならGPS取得も避難所APIへの通信も行いません。
- `disaster.status == "active"`を検知したら「避難所一覧」ボタンを表示します。自動遷移やGPS取得は行いません。
- ボタンを押したときだけ一覧を開き、GPSを取得します。一覧から戻った場合もボタンから再表示できます。
- 災害が終了したら、その災害の一覧と案内ダイアログを閉じます。新しい災害IDは再び自動検知します。
- 通信失敗を災害開始・終了として扱いません。災害の確認処理だけで位置情報の取得は開始しません。
- **アプリ終了中の通知・バックグラウンドでの自動取得は未実装**です。
  OpenAPIにプッシュ通知やリアルタイム購読の仕様がないため、表示中の定期確認で対応しています。

### API接続（OpenAPI対応済み・実サーバーの疎通は未確認）

接続先はコードへ固定せず、実行時に指定します。

```sh
flutter run -d chrome --dart-define=API_BASE_URL=https://YOUR_API_HOST
```

`YOUR_API_HOST`は実際のAPIホストに置き換えてください。
VS Codeから実行する場合は、既存の起動設定の`toolArgs`に
`"--dart-define=API_BASE_URL=https://YOUR_API_HOST"`を指定できます。
API未設定時は災害確認エラーを表示し、GPS取得を開始しません。架空の災害や避難所で補完しません。
Webで別ホストに接続する場合は、API側でアプリのオリジンに対するCORS設定が必要です。

2026-11-17に共有された[OpenAPI仕様](https://www.openapiviewer.com/view/2026-11-17T04-34-40-553Z--11d35c7c9c7c95adfdd83d6f38f473f1d5801cd6350dd0e80a14884b24f9df88--openapi-json)に準拠しています。
仕様に記載されたローカルサーバーは`http://localhost:3000`です。
ローカルサーバーを別途起動し、`--dart-define=API_BASE_URL=http://localhost:3000`を指定してください。
AndroidエミュレーターからPCに接続するときは、通常`localhost`ではなく`10.0.2.2`が必要です。
Android/iOSの平文HTTP許可は追加していないため、実機接続ではHTTPSを使ってください。

- `GET /api/v1/disasters/active`（認証不要）で災害の開始・終了を判定
- `GET /api/v1/shelters/nearby?latitude=35.0&longitude=139.0&limit=20`（認証不要）で最大20件取得
- 避難所レスポンスは`items`を持つオブジェクト
- レスポンス例（テスト用の架空データ）:

```json
{
  "items": [{
    "name": "サンプル避難所",
    "distanceMeters": 251,
    "capacity": 100,
    "currentOccupancy": 40,
    "isOverCapacity": false
  }]
}
```

距離はAPIの`distanceMeters`を使って昇順に並べ替えます。満員も一覧から除外しません。
`isOverCapacity: true`または滞在人数が収容人数以上なら「満員」と表示します。

### 端末別の準備

- Android: 通信・おおよその位置・正確な位置の権限をManifestに追加済み。
- iOS: 使用中の位置情報の説明文をInfo.plistに追加済み。Swift Package Managerで
  ビルドする場合は`BYPASS_PERMISSION_LOCATION_ALWAYS=1 flutter build ios`で
  常時位置情報の要求を無効にしてください。実機ビルドは未確認です。
- Windows: プラグイン用のシンボリックリンク生成にはWindowsの開発者モードが必要です。
  Chrome実行とテストは、依存関係の取得後に`--no-pub`で検証できます。

### テスト

```sh
flutter test --no-pub
```

災害の有無・開始/終了・重複検知・アプリの背景移行に加え、
位置情報やAPIレスポンスを差し替え、権限拒否・距離順・満員表示・通信失敗・再取得を検証します。
実際のGPSとAPIの疎通確認は、端末およびAPIの準備後に別途行ってください。

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
