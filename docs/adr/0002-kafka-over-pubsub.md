# ADR 0002:事件中介層改用 Kafka(取代 GCP Pub/Sub)

- **狀態**:Accepted
- **日期**:2026-07-15
- **決策者**:Jeff(拍板)、Claude(分析與建議)

## Context(背景)

ADR 0001 轉向台灣市場時,事件層沿用了原計畫的 GCP Pub/Sub(Jeff 最初指定
保留 GCP 全家桶,配合 GCP PCA 證照)。後續 Jeff 問「這套是否最貼近業界」,
誠實盤點後發現:Pub/Sub 是整套選型中離台灣業界最遠的一項——台灣的
message queue 主流是 **Kafka**,「outbox + Kafka + effectively-once consumer」
是金融/支付領域的標準面試題組合。此時尚無任何程式碼,切換零成本。

## Decision(決策)

1. 事件中介層改用 **Apache Kafka**,用戶端採 `spring-kafka`。
2. 本地開發:docker-compose 跑 **KRaft 模式單節點 Kafka**(無 ZooKeeper)。
3. 雲端部署方式(GCP Managed Service for Apache Kafka vs GKE 自架單節點)
   **延後到 Phase 3 前以 ADR 定案**——Phase 0–2 用不到雲端 Kafka。
4. 架構不變:outbox 模式、事件 JSON schema 版本化、consumer 冪等
   (effectively-once)全部照舊,只換傳輸層。
5. **講解義務**:Jeff 不熟 Kafka。凡動用 Kafka 的設計討論與 PR 導讀,
   必須從零講解相關概念(topic、partition、consumer group、offset、
   delivery semantics 等),並隨進度把概念頁編纂進知識庫 wiki
   (`type: Interview QA` / `Design Concept`)。此義務已寫入 CLAUDE.md。

## Alternatives considered(考慮過的替代方案)

- **維持 GCP Pub/Sub**:GCP 全家桶一致性最高、營運最省事,但台灣面試
  對口度低,每次都要先解釋「這跟 Kafka 概念同構」——不如直接用 Kafka。
- **Confluent Cloud 免費額度**:省自架功夫,但引入第三方 SaaS 依賴,
  與「作品集展示基礎設施能力」的目標相悖。

## Consequences(後果)

- (+)事件層直接對口台灣業界主流;面試素材(partition 選 key、
  rebalance、重複投遞處理)都是真實會被問的題目。
- (+)本地 docker Kafka 免費,開發完全離線。
- (−)離開 GCP 託管服務的舒適圈:雲端 demo 需要多管一個 Kafka
  (Phase 3 的 ADR 要處理)。GKE + Cloud SQL 的 PCA 背書不受影響。
- (−)Jeff 需要從零學 Kafka——以講解義務(本 ADR 第 5 點)緩解。
