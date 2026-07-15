# Terraform — GCP 基礎資源

定義 e-wallet 的雲端基礎:Artifact Registry、GKE Autopilot(asia-east1)、
Cloud SQL for MySQL 8(最小機型)、workload identity 用的 least-privilege SA。

## 成本策略:apply-verify-destroy(plan §6 Phase 0)

GKE 與 Cloud SQL **不常駐**。代碼永遠在,資源只在驗證/demo 時存在:

```
terraform apply   # 建立(GKE 約 10-15 分鐘)
# ...部署、驗證、截證據(見 docs/design/phase0-cloud-verification.md)
terraform destroy # 拆除,回到零成本
```

破壞式保護(deletion_protection)刻意關閉,就是為了讓 destroy 順暢。
**惟一常駐**的是 state bucket(幾乎零成本)與已啟用的 API。

## 一次性前置(已完成,記錄供重建)

```
gcloud auth login && gcloud auth application-default login
gcloud projects create e-wallet-portfolio-4291 --name="e-wallet-portfolio"
gcloud billing projects link e-wallet-portfolio-4291 --billing-account=<你的帳單帳戶>
gcloud config set project e-wallet-portfolio-4291
gcloud storage buckets create gs://e-wallet-portfolio-4291-tfstate \
  --location=asia-east1 --uniform-bucket-level-access
gcloud storage buckets update gs://e-wallet-portfolio-4291-tfstate --versioning
```

## 日常操作

```
terraform init      # 首次或 backend/provider 變更後
terraform fmt       # 格式化
terraform validate  # 語法與內部一致性
terraform plan      # 預覽差異(不收費、不改現實)
```

## 設計筆記

- **state 放 GCS**(versioning 開啟):state 是「現實長怎樣」的唯一紀錄,
  掉了 Terraform 就瞎了;bucket 版本控管是 state 的後悔藥。
- **DB 密碼由 `random_password` 產生**,存在 state 與 output(sensitive),
  不進 git。取用:`terraform output -raw wallet_db_password`。
- **Cloud SQL 不開 authorized networks**:一律走 Cloud SQL Auth Proxy
  (IAM 閘門,`roles/cloudsql.client`),對齊 PCA 考點的標準做法。
- **`.terraform.lock.hcl` 要進 git**(provider 版本鎖定,同 Maven 鎖版本的精神);
  `.terraform/`(下載的 provider 本體)不進。
