# E-Wallet Portfolio Project — 系統規劃總綱

> 本文件是專案的最高層規範,供 Claude Code 在開發過程中作為長期上下文讀取。
> 當實作細節與本文件衝突時,以本文件的「不變量」與「範圍邊界」為準;
> 若確有必要偏離,先產出一份 ADR 說明理由,不要靜默偏離。

---

## 1. 專案定位

**目的**:作為求職作品集,目標是日本東京的英文友善科技公司後端職缺,
優先順序:Mercari(Go + GCP 完全對口)、PayPay(支付高並發問題域對口)、
Money Forward(帳務領域對口,英文化中)。

**要傳達的工程訊號**(重要性由高到低):

1. 理解「資金系統」與一般 CRUD 系統的本質差異(正確性、可審計性)
2. 分散式系統下的一致性處理(outbox、冪等、最終一致 + 對帳驗證)
3. SRE 素養(SLO、可觀測性、postmortem 文化)
4. 雲端工程實踐(GCP、Terraform IaC、CI/CD)——與 PCA 證照互相背書
5. 高並發處理能力(紅包模組,**已降級為最後階段的選配**)

**不是目的**:功能豐富度、UI、支撐真實用戶。

## 2. 範圍邊界(硬限制)

- **服務數量 ≤ 3**:`wallet`(含 ledger)、`reconciler`(對帳 worker)、
  `redpacket`(Phase 4 選配)。禁止再拆分新服務。
- **Boring Go**:標準庫優先。允許的核心依賴:`grpc-go`、
  `go-sql-driver/mysql` + `sqlc`(型別安全查詢,顯式 SQL)、
  `golang-migrate`(schema 遷移)、一個薄 HTTP 層(標準庫 `net/http`
  或 `grpc-gateway`)、`otel` 系列、`slog`、測試允許 `testify`。
  新增任何其他第三方依賴前,必須先在 ADR 中說明理由。
- **工具鏈(對齊目標公司內部標準)**:`buf`(proto lint + codegen)、
  `golangci-lint`(進 CI)、GitHub Actions、Terraform。
- **明確不做(non-goals)**:前端(以 grpcurl / Postman collection 作為介面)、
  完整 auth(最簡 JWT 即可)、多區域部署、災備、KYC/法遵。
  這些統一寫進 README 的「Production readiness gaps」章節,展示邊界意識。
- **repo 內所有交付文件一律英文**:README、design docs、ADR、postmortem、
  commit message。與使用者的對話可用中文,但寫進 repo 的內容是英文。

## 3. 系統架構

```
                      ┌──────────────────────────┐
  gRPC / HTTP  ──────▶│  wallet service           │
                      │  - account / balance      │
                      │  - transfer (tx boundary) │
                      │  - double-entry ledger    │
                      │  - outbox table           │
                      └──────────┬───────────────┘
                                 │ outbox relay
                                 ▼
                          GCP Pub/Sub (events)
                                 │
              ┌──────────────────┴──────────────┐
              ▼                                 ▼
   ┌────────────────────┐            ┌────────────────────┐
   │ reconciler worker   │            │ redpacket service  │
   │ - daily 3-way check │            │ (Phase 4, optional)│
   │ - drift detection   │            └────────────────────┘
   └────────────────────┘

   Infra: GKE (deployables) + Cloud SQL for MySQL 8 (state)
          + Pub/Sub (events) + Terraform (all of the above)
   Observability: OpenTelemetry → Prometheus / Grafana(自架於 GKE)
```

- 服務間同步呼叫用 gRPC(proto 定義放 `/proto`,以 buf 管理,
  單一 source of truth)。
- 服務間非同步一律走 Pub/Sub 事件,事件 schema 版本化。
- 資料庫:每模組獨立 schema(同一個 Cloud SQL for MySQL 實例,省成本)。

### 3.1 架構定位:modular monolith 優先,選擇性拆分

