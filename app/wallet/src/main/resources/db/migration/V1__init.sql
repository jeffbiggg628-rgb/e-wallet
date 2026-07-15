-- Baseline schema: the five core tables from plan §5.
-- All monetary amounts are BIGINT minor units (plan §4-4: no floating point).

-- User wallet accounts plus system accounts (external / fee / suspense).
CREATE TABLE accounts (
    id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    owner_id    VARCHAR(64)     NOT NULL,
    type        VARCHAR(32)     NOT NULL,
    currency    CHAR(3)         NOT NULL,
    created_at  TIMESTAMP(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_accounts_owner (owner_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Balance projection; rebuildable from ledger_entries (plan §4-3).
CREATE TABLE wallets (
    account_id  BIGINT UNSIGNED NOT NULL,
    balance     BIGINT          NOT NULL DEFAULT 0,
    updated_at  TIMESTAMP(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    version     BIGINT          NOT NULL DEFAULT 0,
    PRIMARY KEY (account_id),
    CONSTRAINT fk_wallets_account FOREIGN KEY (account_id) REFERENCES accounts (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- One row per business action; idempotency_key makes money operations replay-safe (plan §4-5).
CREATE TABLE transactions (
    id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idempotency_key  VARCHAR(64)     NOT NULL,
    type             VARCHAR(32)     NOT NULL,
    status           VARCHAR(32)     NOT NULL,
    created_at       TIMESTAMP(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_transactions_idempotency_key (idempotency_key)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Double-entry lines: each transaction produces >= 2 entries summing to zero (plan §4-2).
-- Append-only (plan §4-1): UPDATE/DELETE forbidden; corrections use reversal entries.
CREATE TABLE ledger_entries (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    transaction_id  BIGINT UNSIGNED NOT NULL,
    account_id      BIGINT UNSIGNED NOT NULL,
    amount          BIGINT          NOT NULL,
    direction       ENUM ('DEBIT', 'CREDIT') NOT NULL,
    created_at      TIMESTAMP(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_ledger_entries_transaction (transaction_id),
    KEY idx_ledger_entries_account (account_id),
    CONSTRAINT fk_ledger_entries_transaction FOREIGN KEY (transaction_id) REFERENCES transactions (id),
    CONSTRAINT fk_ledger_entries_account FOREIGN KEY (account_id) REFERENCES accounts (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Transactional outbox: written in the same DB transaction as the business change (plan §4-6).
CREATE TABLE outbox_events (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    aggregate_type  VARCHAR(64)     NOT NULL,
    aggregate_id    VARCHAR(64)     NOT NULL,
    event_type      VARCHAR(64)     NOT NULL,
    payload         JSON            NOT NULL,
    created_at      TIMESTAMP(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    published_at    TIMESTAMP(6)    NULL,
    PRIMARY KEY (id),
    KEY idx_outbox_unpublished (published_at, id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
