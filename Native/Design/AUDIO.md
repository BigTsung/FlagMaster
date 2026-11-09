# 音樂與互動音效

Native 版以復古電子冒險（chiptune）為本機聲音主題，使用三種背景情境與八種互動音效。音檔離線播放；本機 Gamemaster 素材優先，缺少時使用專案內的原創合成素材。

## 背景情境

| 情境 | App 檔名 | 本機來源 |
| --- | --- | --- |
| 首頁、圖鑑、護照與設定 | `music_home.m4a` | `music_bytes_the_retro_adventure 1.wav` |
| 無盡、複習、區域旅程、相似旗與錯題重練 | `music_learning.m4a` | `music_bytes_the_retro_adventure 1.wav`（柔化學習版） |
| 限時、快問快答、兩次機會 | `music_game.m4a` | `music_8bit_jammer.wav` |

首頁保留指定曲目的旋律與速度；學習版使用同曲，加入 4.5 kHz 低通並降低 3 LU 的響度目標，讓主旋律較不搶注意力。挑戰模式使用另一首 8-bit 曲目。學習情境音量較低；同一情境切頁不重啟曲目。曲目切換交叉淡化 0.8 秒，淡出完成後停止舊播放器。暫停與成果頁降低音樂音量。背景音樂使用 192 kbps AAC；新增的原創學習備援曲是 32 秒稀疏和弦循環。

## 互動與優先順序

| 時機 | Gamemaster 素材路徑 | App 檔名 | 最長秒數／RMS 目標 dBFS |
| --- | --- | --- | --- |
| 遊戲操作 | `Retro_Classic/Menu_UI_Beeps/retro_ui_menu_blip_click_01.wav` | `sfx_tap.wav` | 0.12 / -25 |
| 答對 | `Retro/retro_beeps_success_04.wav` | `sfx_correct.wav` | 0.36 / -21 |
| 答錯 | `Retro_Classic/Menu_UI_Beeps/retro_ui_menu_error_03.wav` | `sfx_wrong.wav` | 0.30 / -23 |
| 單題逾時 | `Retro_Classic/Menu_UI_Beeps/retro_simple_beep_03.wav` | `sfx_timeout.wav` | 0.36 / -23 |
| 倒數 | `Retro_Classic/Menu_UI_Beeps/retro_ui_menu_short_beep_04.wav` | `sfx_countdown.wav` | 0.10 / -27 |
| 完成有限題數的練習或快問快答 | `Retro/retro_beeps_success_02.wav` | `sfx_complete.wav` | 1.30 / -20 |
| 主動結束、限時挑戰時間到 | `Retro_Classic/Menu_UI_Beeps/retro_ui_menu_popup_02.wav` | `sfx_end.wav` | 0.26 / -23 |
| 兩次機會生命耗盡 | `Retro/retro_fail_sound_02.wav` | `sfx_game_over.wav` | 0.80 / -23 |

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

腳本從原始素材重新產生 `LocalEffects` 與 `LocalMusic`，不改動素材包。短音效去除開頭靜音、限制長度、淡入淡出，以 RMS 整理音量並將峰值限制在 -3 dBFS；短音效使用 48 kHz 單聲道 PCM WAV。首頁與挑戰音樂以 -23 LUFS／-3 dBTP 為正規化目標，學習版則為 -26 LUFS／-3 dBTP；播放器另外依情境和使用者偏好調整音量。數值正規化不能代替真機聽感檢查。

`LocalEffects` 與 `LocalMusic` 由 Git 忽略，但 Xcode 會隨整個 `Audio` 資料夾打包。其他工作區需執行上面的安裝指令才能取得相同的 Gamemaster 配置；無素材包時仍有全部音效與三首原創備援音樂。

重建本次新增的原創備援素材：

```sh
python3 Native/Scripts/prepare_audio.py --generate-fallbacks
```

`AVAudioSession.Category.ambient` 遵循裝置靜音設定並允許和其他音訊混合。設定頁分別保存背景音樂、互動音效音量與觸覺回饋。Debug 畫面預覽預設關閉聲音與觸覺。