wallet 內部(account / ledger / transfer / outbox)以 **modular monolith**
組織:模組邊界用 package 與 proto 介面明確劃分,但編譯為單一 binary、
共用單一資料庫,以完整利用 DB transaction 保證資金資料完整性。
reconciler 與(選配的)redpacket 才是獨立 deployable。

**依據**:Mercari 公開的工程實踐——Mercari Hallo 與其全球化新架構均採
modular monolith + proto 定義模組介面,理由正是「資金/薪資類資料的
完整性優先於架構拆分」,並保留日後拆為微服務的彈性。本專案刻意複現
這條演化路線(Phase 1 單體正確性 → Phase 3 選擇性事件化拆分),
README 中應明確敘述此設計對應關係。

### 3.2 選型對照(為何這樣選)

| 選型 | 匹配對象 | 備註 |
|---|---|---|
| Go + gRPC/protobuf + buf | Mercari 全線 | proto 為模組介面的 source of truth |
| MySQL 8(Cloud SQL) | Mercari / Money Forward(Aurora)/ LY | 日本 web 業界主流;顯式 SQL via sqlc |
| GKE + Terraform + GitHub Actions | Mercari 標準 DevOps 棧 | 與 GCP PCA 考點互相背書 |
| Pub/Sub 事件驅動 | Mercari(Pub/Sub)/ PayPay・LY(Kafka) | 概念同構,面試時說明與 Kafka 的差異(ordering key vs partition、subscription vs consumer group) |
| OpenTelemetry | 廠商中立標準 | 各家內部監控廠商不一,OTel 可遷移 |

## 4. 核心不變量(任何 PR 不得違反)

1. **帳本 append-only**:`ledger_entries` 表禁止 UPDATE / DELETE。
   修正錯帳只能透過反向分錄(reversal entry)。
2. **複式記帳恆等式**:任一交易的分錄借貸總和為零;
   任一時點全系統 `SUM(amount)` 為零(不含外部往來帳戶時需配平)。
3. **餘額是推導值**:`wallet.balance` 只是 ledger 的快取投影,
   對帳 job 驗證兩者一致;不一致時以 ledger 為準。
4. **金額用整數最小單位**(JPY 為整數円;若支援小數幣種用 `BIGINT` minor units)。
   **禁止 float**。
5. **所有資金操作冪等**:寫入口徑統一要求 `idempotency_key`,
   重複請求回傳首次結果,不重複入帳。
6. **DB 寫入與事件發布同交易**:業務寫入與 outbox 寫入必須在同一個
   DB transaction;禁止「先寫 DB 再直接 publish」的雙寫。
7. **消費端 effectively-once**:所有 Pub/Sub consumer 必須以冪等鍵
   容忍 at-least-once 的重複投遞。

## 5. 資料模型(骨架)

```sql
-- 帳戶:用戶錢包帳戶 + 系統帳戶(external/fee/suspense)
accounts(id, owner_id, type, currency, created_at)

-- 錢包餘額投影(可重建)
wallets(account_id PK, balance BIGINT, updated_at, version)

-- 交易(一次業務動作)
transactions(id, idempotency_key UNIQUE, type, status, created_at)

-- 分錄:一筆 transaction 產生 ≥2 筆 entry,SUM(amount)=0
ledger_entries(id, transaction_id, account_id, amount BIGINT,
               direction, created_at)  -- append-only

-- outbox
outbox_events(id, aggregate_type, aggregate_id, event_type,
              payload JSON, created_at, published_at NULL)
```

充值 / 提現以 `external` 系統帳戶作為對手方入帳,
使複式恆等式在全系統層面成立。

## 6. 里程碑(依序執行,不得跳序)

> 每個 Phase 的 Definition of Done 統一為三件事:
> **(a) 可運行 demo(b) 英文設計文件(c) 該階段的量化數據**。
> 文件缺一章 = 該 Phase 未完成,即使功能能跑。

