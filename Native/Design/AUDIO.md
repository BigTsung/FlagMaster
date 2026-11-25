# 音樂與互動音效

Native 版使用九首背景配樂與八種互動音效。音檔離線播放；本機 Gamemaster 素材優先，缺少時使用專案內的原創合成素材。

## 背景情境

| 情境 | App 檔名 | 本機來源 |
| --- | --- | --- |
| 開場、首頁、圖鑑、學習紀錄與設定 | `music_home.m4a` | `music_candyland.wav` |
| 無盡模式 | `music_learning.m4a` | `music_bytes_the_retro_adventure 1.wav`（4.5 kHz 低通） |
| 限時挑戰 | `music_game.m4a` | `music_fun_crazy_circus.wav` |
| 極速模式 | `music_speed_round.m4a` | 原創合成循環 |
| 兩次機會 | `music_two_lives.m4a` | `music_fun_funky_toadstool.wav` |
| 間隔複習與錯題重練 | `music_review.m4a` | 原創合成循環 |
| 區域旅程 | `music_region.m4a` | 原創合成循環 |
| 相似國旗 | `music_comparison.m4a` | 原創合成循環 |
| 教學圖卡 | `music_cards.m4a` | `music_kids_play_loop_03.wav` |

所有背景配樂的響度目標均為 -23 LUFS，並共用同一個播放增益。區域旅程與相似國旗從選單進入題目時接續播放。不同曲目交叉淡化 0.8 秒，淡出後停止舊播放器。

## 互動與優先順序

| 時機 | Gamemaster 素材路徑 | App 檔名 | 最長秒數／RMS 目標 dBFS |
| --- | --- | --- | --- |
| 遊戲操作 | `Collectibles_Items_Powerup/collect_coin_03.wav` | `sfx_tap.wav` | 0.20 / -25 |
| 答對 | `Collectibles_Items_Powerup/chime_tinkle_wood_bell_positive_04.wav` | `sfx_correct.wav` | 0.72 / -21 |
| 答錯 | `Collectibles_Items_Powerup/collect_coin_05.wav` | `sfx_wrong.wav` | 0.34 / -23 |
| 單題逾時 | `Collectibles_Items_Powerup/collect_item_hurry_out_of_time_01.wav` | `sfx_timeout.wav` | 0.60 / -23 |
| 倒數 | `Collectibles_Items_Powerup/points_ticker_bonus_no_score_01.wav` | `sfx_countdown.wav` | 0.50 / -27 |
| 完成有限題數的練習或快問快答 | `Collectibles_Items_Powerup/jingle_chime_01_positive.wav` | `sfx_complete.wav` | 1.80 / -20 |
| 主動結束、限時挑戰時間到 | `Collectibles_Items_Powerup/jingle_chime_11_positive.wav` | `sfx_end.wav` | 0.90 / -23 |
| 兩次機會生命耗盡 | `Collectibles_Items_Powerup/jingle_chime_16_negative.wav` | `sfx_game_over.wav` | 1.20 / -23 |

- 遊戲規則發出帶序號的語意事件，連續答對仍能各自播放；重複點擊或重複結束不發出新事件。資料錯誤不播放獎勵音。
- 限時挑戰最後三秒每秒提醒一次，快問快答僅最後一秒提醒。答案展示期間不提示，暫停時停止計時與現有音效，不補播漏掉的倒數。
- 優先順序為結算 > 答題 > 點擊／倒數；一次只播放一個音效。低優先音效不能打斷高優先回饋。
- 暫停、恢復、離開遊戲與 App 進入背景時停止現有音效。關閉音效音量立即停止播放。
- 答案按鈕只播放答案結果，一般資料瀏覽維持安靜。

## 安裝與重建

需要 Python 3 與 ffmpeg。從專案根目錄執行：

```sh
python3 Native/Scripts/prepare_audio.py --pack '/Users/circle/dev/assets/audios/Gamemaster Audio - Pro Sound Collection'
```

腳本從原始素材重新產生 `LocalEffects` 與 `LocalMusic`，不改動素材包。短音效去除開頭靜音、限制長度、淡入淡出，以 RMS 整理音量並將峰值限制在 -3 dBFS；短音效使用 48 kHz 單聲道 PCM WAV。背景配樂以兩階段正規化對齊 -23 LUFS，真峰值上限為 -3 dBTP。所有曲目依使用者的背景音樂音量設定播放。

`LocalEffects` 與 `LocalMusic` 由 Git 忽略，但 Xcode 會隨整個 `Audio` 資料夾打包。其他工作區需執行上面的安裝指令才能取得相同的 Gamemaster 配置；無素材包時仍有全部音效與九首隨 App 提供的配樂。

重建本次新增的原創備援素材：

```sh
python3 Native/Scripts/prepare_audio.py --generate-fallbacks --generate-mode-music
```

`AVAudioSession.Category.ambient` 遵循裝置靜音設定並允許和其他音訊混合。設定頁分別保存背景音樂、互動音效音量與觸覺回饋。Debug 畫面預覽預設關閉聲音與觸覺。
