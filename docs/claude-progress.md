# Progress

## Current position

- **Phase**:專案轉向完成(2026-07-15)——目標市場改台灣、技術棧改
  Java 21 + Spring Boot 3 + MyBatis、協作模式改為 Claude 實作 + PR 導讀。
  詳見 `docs/adr/0001-pivot-to-java-taiwan.md`。
- **Current task**:與 Jeff 討論 Java 版 Phase 0 設計
  (Gradle monorepo 結構、Spring Boot 骨架、docker-compose、Flyway、
  Terraform、CI),定案後重寫 Phase 0 實作計畫。

## Verified done

- 2026-07-15:轉向文件全部改寫完成——ADR 0001、
  `docs/ewallet-portfolio-plan.md`(Java 版)、`CLAUDE.md`(新協作模式)、
  知識庫 index/log 更新。原 Go 版 Phase 0 計畫標記作廢。
- 2026-07-13:Repo 初始化(CLAUDE.md、計畫文件、知識庫骨架)。尚無程式碼。

## Next up

- Java 版 Phase 0 設計討論:Gradle 專案佈局(單 repo 多模組 vs 單模組)、
  Spring Boot 版本與起手依賴、本地開發環境(docker-compose:MySQL 8 +
  Pub/Sub emulator)、CI job 切分、Terraform 最小成本策略是否沿用
  (apply-verify-destroy)。
- 定案後重寫 `docs/plans/` 下的 Phase 0 實作計畫(中文,Claude 實作視角:
  以 PR 為單位切分,每個 PR 附導讀)。

## Open questions

- 原 Go 版 Phase 0 設計中的最小成本 Terraform 策略($300 GCP credits,
  apply-verify-destroy)是否沿用?待 Phase 0 設計討論時與 Jeff 確認。
