# DockTamer 任務清單

## 已完成任務

- [x] 1. 添加「開機自動啟動」(Launch at Login) 功能
  - [x] 1.1 在 AppDelegate.swift 中新增 `launchAtLoginItem` property
  - [x] 1.2 在 setupMenuBar() 中新增選單項目，放在 toggleItem 和 permissionItem 之間
  - [x] 1.3 新增 `isLaunchAtLogin()` 和 `setLaunchAtLogin(_ enabled: Bool)` 方法
  - [x] 1.4 新增 `toggleLaunchAtLogin()` 選單動作方法
  - [x] 1.5 新增英文字串 "Menu.LaunchAtLogin" = "Launch at Login"
  - [x] 1.6 新增繁中字串 "Menu.LaunchAtLogin" = "開機自動啟動"

- [x] 2. 創建 Localizable.strings 檔案
  - [x] 1.1 創建 `zh-Hant.lproj/Localizable.strings` (繁體中文)
  - [x] 1.2 創建 `en.lproj/Localizable.strings` (英文備援)

- [x] 2. 更新 project.yml
  - [x] 2.1 確保本地化資源被包含在專案中

- [x] 3. 更新 Swift 程式碼
  - [x] 3.1 將 AppDelegate.swift 中的西班牙語硬編碼字串替換為 `NSLocalizedString`

- [x] 4. 驗證與測試
  - [x] 4.1 檢查本地化檔案格式正確
  - [x] 4.2 確認程式碼能正確讀取繁體中文字串

- [x] 5. 添加 InfoPlist.strings 本地化
  - [x] 5.1 創建 `en.lproj/InfoPlist.strings` (英文備援)
  - [x] 5.2 創建 `zh-Hant.lproj/InfoPlist.strings` (繁體中文)
  - [x] 5.3 更新 project.yml 移除硬編碼的西班牙語 Accessibility 說明字串
