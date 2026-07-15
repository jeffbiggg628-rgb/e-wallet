# Progress

## Current position

- **Phase**:0(骨架與基礎設施)——設計已定案並經 Jeff 批准
  (`docs/knowledge/discussions/2026-07-15-phase0-java-design.md`),
  事件層改用 Kafka(ADR 0002)。
- **Current task**:Phase 0 Task 1(Maven 骨架)已實作完成並開
  PR #2(feat/maven-skeleton),等 Jeff review 導讀後 merge;
  merge 後接 Task 2(本地環境:compose + Flyway + MyBatis)。
  版本決策:Spring Boot 3.5.16(Jeff 拍板,對口台灣存量市場;
  4.x 已 GA,升版留作日後素材)。實作計畫:`docs/plans/2026-07-15-phase0.md`。

## Verified done

- 2026-07-15:Phase 0 架構討論完成——Maven 多模組(依部署單位切)、
  wallet 內部 api/internal 純慣例邊界(Jeff 否決驗證工具)、
  compose(MySQL 8 + Kafka KRaft)、CI 三 job、apply-verify-destroy 沿用、
  事件層 Pub/Sub → Kafka(ADR 0002)。相關文件全部更新並提交。
- 2026-07-15:專案轉向(ADR 0001)——台灣市場、Java 21 + Spring Boot 3 +
  MyBatis + Maven、Claude 實作 + PR 導讀、文件全中文化。
- 2026-07-13:Repo 初始化。尚無程式碼。

## Next up

- 寫 Phase 0 實作計畫並開始執行第一個 PR(Maven parent + wallet 骨架)。

## Open questions

-(留待 Phase 3 前)雲端 Kafka 部署方式:GCP Managed Service for
  Apache Kafka vs GKE 自架單節點,以 ADR 定案(ADR 0002 決策第 3 點)。

## 協作提醒

- Jeff 不熟 Kafka:動用 Kafka 的討論與 PR 導讀要從零講解概念,
  並編纂進知識庫 wiki(CLAUDE.md、ADR 0002)。
