-- 1. test trigger block copy (WARNING: must use existing consensus address)
SELECT consensus_address FROM public.validator LIMIT 1;
INSERT INTO public.block (height, hash, num_txs, total_gas, proposer_address, "timestamp")
VALUES (1001000, 'blockhash1', 1, 10000, 'mevalcons15jy98ves4lqqw3l8dxr7qprf9ycc7nnklr2u03', NOW());
SELECT * FROM public.block_copy WHERE height=1001000;

-- 2. test trigger transaction copy
INSERT INTO public."transaction" (
    hash, height, success, messages, memo, signatures,
    signer_infos, fee, gas_wanted, gas_used, raw_log,
    logs, partition_id
) VALUES (
    'txhash1', 1001000, TRUE, '[{"msg":"test"}]', 'memo1', ARRAY['sig1'],
    '[{"signer":"signer1"}]', '{"amount":100}', 20000, 15000, 'rawlog1',
    '[{"log":"log1"}]', 0
);
SELECT * FROM public.transaction_copy WHERE hash='txhash1' AND partition_id=0;

-- 3. test trigger message copy (WARNING: must use existing message type)
SELECT "type" FROM public.message_type LIMIT 1;
INSERT INTO public.message (
    transaction_hash, "index", "type", value,
    involved_accounts_addresses, partition_id, height
) VALUES (
    'txhash1', 0, 'metaearth.kyc.MsgUpdate', '{"key":"value"}',
    ARRAY['addr1','addr2'], 0, 1001000
);
SELECT * FROM public.message_copy WHERE transaction_hash='txhash1' AND "index"=0 AND partition_id=0;

-- 4. test trigger parsed message copy
INSERT INTO public.parsed_message (
    height, tx_hash, msg_index, detail, msg_type, description
) VALUES (
    1001000, 'txhash1', 0, '{"detail":"d"}', 'type1', 'desc1'
);
SELECT * FROM public.parsed_message_copy WHERE height=1001000 AND tx_hash='txhash1' AND msg_index=0;

-- 5. test trigger fee records copy
INSERT INTO public.fee_records (
    id, created_at, updated_at, deleted_at,
    height, tx_hash, fee_payer, fee_amount,
    fee_denom, invoke_address, receivers,
    partition_id
) VALUES (
    1, NOW(), NOW(), NULL,
    1001000, 'txhash1', 'payer1', 12345,
    'denom1', ARRAY['invoke1'], NULL,
    0
);
SELECT * FROM public.fee_records_copy WHERE tx_hash='txhash1' AND height=1001000;

