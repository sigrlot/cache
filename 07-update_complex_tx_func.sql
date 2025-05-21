DROP FUNCTION IF EXISTS all_complex_txs_func;
DROP FUNCTION IF EXISTS complex_txs_func;
DROP TABLE IF EXISTS public.complex_txs_result;


CREATE TABLE IF NOT EXISTS public.complex_txs_result (
                                                         transaction_hash text NULL,
                                                         "index" int8 NULL,
                                                         net_type text NULL,
                                                         height int8 NULL,
                                                         "type" text NULL,
                                                         value json NULL,
                                                         detail jsonb NULL,
                                                         memo text null,
                                                         fee_amount int8 NULL,
                                                         fee_denom text NULL,
                                                         success bool NULL,
                                                         "timestamp" timestamptz NULL
);


-- get complex txs
CREATE OR REPLACE FUNCTION all_complex_txs_func(
    address TEXT,
    net_filter _TEXT,
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ
)
RETURNS SETOF complex_txs_result
 LANGUAGE plpgsql
 STABLE
 AS $function$
BEGIN
    -- PERFORM set_config('jit', 'off', true);
    RETURN QUERY
    SELECT 
        pm.transaction_hash, 
        pm."index",
        'hub' AS net_type,
		pm.height,
        pm."type",
        pm.value,
        pm.detail,
		pt.memo,
		pfc.fee_amount,
		pfc.fee_denom,
		pt.success,
        pt."timestamp"
    FROM 
        (SELECT m.*, pm.detail 
         FROM public.message_copy m
		 left join public.parsed_message_copy pm on m.transaction_hash = pm.tx_hash AND m."index" = pm.msg_index
         WHERE address <@ m.involved_accounts_addresses) pm
    JOIN 
        (SELECT t.hash, t.success, t.memo, t.gas_wanted, t.gas_used, b."timestamp" 
         FROM public.transaction_copy t, public.block_copy b 
         WHERE b."timestamp" BETWEEN start_time AND end_time
           AND t.height = b.height) pt 
    ON pt.hash = pm.transaction_hash
    LEFT JOIN 
        (SELECT fc.tx_hash, fc.fee_amount, fc.fee_denom 
         FROM public.fee_records_copy fc) pfc 
    ON pfc.tx_hash = pm.transaction_hash
    WHERE 'hub' = ANY(net_filter)
UNION ALL
	SELECT 
		ptmv.transaction_hash,
		ptmv."index",
	    'hub' AS net_type,
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
        'hub' = ANY(net_filter)
		AND address <@ ptmv.addresses
        AND ptmv."timestamp" BETWEEN start_time AND end_time
UNION ALL
    SELECT 
        rm.transaction_hash, 
        rm."index",
        'rollapp_checkin' AS net_type,
		rm.height,
        rm."type",
        rm.value::json,
        rm.detail,
		rt.memo,
		rfc.fee_amount,
		rfc.fee_denom,
		rt.success,
        rt."timestamp"
    FROM 
        (SELECT m.*, pm.detail 
         FROM rollapp_checkin.message_copy m
		 left join rollapp_checkin.parsed_message_copy pm on m.transaction_hash = pm.tx_hash AND m."index" = pm.msg_index
         WHERE address <@ m.involved_accounts_addresses) rm
    JOIN 
        (SELECT t.hash, t.success, t.memo, t.gas_wanted, t.gas_used, b."timestamp" 
         FROM rollapp_checkin.transaction_copy t, rollapp_checkin.block_copy b 
         WHERE b."timestamp" BETWEEN start_time AND end_time
           AND t.height = b.height) rt 
    ON rt.hash = rm.transaction_hash
    LEFT JOIN 
        (SELECT fc.tx_hash, fc.fee_amount, fc.fee_denom 
         FROM rollapp_checkin.fee_records_copy fc) rfc 
    ON rfc.tx_hash = rm.transaction_hash
    WHERE 'rollapp_checkin' = ANY(net_filter)
UNION ALL
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
        'rollapp_checkin' = ANY(net_filter)
		AND address <@ rtmv.addresses
        AND rtmv."timestamp"  BETWEEN start_time AND end_time;
END;
$function$;


