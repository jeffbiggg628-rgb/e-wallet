# Phase 0 雲端驗證紀錄(apply-verify-destroy 第一輪)

- **日期**:2026-07-15
- **專案**:`e-wallet-portfolio-4291`(asia-east1)
- **目的**:證明整條交付路是通的——Terraform 建雲端資源 → 推 image →
  GKE 部署 → 應用經 Workload Identity + Cloud SQL Auth Proxy 連上
  Cloud SQL 並跑 Flyway → 拆除歸零。

## 執行紀錄與證據

### 1. `terraform apply`

第一次 apply:**14/15 成功、1 失敗**(exit 1)。關鍵時間:
GKE Autopilot 6m28s、Cloud SQL 8m21s。失敗的資源與修復見下方「事故紀錄」。
修復後補 apply:`Apply complete! Resources: 1 added`。最終 state 共 **15 個資源**。

### 2. 推送 image(跨平台)

開發機是 Apple Silicon(arm64),GKE 節點是 amd64,必須跨平台建置:

```
docker buildx build --platform linux/amd64 \
  -t asia-east1-docker.pkg.dev/e-wallet-portfolio-4291/e-wallet/wallet:phase0 --push .
# → pushing manifest ... DONE(digest sha256:b47a7075…)
```

### 3. GKE 部署與驗證

```
kubectl create secret generic wallet-db --from-literal=password=$(terraform output -raw wallet_db_password)
kubectl apply -f infra/k8s/
# → deployment "wallet" successfully rolled out
# → pod/wallet-58945b4657-294kw   2/2   Running
```

端對端驗證(`kubectl port-forward svc/wallet`):

```
GET /actuator/health → {"status":"UP","groups":["liveness","readiness"]}
GET /api/v1/ping     → {"status":"ok"}
```

Pod 內 wallet container 的啟動 log 證明 Flyway 在 **Cloud SQL** 上完成遷移:

```
Migrating schema `wallet` to version "1 - init"
Successfully applied 1 migration to schema `wallet`, now at version v1 (00:00.279s)
Started WalletApplication in 13.185 seconds
```

這一條 UP 同時證明了:Workload Identity(pod 無金鑰冒用 wallet-app SA)
→ Cloud SQL Auth Proxy(IAM 閘門)→ MySQL 8 → Flyway → MyBatis 全線貫通。

### 4. `terraform destroy`

```
Destroy complete! Resources: 15 destroyed.  (exit 0)
terraform state list → 0 resources
gcloud container clusters list / sql instances list → Listed 0 items
```

常駐資源僅剩 state bucket 與已啟用的 API(皆近零成本)。

## 事故紀錄:Workload Identity 綁定失敗(教材)

**現象**:pod 起來後 wallet container CrashLoopBackOff(restarts=5),
proxy log 顯示 `iam.serviceAccounts.getAccessToken denied ... 403`。

**根因**:workload identity pool(`<project>.svc.id.goog`)**是專案內第一個
GKE 叢集建立時才誕生的**。`google_service_account_iam_member` 綁定沒有宣告
對叢集的依賴,Terraform 平行建立時綁定先執行 → `Identity Pool does not
exist` 400。第一次 apply 實際 exit 1,但被驗證指令中的 `echo` 蓋掉、
一度誤判為成功——**教訓:驗 exit code 要驗對象,結果要以資源實況為準**
(`gcloud iam service-accounts get-iam-policy` 查到 policy 為空才確診)。

**修復**:`iam.tf` 對該綁定加 `depends_on = [google_container_cluster.main]`,
補 apply 後刪 pod 重排,rollout 成功。

**面試版一句話**:「WI pool 的生命週期跟著專案的第一個 GKE 叢集,
IaC 裡凡引用 `svc.id.goog` 的綁定都要顯式依賴叢集資源。」

## 花費

- 本輪資源存活約 1 小時(GKE Autopilot 單 pod + db-f1-micro)
- 估算 < US$1;帳單延遲入帳,實際數字待 GCP Billing 結算後回填於此:
  - [ ] 實際花費:____(待查)

## 重現步驟

見 `infra/terraform/README.md` 的 apply-verify-destroy 手冊;
k8s 部署指令如上(secret → apply -f → rollout status → port-forward)。
