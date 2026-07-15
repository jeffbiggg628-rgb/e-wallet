# E-Wallet Portfolio Project — 系統規劃總綱

> 本文件是專案的最高層規範,供 Claude Code 在開發過程中作為長期上下文讀取。
> 當實作細節與本文件衝突時,以本文件的「不變量」與「範圍邊界」為準;
> 若確有必要偏離,先產出一份 ADR 說明理由,不要靜默偏離。
>
> **2026-07-15 全面改版**:目標市場改為台灣、技術棧由 Go 改為 Java、
> 協作模式改為 Claude 實作。改版理由與完整決策見
> `docs/adr/0001-pivot-to-java-taiwan.md`。

---

## 1. 專案定位

**目的**:求職作品集,目標台灣後端職缺,以金融/支付/電商金流領域為對口
(銀行金控科技子公司、支付業者、電商平台)。

**要傳達的工程訊號**(重要性由高到低):

1. 理解「資金系統」與一般 CRUD 系統的本質差異(正確性、可審計性)
2. 分散式系統下的一致性處理(outbox、冪等、最終一致 + 對帳驗證)
3. SRE 素養(SLO、可觀測性、postmortem 文化)
4. 雲端工程實踐(GCP、Terraform IaC、CI/CD)——與 GCP PCA 證照互相背書
5. 高並發處理能力(紅包模組,**已降級為最後階段的選配**)

**不是目的**:功能豐富度、UI、支撐真實用戶。

## 2. 範圍邊界(硬限制)

- **服務數量 ≤ 3**:`wallet`(含 ledger)、`reconciler`(對帳 worker)、
  `redpacket`(Phase 4 選配)。禁止再拆分新服務。
- **Boring Java**:Java 21 LTS + Spring Boot 3,標準做法優先。允許的核心依賴:
  `spring-boot-starter-web`(REST)、`mybatis-spring-boot-starter`(型別安全
  顯式 SQL)、`mysql-connector-j`、`flyway`(schema 遷移)、
  `springdoc-openapi`(API 文件)、`spring-kafka`(事件層,見 ADR 0002)、
  `micrometer` + OpenTelemetry 系列;測試允許 JUnit 5、Testcontainers
  (含 Kafka module)、AssertJ、Awaitility。**新增任何其他第三方依賴前,必須先在 ADR 中說明理由**
  (含 Lombok——預設不用,要用先寫 ADR)。
- **工具鏈**:Maven(建置;台灣金融業主流)、Spotless + Checkstyle
  (格式與靜態檢查,進 CI)、GitHub Actions、Terraform。
- **明確不做(non-goals)**:前端(以 Swagger UI / Postman collection 作為介面)、
  完整 auth(最簡 JWT 即可)、多區域部署、災備、KYC/法遵。
  這些統一寫進 README 的「Production readiness gaps」章節,展示邊界意識。
- **語言政策**:所有文件(README、設計文件、ADR、計畫、知識庫、PR 導讀)
  一律**繁體中文**,關鍵技術術語保留英文原文;
  **commit message 與程式碼註解用英文**(業界慣例)。

## 3. 系統架構

```
                      ┌──────────────────────────┐
  REST / HTTP  ──────▶│  wallet service           │
                      │  - account / balance      │
                      │  - transfer (tx boundary) │
                      │  - double-entry ledger    │
                      │  - outbox table           │
                      └──────────┬───────────────┘
                                 │ outbox relay
                                 ▼
                           Kafka (events)
                                 │
              ┌──────────────────┴──────────────┐
              ▼                                 ▼
   ┌────────────────────┐            ┌────────────────────┐
   │ reconciler worker   │            │ redpacket service  │
   │ - daily 3-way check │            │ (Phase 4, optional)│
   └────────────────────┘            └────────────────────┘

   Infra: GKE (deployables) + Cloud SQL for MySQL 8 (state)
          + Kafka (events;本地 docker,雲端部署 Phase 3 前以 ADR 定案)
          + Terraform (all of the above)
   Observability: OpenTelemetry → Prometheus / Grafana(自架於 GKE)
```

- 對外同步介面用 REST,以 OpenAPI 規格為契約(springdoc 自動產出並進 CI 驗證)。
- wallet 內部模組邊界以 Java package + 明確定義的 interface 劃分
  (禁止跨模組直接存取彼此的 mapper / table)。