-- get complex txs by business module
CREATE OR REPLACE FUNCTION public.complex_txs_func(address text, module text, net_filter text[], start_time timestamp with time zone, end_time timestamp with time zone)
 RETURNS SETOF complex_txs_result
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    -- PERFORM set_config('jit', 'off', true);
    RETURN QUERY
    SELECT 
        pm.transaction_hash, 
        pm."index",
        'hub' AS net_type,
		pm.height,
        pm."type",
        pm.value,
        pm.detail,
		pt.memo,
		pfc.fee_amount,
		pfc.fee_denom,
		pt.success,
        pt."timestamp"
    FROM 
        (SELECT m.*, pm.detail 
         FROM public.message_copy m
		 left join public.parsed_message_copy pm on m.transaction_hash = pm.tx_hash AND m."index" = pm.msg_index
         WHERE address <@ m.involved_accounts_addresses) pm
    JOIN 
        (SELECT t.hash, t.success, t.memo, t.gas_wanted, t.gas_used, b."timestamp" 
         FROM public.transaction_copy t, public.block_copy b 
         WHERE b."timestamp"  BETWEEN start_time AND end_time
           AND t.height = b.height) pt 
    ON pt.hash = pm.transaction_hash
    LEFT JOIN 
        (SELECT fc.tx_hash, fc.fee_amount, fc.fee_denom 
         FROM public.fee_records_copy fc) pfc 
    ON pfc.tx_hash = pm.transaction_hash
    LEFT JOIN 
        (SELECT mt.type, mt.business_msg_type 
         FROM public.message_type mt) pmt 
    ON pm."type" = pmt."type"
    LEFT JOIN 
        (SELECT blc."label", blc.business_type 
         FROM public.business_label_config blc) pblc 
    ON pt.memo = pblc."label"
    WHERE (module = ANY(pmt.business_msg_type) OR pblc.business_type = module)
      AND ('hub' = ANY(net_filter))
UNION ALL
	SELECT 
		ptmv.transaction_hash,
		ptmv."index",
	    'hub' AS net_type,
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
        'hub' = ANY(net_filter)
		AND address <@ ptmv.addresses
        AND ptmv."timestamp" BETWEEN start_time AND end_time
		AND (module = ptmv.business_type OR module <@ ptmv.business_msg_type)
UNION ALL
    SELECT 
        rm.transaction_hash, 
        rm."index",
        'rollapp_checkin' AS net_type,
		rm.height,
        rm."type",
        rm.value::json,
        rm.detail,
		rt.memo,
		rfc.fee_amount,
		rfc.fee_denom,
		rt.success,
        rt."timestamp"
    FROM 
        (SELECT m.*, pm.detail 
         FROM rollapp_checkin.message_copy m
		 left join rollapp_checkin.parsed_message_copy pm on m.transaction_hash = pm.tx_hash AND m."index" = pm.msg_index
         WHERE address <@ m.involved_accounts_addresses) rm
    JOIN 
        (SELECT t.hash, t.success, t.memo, t.gas_wanted, t.gas_used, b."timestamp" 
         FROM rollapp_checkin.transaction_copy t, rollapp_checkin.block_copy b 
         WHERE b."timestamp" BETWEEN start_time AND end_time
           AND t.height = b.height) rt 
    ON rt.hash = rm.transaction_hash
    LEFT JOIN 
        (SELECT fc.tx_hash, fc.fee_amount, fc.fee_denom 
         FROM rollapp_checkin.fee_records_copy fc) rfc 
    ON rfc.tx_hash = rm.transaction_hash
    LEFT JOIN 
        (SELECT mt.type, mt.business_msg_type 
         FROM rollapp_checkin.message_type mt) rmt 
    ON rm."type" = rmt."type"
    WHERE (module <@ rmt.business_msg_type)
      AND ('rollapp_checkin' = ANY(net_filter))
UNION ALL
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
        'rollapp_checkin' = ANY(net_filter)
		AND address <@ rtmv.addresses
        AND rtmv."timestamp" BETWEEN start_time AND end_time
		AND (module = rtmv.business_type OR module <@ rtmv.business_msg_type);
END;
$function$
;


