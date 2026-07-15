# ADR 0001:專案轉向——目標市場改為台灣、技術棧由 Go 改為 Java

- **狀態**:Accepted
- **日期**:2026-07-15
- **決策者**:Jeff(拍板)、Claude(分析與建議)

## Context(背景)

原專案定位為日本東京英文友善公司的求職作品集(Mercari、PayPay、Money Forward),
所有選型均依此設計:Go(Mercari 對口)、gRPC + buf、sqlc、repo 內文件全英文。
同時專案兼作 Jeff 的 Go 學習路徑,規定所有代碼由 Jeff 親手實作。

2026 年 7 月,旅日求職計畫取消。專案仍作為求職作品集,但目標市場改為台灣,
原有選型依據(對齊東京公司)與協作模式(Go 學習)同時失效。
此時 repo 內尚無任何程式碼,轉向沒有沉沒成本。

## Decision(決策)

1. **目標市場**:台灣後端職缺,金融/支付/電商金流領域對口。
2. **技術棧**:Java 21 LTS + Spring Boot 3;持久層統一用 **MyBatis**(顯式 SQL,
   延續原 sqlc「每條 SQL 可審計」的精神,亦為台灣金融業主流);API 改為
   **REST + OpenAPI**(springdoc);Flyway 管 schema 遷移;Gradle 建置;
   JUnit 5 + Testcontainers 測試。
3. **雲端維持 GCP**:GKE + Cloud SQL for MySQL 8 + Pub/Sub + Terraform,
   與 Jeff 的 GCP PCA 證照互相背書(Jeff 明確指定保留)。
4. **協作模式**:改為「設計共議 + Claude 實作 + PR 導讀」。架構與重大取捨
   先討論、Jeff 拍板;程式碼由 Claude 實作;每個 PR 附中文導讀
   (做了什麼、關鍵決策、面試可能怎麼問),Jeff 理解後才 merge。
5. **語言政策**:所有文件(README、設計文件、ADR、計畫、知識庫、PR 導讀)
   一律繁體中文;commit message 與程式碼註解維持英文(業界慣例)。
6. **不變之處**:四大類核心不變量(plan §4)、modular monolith 架構、
   Phase 0–4 里程碑結構、OKF 知識庫制度,全部保留。

## Alternatives considered(考慮過的替代方案)

- **持久層雙軌制**(一般 CRUD 用 Spring Data JPA、資金路徑用 JdbcTemplate):
  可同時展示台灣最大宗的 JPA 技能,且「資金路徑為何不用 JPA」是好的面試素材。
  最終因 Jeff 選擇全專案統一、貼齊金融業實務而未採用。JPA 面試問答需另行準備。
- **保留 gRPC + protobuf**:最接近原計畫,但台灣市場以 REST 為主流,
  對口度低且 grpc-java 與 Spring 整合成本較高,放棄。

## Consequences(後果)

- (+)選型對齊台灣金融/支付業主流,文件即中文面試素材。
- (+)Claude 實作,開發速度大幅提升;Jeff 透過設計共議與 PR 導讀維持理解深度。
- (−)失去 Go 的 race detector;併發正確性改以「結果不變量驗證」策略
  (併發壓測後驗證複式恆等式與餘額零漂移)+ Testcontainers 真實 MySQL 取代。
- (−)原 Go 版 Phase 0 實作計畫(`docs/plans/2026-07-13-phase0.md`)作廢,
  需重寫 Java 版;既有 Phase 0 設計討論紀錄保留為歷史文件。
- (−)本專案不展示 JPA;若面試需要,另行準備。
