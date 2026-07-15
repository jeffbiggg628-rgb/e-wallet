# CLAUDE.md

## 這個專案是什麼

以 Java 打造的 e-wallet 後端,作為台灣後端求職作品集
(金融/支付/電商金流領域對口)。技術棧:Java 21 + Spring Boot 3 +
MyBatis + REST/OpenAPI + GCP(GKE、Cloud SQL MySQL 8、Pub/Sub)+ Terraform。

權威規格是 **`docs/ewallet-portfolio-plan.md`**。開始任何任務前,至少先讀
其 §2(範圍邊界)、§4(不變量)、§6(里程碑)。任何事與該文件衝突時,
以文件為準;要偏離必須先寫 ADR——禁止靜默偏離。
專案轉向的緣由見 `docs/adr/0001-pivot-to-java-taiwan.md`。

## 協作模式:設計共議、Claude 實作、PR 導讀

- **設計共議**:架構與重大取捨必須先與 Jeff 討論、由 Jeff 拍板;
  重大決策記錄為 ADR。有任何不確定就先問,不要替 Jeff 做決定。
- **Claude 實作**:程式碼、測試、基礎設施由 Claude 完成。
  小步提交,一個 PR 對應一個明確意圖。
- **PR 導讀(每個 PR 必附,中文)**:
  1. 這次做了什麼(白話摘要)
  2. 關鍵決策在哪、為什麼這樣做(含被否決的替代方案)
  3. 面試可能怎麼問、怎麼答
  Jeff 理解並批准後才 merge——**理解深度不外包**。

### 交付前自我檢查清單(每個 PR 適用)

1. **需求完整性** — 是否完整覆蓋約定的步驟與該 Phase 的 DoD(plan §6)?
2. **不變量安全**(plan §4)— append-only ledger、複式恆等式為零、
   餘額是投影、整數最小單位(禁 float)、冪等鍵、outbox 與業務寫入
   同一個 `@Transactional`、消費端 effectively-once。
3. **正確性** — 錯誤分類(retryable / non-retryable,不吞錯)、
   併發安全、交易邊界、邊界條件。
4. **慣用 Java / Spring 與最佳實踐** — boring 標準做法優先
   (plan §2);新增依賴前先寫 ADR。
5. **測試** — 優先覆蓋不變量與失敗路徑;行覆蓋率不是目標。

## 知識庫:`docs/knowledge/`(OKF bundle,LLM 維護,定位為面試素材庫)

依循以下理念運作(不清楚時去讀):
- LLM-as-compiler knowledge base: https://blog.aihao.tw/2026/05/20/llm-knowledge-base/
- Open Knowledge Format spec: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md
- Harness engineering: https://walkinglabs.github.io/learn-harness-engineering/zh-TW/

結構(分層依 knowledge-base 文章,格式依 OKF):

```
docs/knowledge/
  index.md          # 漸進揭露索引——深入讀任何檔案前一定先讀這裡
  log.md            # 時間序更新紀錄(新的在上)
  raw/              # 唯讀來源素材(連結、摘錄)——不得編輯
  wiki/             # LLM 編纂的知識:設計決策白話解說、領域概念、
                    # 面試問答(例如「為何資金路徑不用 JPA」)
  discussions/      # 值得保留的設計討論紀錄
```

規則:
- 每個非保留 `.md` 檔都要有 YAML frontmatter,至少含非空的 `type:` 欄位
  (如 `type: Design Concept`、`type: Interview QA`);建議加 `title`、
  `description`、`tags` 與時間戳。
- **wiki 由 Claude 維護**;Jeff 給方向,不手改編纂頁。
- **Write-back loop**:設計討論或 PR 導讀產生耐久的教訓
  (設計決策理由、Jeff 已理解的模式、面試可用的問答)時,
  編纂進 `wiki/`、更新 `index.md`、追加到 `log.md`。
- **完整性**:保留來源出處、區分事實與推論、衝突要明確標記而非覆蓋。
- **Index-first**:先讀 `index.md` 再深入,節省上下文。

## Harness 規則(跨 session 連續性)

- **Session 起手式**:讀本檔 → plan §2/§4/§6 → `docs/claude-progress.md` →
  `docs/knowledge/index.md`,然後先陳述本次任務邊界再動手。
- **一次一個任務**,事先定義明確的完成條件。不擴張範圍;
  不確定時重讀 plan §2/§4/§6,仍不確定就問。
- **完成前先驗證**:沒有證據不得宣稱完成——測試/lint 實際跑過並引用輸出。
  Phase 的 DoD 另需 demo、中文設計文件、量化數據(plan §6)。
- **乾淨交接**:session 結束前更新 `docs/claude-progress.md`
  (目前 phase/步驟、通過驗證的項目、下一步、未決問題)。
- **Repo 是唯一事實來源**:決策存在於 ADR 與知識庫,不在對話紀錄裡。

## 語言政策

- 與 Jeff 對話:繁體中文。
- **所有文件一律繁體中文**:README、設計文件、ADR、計畫(`docs/plans/**`)、
  知識庫、postmortem、PR 導讀。關鍵技術術語保留英文原文。
- **commit message 與程式碼註解用英文**(業界慣例,英文祈使句)。

## 工程對齊

設計模式與技術選型對齊台灣金融/支付業主流實務(plan §3.2):
modular monolith(package + interface 劃分模組邊界)、REST + OpenAPI、
MyBatis 顯式 SQL、outbox + Pub/Sub、OpenTelemetry。
禁止計畫外的 cleverness;任何新依賴先寫 ADR。
