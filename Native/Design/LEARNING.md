# 已實作：間隔複習、相似國旗、分區旅程

三項功能皆可從首頁「讓探索，變成記憶」進入，離線即可使用。新增內容與所有標籤支援繁體中文／英文。

## 間隔複習

每個國家的紀錄新增最近作答時間、下次到期時間與複習階段，保留既有答題次數和正確率。

- 第一次答對或到期後答對：依階段在 1、3、7、14、30 天後再出現，最高維持 30 天。
- 答錯：階段回到 0，10 分鐘後可再練。
- 提前練習仍計入正確率，但答對不延長下次到期時間、不提升階段。
- 首頁每 30 秒及回到前景時更新到期數；點擊複習時重新取得最新到期清單。
- 每局取最早到期的最多 50 面，不重複，完成後結算。沒有到期題目時顯示下一次時間。
- 熟悉標準改為階段至少 3；答錯會退出熟悉狀態。這是產品指標，不等同記憶成效保證。
- 舊版沒有排程的紀錄保留原始計分，初次升級後視為可複習，以建立新排程。
- 目前排程使用固定 24 小時天數及裝置時間；未建立通知、雲端同步或帳戶功能。

## 相似國旗對照

首批四組：愛爾蘭／象牙海岸、波蘭／印尼、澳洲／紐西蘭、羅馬尼亞／摩爾多瓦。

先隱藏名稱供主動回想，再揭曉兩面國旗名稱和辨識線索。點選練習後各出一題，四個選項一定包含另一面相似旗幟。不限時、作答後顯示對照，兩題後結算；作答會進入一般歷史與複習排程。

一般探索或複習若恰好混淆上述配對，答案回顧會直接顯示對照；限時模式在結算錯題中提供可展開的對照。圖鑑本身不計分，也不會因為揭曉答案就增加熟悉度。

辨識線索以本地旗幟圖片及以下官方資料核對，沒有加入不可靠的象徵意義故事：

- [Ireland – Kildare County Council](https://kildarecoco.ie/YourCouncil/Publications/Corporate/Flag%20Policy%20of%20Kildare%20County%20Council%20April%202024.pdf)
- [Côte d’Ivoire government](https://www.fonctionpublique.gouv.ci/assets/rubriques/_documentation/5_Symboles_Republique_CI20185.pdf)
- [Poland flag diagram](https://www.gov.pl/attachment/cbe84c7a-8d68-4958-8f66-bdf50e67e47b)
- [Indonesia government](https://indonesia.go.id/profile/konstitusi)
- [Australia PM&C](https://www.pmc.gov.au/honours-and-symbols/australian-national-symbols/australian-national-flag)
- [New Zealand Ministry for Culture & Heritage](https://www.mch.govt.nz/our-work/flags-anthems-and-emblems/new-zealand-flag)
- [Moldova Presidency](https://presedinte.md/eng/simbolurile-statului)

## 地圖分區旅程

六區：亞洲、歐洲、非洲、北美洲、南美洲、大洋洲。地圖採用 [Natural Earth 1:110m Admin 0 Countries](https://www.naturalearthdata.com/downloads/110m-cultural-vectors/)，包含 175 個國家及地區輪廓、國界線與經緯網格；資料隨 App 提供，可完全離線顯示。選取區域會高亮所屬國家，地圖標記和下方區域卡皆可操作。Natural Earth 資料屬 public domain；地圖供學習分區使用。

每局最多 10 面，先抽取未探索的國旗，再補熟悉階段較低的國旗；本局不重複。干擾選項也來自同一区域。完成後使用共同的成果頁與本局錯題重練。

分組以 [UN M49](https://unstats.un.org/unsd/methodology/m49/) 為參考；北美洲合併中美洲和加勒比海。台灣、科索沃沿用既有題庫並依地理區域分組；歐盟不是國家，保留在自由探索而不計入六區旅程。測試確認其他 197 個題庫代碼恰好屬於一區。

目前保存的是每面國旗的學習進度，不是尚未完成的旅程位置；中途退出再開始會重新選題。

## 驗證與預覽

回歸測試涵蓋舊資料讀寫、排程到期邊界、提前練習、階段上限、答錯重置、到期優先順序、六區完整性、旅程不重複及結束條件、相似旗幟必選干擾項。

Debug fixture routes: `journeys`, `comparisons`, `region-game`, `comparison-game`, `review`。加上 `--preview-revealed` 可在對照圖鑑顯示線索；預覽使用隔離資料。Release 不含預覽路由。

[區域地圖](Previews/journeys.png)

區域地圖已完成 iPhone 模擬器畫面檢查。對照卡、區域答題與到期複習已通過編譯及核心流程測試；真機觸覺、VoiceOver 和完整手動點擊／手勢仍需另外驗收。
