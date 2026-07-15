---
type: Design Concept
title: Flyway——資料庫 schema 的版本控制
description: Flyway 解決的問題(schema drift)、三個核心機制、與本專案 append-only 哲學的呼應
tags: [flyway, mysql, migration, toolchain, phase0]
date: 2026-07-15
source: 2026-07-15 與 Jeff 的 Q&A(Phase 0 計畫 Task 2 前置提問)
---

# Flyway——資料庫 schema 的版本控制

## 解決的問題:schema drift

程式碼有 git,但資料庫的結構變更(`ALTER TABLE`…)若靠人手動跑,
沒人能回答「正式環境的表現在長怎樣、跟測試環境差在哪、
新環境要跑哪些 SQL 才追得上」。Flyway 把 schema 演進變成
**有版本、可重放的代碼**。

## 三個核心機制

1. **檔名即版本**:`db/migration/V1__init.sql`、`V2__add_wallet_index.sql`…
   只能往前追加。
2. **DB 內記帳**:`flyway_schema_history` 表記錄已執行的版本與 checksum;
   應用啟動時自動補跑缺的版本,跑過的絕不重跑。
3. **舊腳本不可改**:checksum 驗證,改了已執行的腳本會拒絕啟動;
   要變更就寫新版本。

## 對本專案的意義

- 本地 compose MySQL、Testcontainers 測試 MySQL、Cloud SQL 三個環境
  由同一疊腳本建出,保證一致。
- schema 變更一律走 PR + 導讀,資料庫歷史可考古。
- 哲學呼應:「只能追加、不改歷史、修正用新的一筆」=
  ledger 的 append-only + reversal entry(plan §4 不變量 1)。

## 面試可能怎麼問

- Q:Flyway 和 Liquibase 差在哪?
  A:Flyway 以純 SQL 腳本為主、輕量;Liquibase 用 XML/YAML 抽象變更、
  支援 rollback 描述。本專案選 Flyway 因與 MyBatis 顯式 SQL 路線一致。
- Q:已上線的 migration 寫錯了怎麼辦?
  A:不改舊檔(checksum 會擋),寫一個新版本做修正——同 reversal entry 思維。
