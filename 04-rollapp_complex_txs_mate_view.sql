DROP MATERIALIZED VIEW IF EXISTS rollapp_checkin.complex_txs_mateview;

CREATE MATERIALIZED VIEW rollapp_checkin.complex_txs_mateview AS
SELECT
    rm.transaction_hash,
    rm."index",
    rm.height,
    rm."type",
    rm.value::json,
    rm.detail,
    rm.involved_accounts_addresses as addresses,
    rt.memo,
    rfc.fee_amount,
    rfc.fee_denom,
    rt.success,
    rmt.business_msg_type,
    '' as business_type,
    rt."timestamp"
FROM
    (SELECT m.*, pm.detail
     FROM rollapp_checkin.message m
     LEFT JOIN rollapp_checkin.parsed_message pm ON m.transaction_hash = pm.tx_hash AND m."index" = pm.msg_index) rm
JOIN
    (SELECT t.hash, t.success, t.memo, t.gas_wanted, t.gas_used, b."timestamp"
     FROM rollapp_checkin."transaction" t, rollapp_checkin.block b
     WHERE t.height = b.height and t.height < 8000000) rt
ON rt.hash = rm.transaction_hash
LEFT JOIN
    (SELECT fc.tx_hash, fc.fee_amount, fc.fee_denom
     FROM rollapp_checkin.fee_records fc) rfc
ON rfc.tx_hash = rm.transaction_hash
LEFT JOIN 
    (SELECT mt.type, mt.business_msg_type 
     FROM rollapp_checkin.message_type mt) rmt 
ON rm."type" = rmt."type"
WITH DATA;


-- key and index
CREATE UNIQUE INDEX complex_txs_mv_pkey ON rollapp_checkin.complex_txs_mateview (transaction_hash, "index");
CREATE INDEX complex_txs_mv_addresses_idx ON rollapp_checkin.complex_txs_mateview (addresses);
CREATE INDEX complex_txs_mv_height_idx ON rollapp_checkin.complex_txs_mateview (height);
CREATE INDEX complex_txs_mv_timestamp_idx ON rollapp_checkin.complex_txs_mateview ("timestamp");
-- CREATE INDEX complex_txs_mv_success_idx ON rollapp_checkin.complex_txs_mateview (success);


-- REFRESH MATERIALIZED VIEW rollapp_checkin.complex_txs_mateview;
