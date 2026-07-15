# Knowledge Base Index

漸進揭露索引。深入讀任何知識檔案前,先讀這裡。
知識庫定位:**面試素材庫**(設計決策白話解說、領域概念、面試問答)。

## wiki/ (compiled knowledge)

- [kafka-basics.md](wiki/kafka-basics.md) — Kafka 心智模型(log 不是 queue)、
  topic/partition/consumer group/offset、KRaft、advertised.listeners 經典坑
  (含本專案 9092 被佔的實戰)、三題面試問答。
- [flyway-schema-migration.md](wiki/flyway-schema-migration.md) —
  Flyway 是什麼:schema drift 問題、檔名即版本/DB 記帳/舊腳本不可改
  三機制、與 ledger append-only 哲學的呼應、面試問答(vs Liquibase)。

## discussions/ (kept Q&A records)

- [2026-07-15-phase0-java-design.md](discussions/2026-07-15-phase0-java-design.md) —
  **(現行)** Java 版 Phase 0 設計定案:Maven 多模組依部署單位切、
  api/internal 純慣例邊界、compose(MySQL 8 + Kafka KRaft)、CI 三 job、
  apply-verify-destroy、Kafka 決策(ADR 0002)與誠實揭露清單。
- [2026-07-13-phase0-design.md](discussions/2026-07-13-phase0-design.md) —
  **(歷史文件,Go 時代)** 已批准的 Go 版 Phase 0 設計:單 module monorepo、
  buf/proto 慣例、compose 開發環境、最小成本 Terraform
  (GKE/Cloud SQL 採 apply-verify-destroy)、4-job CI。
  其中「最小成本 Terraform」與「compose 開發環境」思路對 Java 版仍有參考價值;
  buf/proto 部分已隨轉向 REST 而失效(見 ADR 0001)。

## raw/ (read-only sources)

_空。_
