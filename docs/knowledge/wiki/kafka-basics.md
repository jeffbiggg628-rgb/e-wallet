---
type: Design Concept
title: Kafka 基礎——log、topic、partition、consumer group 與 listeners
description: Kafka 的心智模型(它是 log 不是 queue)、四個核心概念、KRaft、advertised.listeners 經典坑(含本專案實例)
tags: [kafka, messaging, phase0, interview]
date: 2026-07-15
source: Phase 0 Task 2(docker-compose 首次引入 Kafka)的 PR 導讀;ADR 0002 講解義務
---

# Kafka 基礎

## 心智模型:它是分散式 commit log,不是 queue

傳統 message queue(如 RabbitMQ):訊息被消費就刪除,broker 幫你記進度。
Kafka:producer 把訊息 **append** 到一個只增不減的 log,訊息**留在原地**
(依保留策略過期),**consumer 自己記「讀到哪」**。這個差異是一切的根源——
訊息可重放(replay)、多組 consumer 互不干擾地讀同一份資料、
以及我們 Phase 3 要做的 effectively-once 消費。

對本專案的呼應:「append-only log + 讀取進度是 consumer 自己的投影」
和 ledger 的「append-only 分錄 + 餘額是投影」是同一種哲學。

## 四個核心概念

| 概念 | 是什麼 | 關鍵點 |
|---|---|---|
| **topic** | 訊息的邏輯分類(如 `wallet.transfer.completed`) | 只是名字,實體是底下的 partitions |
| **partition** | topic 切成的多份 log | **順序只在單一 partition 內保證**;同 key 的訊息進同 partition(key = 帳戶 ID → 同帳戶事件有序) |
| **consumer group** | 一組分工消費的 consumer | 一個 partition 同時只給組內一個 consumer;加 consumer = 水平擴展(上限 = partition 數) |
| **offset** | consumer 在某 partition 的讀取位置 | consumer 定期 commit offset;crash 後從上次 commit 處重讀 → **at-least-once,重複投遞是常態**,冪等是 consumer 的責任(plan §4-7) |

## KRaft

Kafka 自 3.x 起內建共識協定 KRaft,取代舊時代的 ZooKeeper 外部依賴。
單節點 KRaft(process_roles: broker,controller)是本地開發標配——
我們的 docker-compose 就是這個形態。

## 經典坑:advertised.listeners(本專案 2026-07-15 實戰)

Kafka 連線是兩段式:client 先連 bootstrap server 拿 metadata,
metadata 裡寫著「每個 partition 的 leader 在 `advertised.listeners` 這個位址」,
client 再照那個位址連。**所以 advertised 位址必須是 client 視角可達的**,
否則第一段連得上、第二段永遠失敗——這是 Docker/K8s 上 Kafka 最常見的故障。

本專案實例:host 的 9092 被無關程序佔用(舊專案 java 服務 + ssh tunnel),
還把流量灌進我們的 broker 自動建了別人的 topics。解法(見 docker-compose.yml):
- 對外改走 **19092**,並設雙 listener:`INTERNAL://kafka:29092`(容器網路內)
  + `EXTERNAL://localhost:19092`(host 視角)。
- 順手關掉 `auto.create.topics.enable`——資金系統的 topic 必須顯式建立,
  不接受「打錯字自動生一個新 topic」。

## 面試可能怎麼問

- **Q:Kafka 怎麼保證訊息順序?**
  A:只在單一 partition 內保證。要業務有序就選對 partition key
  (例如帳戶 ID),讓同一實體的事件落同一 partition。
- **Q:為什麼會收到重複訊息?怎麼辦?**
  A:offset commit 與處理不是原子的,crash 重啟必然重讀 → at-least-once。
  解法不是求 broker exactly-once,而是 consumer 冪等(以事件 ID / 冪等鍵
  去重),即 effectively-once——本專案 plan §4-7 的不變量。
- **Q:container 裡的 Kafka 為什麼 host 連不上?**
  A:九成是 advertised.listeners 回了 client 不可達的位址,用雙 listener 分開
  容器內與 host 視角。
