# 音樂與互動音效

Native 版的背景音樂和預設音效為 FlagMaster 原創程式合成音訊。裝有 Gamemaster Audio 素材的工作區可優先使用下列四個互動音效，並隨 App 離線播放。

## 選用素材

- 首頁背景：冒險主題旋律、寬廣和聲、左右移動的鐘琴分解音 → `music_home.m4a`
- 答題背景：街機式低頻脈衝、128 BPM 節拍與逐步加入的主旋律 → `music_game.m4a`
- 按鈕：極短的科幻木質提示音，僅用於實際遊戲操作 → `sfx_tap.wav`
- 答對：快速展開的明亮大調琶音 → `sfx_correct.wav`
- 答錯／逾時：圓潤的下降脈衝，清楚但不帶懲罰感 → `sfx_wrong.wav`
- 完成旅程：多層短號角式勝利旋律與高八度收尾 → `sfx_complete.wav`

兩首背景音樂為 192 kbps AAC；短音效保留 48 kHz 雙聲道 PCM WAV，以減少點擊後的播放延遲。App 使用 `AVAudioSession.Category.ambient`，遵循裝置靜音設定並允許和其他音訊混合。首頁與答題音樂以淡入方式切換；暫停及成果頁會降低背景音量。

## Gamemaster Audio 素材對應

首頁可使用音效包的 `Ω_Bonus_Music_16bit44kOnly/music_fun_funky_whistle_groove_loop.wav`。將它降低 3 dB 並轉為 192 kbps AAC，存為 `Native/FlagMaster/Resources/Audio/LocalMusic/music_home.m4a`。Xcode 會將本機替換曲打包，未安裝時使用專案內的首頁曲。`LocalMusic` 由 Git 忽略。

從 Pro Sound Collection 的 `User_Interface_Menu` 選用以下檔案，依右欄命名後放入 `Native/FlagMaster/Resources/Audio/LocalEffects/`。

| 時機 | 音效包檔名 | App 檔名 |
| --- | --- | --- |
| 操作 | `ui_button_simple_click_06.wav` | `sfx_tap.wav` |
| 答對 | `ui_menu_button_confirm_02.wav` | `sfx_correct.wav` |
| 答錯或單題逾時 | `ui_menu_button_error_06.wav`（降低 3 dB） | `sfx_wrong.wav` |
| 完成回合 | `ui_menu_popup_message_reward_01.wav` | `sfx_complete.wav` |

Xcode 會將 `LocalEffects` 隨 `Audio` 資源資料夾打包。此資料夾由 Git 忽略，其他工作區可依照上表安裝，缺少的音效會使用隨專案提供的預設素材。

設定頁分別保存背景音樂音量、互動音效音量與觸覺回饋。Debug 畫面預覽會關閉三者，避免自動化截圖播放聲音。
