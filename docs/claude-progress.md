# Progress

## Current position

- **Phase**:0(骨架與基礎設施)——實作計畫 `docs/plans/2026-07-15-phase0.md`,
  6 個 Task,一個 Task 一個 PR。
- **Current task**:Task 3(CI)完成並開 PR #5(feat/ci-pipeline),
  CI 三 job 首跑全綠;等 Jeff review 後 merge,接 Task 4(Terraform)。

## Verified done

- 2026-07-15:**Task 3** 完成(PR #5)——multi-stage Dockerfile(JRE runtime、
  非 root)、GitHub Actions 三 job(lint 27s / test 1m07s / build-image 1m01s
  首跑全綠)、main ruleset 加上三個 required status checks(gh api 設定)。
  本地 image 實測:連 compose MySQL、health UP、whoami=appuser。
  9092 事件收尾:汙染源(搶票系統 order/seckill 殘留服務)已關,
  Kafka 回 9092;lsof 的 ssh 是 Colima port-forward,未動。
- 2026-07-15:**Task 2** 完成(PR #4,已 merge)——docker-compose(MySQL 8 + Kafka
  KRaft 雙 listener,host 走 19092)、Flyway V1 五張核心表、MyBatis 接線、
  SchemaSmokeIT(Testcontainers 真 MySQL,先紅後綠)。`mvn verify` 全綠;
  應用連 compose MySQL 啟動 health UP;全新 broker topic 乾淨。
  插曲:host 9092 被舊專案程序(java PID 11799/17092 + ssh tunnel)佔用,
  對外埠改 19092 並關 auto-create topics;Jeff 的程序未動。
  Write-back:wiki/kafka-basics.md。
- 2026-07-15:**Task 1** 完成(PR #2,已 merge)——Maven 多模組骨架
  (parent + libs/common + app/wallet)、ping API、actuator、springdoc、
  Spotless/Checkstyle。`mvn verify` 綠、三端點實測通過。
  版本決策:Spring Boot 3.5.16(Jeff 拍板;4.x 已 GA,升版留作日後素材)。
- 2026-07-15:Phase 0 設計定案 + 專案轉向(ADR 0001/0002),文件 PR #3 已 merge。
- 2026-07-13:Repo 初始化。

## Next up

- Task 4:Terraform GCP 基礎(GCS backend、Artifact Registry、
  GKE Autopilot @ asia-east1、Cloud SQL MySQL 8、workload identity SA)
  + CI 加 tf-validate job。需要 Jeff 的 GCP 專案資訊與 gcloud 登入。

## Open questions

-(留待 Phase 3 前)雲端 Kafka 部署方式:GCP Managed Service for
  Apache Kafka vs GKE 自架單節點,以 ADR 定案(ADR 0002 決策第 3 點)。
-(已解決 2026-07-15)9092 汙染源是搶票系統的 order/seckill 兩個殘留
  服務(跑了 12 天),Jeff 拍板關閉;lsof 裡的 ssh 是 Colima 的
  port-forward 不是 tunnel,未動。Kafka 維持 9092,auto-create 關閉。

## 協作提醒

- Jeff 不熟 Kafka:動用 Kafka 的討論與 PR 導讀要從零講解概念,
  並編纂進知識庫 wiki(CLAUDE.md、ADR 0002)。