- 服務間非同步一律走 Kafka 事件,事件為 JSON,schema 版本化
  (payload 內含 `schema_version` 欄位)。
- 資料庫:每模組獨立 schema(同一個 Cloud SQL for MySQL 實例,省成本)。

### 3.1 架構定位:modular monolith 優先,選擇性拆分

wallet 內部(account / ledger / transfer / outbox)以 **modular monolith**
組織:模組邊界用 package 與 interface 明確劃分,但編譯為單一可部署單元、
共用單一資料庫,以完整利用 DB transaction 保證資金資料完整性。
reconciler 與(選配的)redpacket 才是獨立 deployable。

**依據**:資金/帳務類系統的業界共識——資料完整性優先於架構拆分
(Mercari Hallo、多數支付業者的公開實踐均採此演化路線:先單體正確性,
再選擇性事件化拆分)。本專案刻意複現這條演化路線
(Phase 1 單體正確性 → Phase 3 選擇性事件化拆分),README 應明確敘述。

### 3.2 選型對照(為何這樣選)

| 選型 | 依據 | 備註 |
|---|---|---|
| Java 21 + Spring Boot 3 | 台灣金融/支付/電商後端絕對主流 | LTS 版本,不追新 |
| MyBatis(顯式 SQL) | 台灣銀行、支付業實務主流 | 資金系統每條 SQL 可審計;面試可講「為何不用 JPA 管資金路徑」 |
| REST + OpenAPI | 台灣市場主流介面風格 | OpenAPI 規格即契約,進 CI |
| MySQL 8(Cloud SQL) | 台灣 web 業界主流 | 顯式 SQL、明確索引與鎖策略 |
| GKE + Terraform + GitHub Actions | 與 GCP PCA 證照互相背書 | Jeff 指定保留 GCP |
| Kafka 事件驅動 | 台灣業界 message queue 主流 | 「outbox + Kafka + effectively-once」是金融/支付面試標準題組(ADR 0002) |
| OpenTelemetry | 廠商中立標準 | 可遷移到任何後端 |

## 4. 核心不變量(任何 PR 不得違反)

1. **帳本 append-only**:`ledger_entries` 表禁止 UPDATE / DELETE。
   修正錯帳只能透過反向分錄(reversal entry)。
2. **複式記帳恆等式**:任一交易的分錄借貸總和為零;
   任一時點全系統 `SUM(amount)` 為零(不含外部往來帳戶時需配平)。
3. **餘額是推導值**:`wallet.balance` 只是 ledger 的快取投影,
   對帳 job 驗證兩者一致;不一致時以 ledger 為準。
4. **金額用整數最小單位**(TWD 為整數元;若支援小數幣種用 `BIGINT` minor units)。
   **禁止 float / double,Java 端一律 `long`(minor units),禁止 `BigDecimal`
   混用浮點來源**。
5. **所有資金操作冪等**:寫入口徑統一要求 `idempotency_key`,
   重複請求回傳首次結果,不重複入帳。
6. **DB 寫入與事件發布同交易**:業務寫入與 outbox 寫入必須在同一個
   DB transaction(同一個 `@Transactional` 邊界);
   禁止「先寫 DB 再直接 publish」的雙寫。
7. **消費端 effectively-once**:所有 Kafka consumer 必須以冪等鍵
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
> **(a) 可運行 demo(b) 中文設計文件(c) 該階段的量化數據**。
> 文件缺一章 = 該 Phase 未完成,即使功能能跑。

### Phase 0 — 骨架與基礎設施(先行,約 2 週)
- Maven monorepo 結構、Spring Boot 服務骨架、OpenAPI 契約雛形、
  本地 docker-compose(MySQL 8 + Kafka KRaft 單節點)、Flyway 遷移工具鏈
- Terraform 定義 GCP 基礎資源;GitHub Actions:lint + test + build image
- DoD 文件:`docs/adr/0003-architecture-overview.md`

