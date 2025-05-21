DROP MATERIALIZED VIEW IF EXISTS public.complex_txs_mateview;

CREATE MATERIALIZED VIEW public.complex_txs_mateview AS
SELECT
    pm.transaction_hash,
    pm."index",
    pm.height,
    pm."type",
    pm.value,
    pm.detail,
    pm.involved_accounts_addresses as addresses,
    pt.memo,
    pfc.fee_amount,
    pfc.fee_denom,
    pt.success,
    pmt.business_msg_type,
    pblc.business_type,
    pt."timestamp"
FROM
    (SELECT m.*, pm.detail
     FROM public.message m
     LEFT JOIN public.parsed_message pm ON m.transaction_hash = pm.tx_hash AND m."index" = pm.msg_index) pm
JOIN
    (SELECT t.hash, t.success, t.memo, t.gas_wanted, t.gas_used, b."timestamp"
     FROM public."transaction" t, public.block b
     WHERE t.height = b.height and t.height < 8000000) pt
ON pt.hash = pm.transaction_hash
LEFT JOIN
    (SELECT fc.tx_hash, fc.fee_amount, fc.fee_denom
     FROM public.fee_records fc) pfc
ON pfc.tx_hash = pm.transaction_hash
LEFT JOIN 
    (SELECT mt.type, mt.business_msg_type 
     FROM public.message_type mt) pmt 
ON pm."type" = pmt."type"
LEFT JOIN 
    (SELECT blc."label", blc.business_type 
     FROM public.business_label_config blc) pblc 
ON pt.memo = pblc."label"
WITH DATA;


-- key and index
CREATE UNIQUE INDEX complex_txs_mv_pkey ON public.complex_txs_mateview (transaction_hash, "index");
CREATE INDEX complex_txs_mv_addresses_idx ON public.complex_txs_mateview (addresses);
CREATE INDEX complex_txs_mv_height_idx ON public.complex_txs_mateview (height);
CREATE INDEX complex_txs_mv_timestamp_idx ON public.complex_txs_mateview ("timestamp");
-- CREATE INDEX complex_txs_mv_success_idx ON public.complex_txs_mateview (success);


-- REFRESH MATERIALIZED VIEW public.complex_txs_mateview;
