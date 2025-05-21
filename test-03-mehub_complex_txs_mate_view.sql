-- mateview: rollapp_checkin.complex_txs_mateview
SELECT 
    ptmv.transaction_hash,
    ptmv."index",
    'rollapp_checkin' AS net_type,
    ptmv.height,
    ptmv."type",
    ptmv.value,
    ptmv.detail,
    ptmv.memo,
    ptmv.fee_amount,
    ptmv.fee_denom,
    ptmv.success,
    ptmv."timestamp"
FROM 
    public.complex_txs_mateview ptmv
WHERE 
    'addr1' = ANY(ptmv.addresses)
    AND ptmv."timestamp" BETWEEN '2020-05-20 15:30:40.265 +0800' AND '2025-06-20 15:30:40.265 +0800'
    AND ('staking' = ptmv.business_type OR 'staking' = ANY(ptmv.business_msg_type));