### Phase 1 — 單體正確性:wallet + double-entry ledger(核心,約 6 週)
- 開戶、充值、轉帳、提現;全部走單機 DB transaction(`@Transactional`)
- 冪等鍵機制;併發轉帳的正確性測試——**Java 沒有 race detector,
  改用「結果不變量驗證」策略**:多執行緒併發壓測(JUnit + Testcontainers
  真實 MySQL)後,驗證複式恆等式與餘額零漂移
- **量化數據**:併發 1000 workers 隨機互轉 N 輪後,恆等式與餘額零漂移
- DoD 文件:`docs/design/ledger.md`(為何複式、為何 append-only、
  為何餘額是投影、為何資金路徑用顯式 SQL 而非 JPA)

### Phase 2 — 對帳:reconciler(約 3 週)
- 每日批次:ledger ↔ wallet 投影 ↔ 模擬外部對帳單(CSV)三方勾稽
- 故意注入不一致(手動 SQL 竄改測試環境),展示偵測、告警、
  reversal entry 修復流程
- **量化數據**:注入 N 種漂移場景的偵測率 100%
- DoD 文件:`docs/design/reconciliation.md`

### Phase 3 — 拆分:outbox + Kafka + 可觀測性(約 6 週)
- 雲端 Kafka 部署方式先以 ADR 定案(managed vs GKE 自架,見 ADR 0002)
- outbox relay → Kafka;通知類 / 投影類 consumer 落地 effectively-once
- OpenTelemetry trace 貫穿 HTTP → DB → Kafka;Prometheus 指標;
  Grafana dashboard(RED metrics + 業務指標:入帳延遲、對帳漂移數)
- 定義 SLO:transfer API p99 < 300ms、可用性 99.9%、
  事件端到端延遲 p95 < 5s
- 用壓測把系統打掛一次,寫 postmortem:`docs/postmortems/0001-*.md`
- **量化數據**:關閉 relay / 重複投遞 / kill pod 三種故障注入下,
  對帳零漂移(reconciler 在此階段升級為分散式正確性的裁判)
- DoD 文件:`docs/design/eventing.md`、`docs/slo.md`

### Phase 4 —(選配)紅包模組:高並發疊加
- **明確降級:時間不足即整段砍掉,不影響前三階段的完整性。**
- 若做:發紅包 / 搶紅包,Redis 預減 + 非同步入帳走既有 outbox 管線,
  k6 壓測出吞吐曲線與瓶頸分析報告
- 入帳仍必須通過 Phase 2 對帳驗證——這是紅包模組與一般秒殺專案的
  本質差異,README 要明確寫出這一點

## 7. 品質與流程約定(協作守則)

- **設計共議、Claude 實作**:架構與重大取捨先與 Jeff 討論定案
  (重大決策寫 ADR),程式碼、測試、基礎設施由 Claude 實作。
- **每個 PR 必附中文導讀**:這次做了什麼、關鍵決策與理由、
  面試可能怎麼問。Jeff 理解並批准後才 merge——理解深度不外包。
- 小步提交:一個 PR 對應一個明確意圖;commit message 用英文祈使句。
- 任何資金路徑的變更必須附帶:單元測試 + 併發整合測試。
- 測試優先覆蓋不變量(第 4 節),而不是行覆蓋率數字。
- 錯誤處理:資金操作失敗必須可分類(retryable / non-retryable),
  禁止吞錯誤。
- 每個重大技術決策寫 ADR(`docs/adr/NNNN-*.md`,中文,含 context /
  decision / consequences)。
- 不確定需求時:先讀本文件第 2、4、6 節;仍不確定就停下來問,
  不要擴張範圍。

## 8. 與求職準備的接點(背景資訊)

- 所有中文設計文件同時是面試素材:要能支撐「對著架構圖講 20 分鐘」
  的場景;關鍵術語保留英文原文,面試中英夾雜表達時不卡詞。
- Terraform / GKE 的實作與 GCP PCA 考試內容互相背書,
  實作時優先採用 PCA 考點中的標準做法(如 Workload Identity、
  least-privilege service account)。
- 本專案即 Java / Spring 手感的維持來源;Jeff 透過設計共議與
  PR 導讀維持對每個設計決策與關鍵代碼的理解深度。
- 本專案不展示 JPA;面試的 JPA 問答另行準備(知識庫可收錄
  「MyBatis vs JPA」對比問答)。
