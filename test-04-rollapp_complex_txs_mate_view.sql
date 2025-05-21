-- mateview: rollapp_checkin.complex_txs_mateview
SELECT 
    rtmv.transaction_hash,
    rtmv."index",
    'rollapp_checkin' AS net_type,
    rtmv.height,
    rtmv."type",
    rtmv.value,
    rtmv.detail,
    rtmv.memo,
    rtmv.fee_amount,
    rtmv.fee_denom,
    rtmv.success,
    rtmv."timestamp"
FROM 
    rollapp_checkin.complex_txs_mateview rtmv
WHERE 
    'addr1' = ANY(rtmv.addresses)
    AND rtmv."timestamp" BETWEEN '2020-05-20 15:30:40.265 +0800' AND '2025-06-20 15:30:40.265 +0800'
    AND ('checkin' = rtmv.business_type OR 'checkin' = ANY(rtmv.business_msg_type));