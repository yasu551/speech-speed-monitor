# speech-speed-monitor

macOS用のメニューバーアプリです。Zoomなどで会話している最中に、話速が一定値を超えたら警告音を鳴らします。

## 何を作ったか

このリポジトリには、以下を満たす最小構成のmacOSアプリを入れています。

- メニューバー常駐
- マイク入力を監視
- 直近数秒の音声から話速を推定
- 早口と判定したら警告音を鳴らす
- しきい値と警告間隔をUIから調整可能

実装はSwiftUIとAVFoundationベースです。

## 仕組み

厳密な音声認識ではなく、軽量なリアルタイム推定です。

- マイク入力のRMS、ピーク、ゼロクロス率から発話らしいフレームを検出
- 直近3秒の中で、短い無音区間で区切られる発話セグメント数を数える
- 発話セグメント数を発話時間で割って、syllables/sec相当の近似値として扱う
- 近似値がしきい値を超えたら警告音を再生

この方法は軽くてリアルタイム性がありますが、日本語のモーラ数や実際の単語数を正確に測るものではありません。

## ファイル構成

- [SpeechSpeedMonitor.xcodeproj](SpeechSpeedMonitor.xcodeproj)
- [SpeechSpeedMonitor/SpeechSpeedMonitorApp.swift](SpeechSpeedMonitor/SpeechSpeedMonitorApp.swift)
- [SpeechSpeedMonitor/AppState.swift](SpeechSpeedMonitor/AppState.swift)
- [SpeechSpeedMonitor/ContentView.swift](SpeechSpeedMonitor/ContentView.swift)
- [SpeechSpeedMonitor/SpeechRateMonitor.swift](SpeechSpeedMonitor/SpeechRateMonitor.swift)
- [SpeechSpeedMonitor/BeepPlayer.swift](SpeechSpeedMonitor/BeepPlayer.swift)

## 使い方

1. macOSでXcodeを開く
2. [SpeechSpeedMonitor.xcodeproj](SpeechSpeedMonitor.xcodeproj) を開く
3. 実行する
4. 初回起動時にマイク権限を許可する
5. メニューバーのアイコンから監視を開始する

## 推奨調整

- まずは警告しきい値を5.2前後から試す
- 警告が多すぎるなら6.0前後まで上げる
- 反応が鈍いなら4.5前後まで下げる
- クールダウンは4秒前後が無難

## 制約

- macOS専用です
- この実装は「話速の厳密測定」ではなく「早口の兆候検出」です
- Zoomの相手の声も同じマイク系統に入る環境では誤検知し得ます
- AirPodsやマイクのノイズ抑制設定で感度が変わります
- Linuxコンテナ上ではXcodeビルド確認はできません

## 次にやると良い改善

- Voice Processing I/Oやより強いVADを使って誤検知を減らす
- 自分の声だけを取りやすい入力デバイス前提に調整画面を追加する
- 警告音の代わりに短いクリック音や通知表示を選べるようにする
- 将来的にSpeech frameworkで発話内容を使った速度推定に切り替える