### Phase 0 — 骨架與基礎設施(先行,約 2 週)
- Monorepo 結構、proto 定義、本地 docker-compose(MySQL 8 + Pub/Sub emulator)
- Terraform 定義 GCP 基礎資源;GitHub Actions:lint + test + build image
- DoD 文件:`docs/adr/0001-architecture-overview.md`

### Phase 1 — 單體正確性:wallet + double-entry ledger(核心,約 6 週)
- 開戶、充值、轉帳、提現;全部走單機 DB transaction
- 冪等鍵機制;併發轉帳的正確性測試(go test -race + 並發壓測腳本)
- **量化數據**:並發 1000 workers 隨機互轉 N 輪後,恆等式與餘額零漂移
- DoD 文件:`docs/design/ledger.md`(為何複式、為何 append-only、
  為何餘額是投影——用目標公司 tech blog 的語彙寫)

### Phase 2 — 對帳:reconciler(約 3 週)
- 每日批次:ledger ↔ wallet 投影 ↔ 模擬外部對帳單(CSV)三方勾稽
- 故意注入不一致(手動 SQL 竄改測試環境),展示偵測、告警、
  reversal entry 修復流程
- **量化數據**:注入 N 種漂移場景的偵測率 100%
- DoD 文件:`docs/design/reconciliation.md`

### Phase 3 — 拆分:outbox + Pub/Sub + 可觀測性(約 6 週)
- outbox relay → Pub/Sub;通知類 / 投影類 consumer 落地 effectively-once
- OpenTelemetry trace 貫穿 gRPC → DB → Pub/Sub;Prometheus 指標;
  Grafana dashboard(RED metrics + 業務指標:入帳延遲、對帳漂移數)
- 定義 SLO:transfer API p99 < 300ms、可用性 99.9%、
  事件端到端延遲 p95 < 5s
- 用壓測把系統打掛一次,寫英文 postmortem:`docs/postmortems/0001-*.md`
- **量化數據**:關閉 relay / 重複投遞 / kill pod 三種故障注入下,
  對帳零漂移(reconciler 在此階段升級為分散式正確性的裁判)
- DoD 文件:`docs/design/eventing.md`、`docs/slo.md`

### Phase 4 —(選配)紅包模組:高並發疊加
- **明確降級:時間不足即整段砍掉,不影響前三階段的完整性。**
- 若做:發紅包 / 搶紅包,Redis 預減 + 非同步入帳走既有 outbox 管線,
  k6 壓測出吞吐曲線與瓶頸分析報告
- 入帳仍必須通過 Phase 2 對帳驗證——這是紅包模組與舊秒殺專案的
  本質差異,README 要明確寫出這一點

## 7. 品質與流程約定(給 Claude Code 的協作守則)

- 小步提交:一個 PR 對應一個明確意圖;commit message 用英文祈使句。
- 任何資金路徑的變更必須附帶:單元測試 + 併發測試(`-race`)。
- 測試優先覆蓋不變量(第 4 節),而不是行覆蓋率數字。
- 錯誤處理:資金操作失敗必須可分類(retryable / non-retryable),
  禁止吞錯誤。
- 每個重大技術決策寫 ADR(`docs/adr/NNNN-*.md`,英文,含 context /
  decision / consequences)。
- 不確定需求時:先讀本文件第 2、4、6 節;仍不確定就停下來問,
  不要擴張範圍。

## 8. 與求職準備的接點(背景資訊)

- 所有英文文件同時是面試素材:設計文件要能支撐「對著架構圖
  用英文講 20 分鐘」的場景。
- Terraform / GKE 的實作與 GCP PCA 考試內容互相背書,
  實作時優先採用 PCA 考點中的標準做法(如 Workload Identity、
  least-privilege service account)。
- 面試前一個月恢復 Java 手感(白板題用 Java);本專案維持純 Go。
