# Schedule

## 主要功能:
1. 整合 Apple 內建的行事曆與提醒事項
## 專案架構:
1. 採用 MVC 架構模式
2. 根據功能將專案模組化為數個框架
## 前端:
1. 使用 UIKit 為主要框架
2. 使用 Lottie Animation 呈現進場動畫(套用 Lottie 官方的 SPM)
3. 使用自製的 Container View Controller，在其中自訂 TransitionContext
與 TransitionAnimator，以實現客製轉場及全屏右滑返回(參考 Facebook App) 4. 使用 NotificationCenter 搭配 observers，實現響應式 UI
5. 使用 UserDefaults 實現自訂主題顏色、自訂深淺色模式等等功能
## 後端:
1. 使用 EventKit 同步 Apple 行事曆與提醒事項
2. 使用 Singleton 搭配 Asynchronous Functions 處理 EKCalendarItems 的增刪查改
## 性能優化部分:
1. 使用 Core Data 儲存轉換過的 EKCalendarItems(自訂 Object 與其 Encoding、Decoding)， 使呈現月曆的 UIPageViewController 在切換頁面時能夠順暢(不用常常從 EKEventStore fetch 資料)
2. 適時在 Background Thread 上更新資料庫，以確保它維持在最新狀態

## Finished：
- TabBar 第一項：主畫面（月曆＆每日事項）
- TabBar 第五項：設定頁面（及所有設定部分）
- TabBar 第三項-1：新增/編輯 Event 畫面

## In Progress：
- TabBar 第二項：Reminders Overview
- TabBar 第四項：搜尋畫面
- TabBar 第三項-2：新增/編輯 Reminder 畫面
- 加入繁體中文
