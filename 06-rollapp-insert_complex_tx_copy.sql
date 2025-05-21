-- 1. parsed_message -> parsed_message_copy
INSERT INTO rollapp_checkin.parsed_message_copy (height, tx_hash, msg_index, detail, msg_type, description)
SELECT height, tx_hash, msg_index, detail, msg_type, description
FROM rollapp_checkin.parsed_message
WHERE height > 1000000
ON CONFLICT (height, tx_hash, msg_index) DO UPDATE SET
    detail = EXCLUDED.detail,
    msg_type = EXCLUDED.msg_type,
    description = EXCLUDED.description;

-- 2. block -> block_copy
INSERT INTO rollapp_checkin.block_copy (height, hash, num_txs, total_gas, proposer_address, "timestamp")
SELECT height, hash, num_txs, total_gas, proposer_address, "timestamp"
FROM rollapp_checkin.block
WHERE height > 1000000
ON CONFLICT (height) DO UPDATE SET
    hash = EXCLUDED.hash,
    num_txs = EXCLUDED.num_txs,
    total_gas = EXCLUDED.total_gas,
    proposer_address = EXCLUDED.proposer_address,
    "timestamp" = EXCLUDED."timestamp";

-- 3. transaction -> transaction_copy
INSERT INTO rollapp_checkin.transaction_copy (
    hash, height, success, messages, memo, signatures,
    signer_infos, fee, gas_wanted, gas_used, raw_log,
    logs, partition_id
)
SELECT
    hash, height, success, messages, memo, signatures,
    signer_infos, fee, gas_wanted, gas_used, raw_log,
    logs, partition_id
FROM rollapp_checkin."transaction"
WHERE height > 1000000
ON CONFLICT (hash, partition_id) DO UPDATE SET
    height = EXCLUDED.height,
    success = EXCLUDED.success,
    messages = EXCLUDED.messages,
    memo = EXCLUDED.memo,
    signatures = EXCLUDED.signatures,
    signer_infos = EXCLUDED.signer_infos,
    fee = EXCLUDED.fee,
    gas_wanted = EXCLUDED.gas_wanted,
    gas_used = EXCLUDED.gas_used,
    raw_log = EXCLUDED.raw_log,
    logs = EXCLUDED.logs;

-- 4. message -> message_copy
INSERT INTO rollapp_checkin.message_copy (
    transaction_hash, "index", "type", value,
    involved_accounts_addresses, partition_id, height
)
SELECT
    transaction_hash, "index", "type", value,
    involved_accounts_addresses, partition_id, height
FROM rollapp_checkin.message
WHERE height > 1000000
ON CONFLICT (transaction_hash, "index", partition_id) DO UPDATE SET
    "type" = EXCLUDED."type",
    value = EXCLUDED.value,
    involved_accounts_addresses = EXCLUDED.involved_accounts_addresses,
    height = EXCLUDED.height;

-- 5. fee_records -> fee_records_copy
INSERT INTO rollapp_checkin.fee_records_copy (
    id, created_at, updated_at, deleted_at,
    height, tx_hash, fee_payer, fee_amount,
    fee_denom, invoke_address, receivers,
    partition_id
)
SELECT
    id, created_at, updated_at, deleted_at,
    height, tx_hash, fee_payer, fee_amount,
    fee_denom, invoke_address, receivers,
    partition_id
FROM rollapp_checkin.fee_records
WHERE height > 1000000
ON CONFLICT (tx_hash, height) DO UPDATE SET
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    deleted_at = EXCLUDED.deleted_at,
    fee_payer = EXCLUDED.fee_payer,
    fee_amount = EXCLUDED.fee_amount,
    fee_denom = EXCLUDED.fee_denom,
    invoke_address = EXCLUDED.invoke_address,
    receivers = EXCLUDED.receivers,
    partition_id = EXCLUDED.partition_id;

