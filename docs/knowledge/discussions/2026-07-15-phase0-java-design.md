---
type: Design Discussion
title: Java 版 Phase 0 設計定案
description: 專案轉向後的第一次架構討論——Maven 佈局、模組邊界、本地環境、CI、GCP 成本策略、Kafka 決策
tags: [phase0, maven, module-boundary, kafka, terraform, ci]
date: 2026-07-15
status: approved
---

# Java 版 Phase 0 設計定案(2026-07-15,Jeff 批准)

前情:專案轉向見 ADR 0001(Go→Java、東京→台灣、Claude 實作);
事件層換 Kafka 見 ADR 0002。本文記錄 Phase 0 落地形狀的討論結果。

## 決策清單

| 議題 | 決定 | 拍板依據 |
|---|---|---|
| 建置工具 | **Maven**(非 Gradle) | Jeff 指定;台灣金融業滲透率最高 |
| 專案佈局 | **多模組,依部署單位切**:`app/wallet`(+ Phase 2 `app/reconciler`)、`libs/common`(極小)、`infra/terraform` | 部署邊界由編譯器強制;複雜度適中 |
| wallet 內部模組 | account / ledger / transfer / outbox 各為 package,內分 `api/`(公開 interface + DTO)與 `internal/`(service、mapper、SQL) | 跨模組只准 import `api` |
| 邊界驗證 | **純慣例,不加工具**(否決 ArchUnit、Spring Modulith) | Jeff 拍板;Claude 在每個 PR 自查並於導讀說明;飄移時再補 ArchUnit(一個測試檔的事) |
| 本地開發環境 | docker-compose:**MySQL 8 + Kafka(KRaft 單節點)**,僅此兩個;觀測性堆疊 Phase 3 才進 | 日常開發完全離線 |
| CI | GitHub Actions 三 job:lint(Spotless + Checkstyle)→ test(單元 + Testcontainers)→ build image;PR 全綠才 merge | |
| GCP 成本 | 沿用 **apply-verify-destroy**:Terraform 定義 GKE Autopilot + Cloud SQL + Artifact Registry,實 apply 一次、驗證、留證據、destroy | $300 credits 撐全專案;日常不碰雲 |
| 事件層 | **Kafka**(取代 Pub/Sub),雲端部署方式 Phase 3 前以 ADR 定案 | 見 ADR 0002;Jeff 不熟 Kafka → 講解義務 |

## Phase 0 DoD

1. `mvn verify` 本地全綠;compose 起得來,wallet 骨架連上 MySQL、health check 通過
2. CI 三 job 在 GitHub 實跑全綠
3. 一輪完整 build → push image → Terraform apply → GKE 部署驗證 → destroy,證據入文件
4. 中文架構文件 `docs/adr/0003-architecture-overview.md`

## 誠實揭露(面試前要記得的)

- MyBatis 非台灣最大宗(JPA 才是),是金融業主流——JPA 問答另行準備(ADR 0001)
- GCP 非台灣市佔最大(AWS 才是),GKE/K8s 技能可轉移,PCA 證照背書
- Kafka 已是主流對口,無短板(ADR 0002)
