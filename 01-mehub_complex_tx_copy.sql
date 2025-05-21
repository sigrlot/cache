-- create table
DROP TABLE IF EXISTS public.parsed_message_copy;
CREATE TABLE IF NOT EXISTS public.parsed_message_copy (
    height int8 NOT NULL,
    tx_hash text NOT NULL,
    msg_index int8 NOT NULL,
    detail jsonb NULL,
    msg_type text NULL,
    description text NULL,
    CONSTRAINT parsed_message_copy_pkey PRIMARY KEY (height, tx_hash, msg_index)
);
CREATE UNIQUE INDEX idx_parsed_message_copy_hash_msg_index_height ON public.parsed_message_copy (height,tx_hash,msg_index);
CREATE INDEX idx_parsed_message_copy_msg_index ON public.parsed_message_copy (msg_index);
CREATE INDEX idx_parsed_message_copy_msg_type ON public.parsed_message_copy (msg_type);
CREATE INDEX idx_parsed_message_copy_tx_hash ON public.parsed_message_copy (tx_hash);


-- create trigger func
CREATE OR REPLACE FUNCTION public.parsed_message_copy_func()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.parsed_message_copy (
        height,
        tx_hash,
        msg_index,
        detail,
        msg_type,
        description
    ) VALUES (
        NEW.height,
        NEW.tx_hash,
        NEW.msg_index,
        NEW.detail,
        NEW.msg_type,
        NEW.description
    )
    ON CONFLICT (height, tx_hash, msg_index) 
    DO UPDATE SET
        detail = EXCLUDED.detail,
        msg_type = EXCLUDED.msg_type,
        description = EXCLUDED.description;
    
    RETURN NEW;
END;
$$;


-- create trigger
DROP TRIGGER IF EXISTS parsed_message_copy_trigger ON public.parsed_message;
CREATE TRIGGER parsed_message_copy_trigger
AFTER INSERT ON public.parsed_message
FOR EACH ROW
EXECUTE FUNCTION public.parsed_message_copy_func();


-- create table
DROP TABLE IF EXISTS public.block_copy;
CREATE TABLE IF NOT EXISTS public.block_copy (
	height int8 NOT NULL,
	hash text NOT NULL,
	num_txs int4 DEFAULT 0 NULL,
	total_gas int8 DEFAULT 0 NULL,
	proposer_address text NULL,
	"timestamp" timestamptz NOT NULL,
	CONSTRAINT block_copy_hash_key UNIQUE (hash),
	CONSTRAINT block_copy_pkey PRIMARY KEY (height),
	CONSTRAINT block_copy_proposer_address_fkey FOREIGN KEY (proposer_address) REFERENCES public."validator"(consensus_address)
)
WITH (
	autovacuum_vacuum_scale_factor=0,
	autovacuum_analyze_scale_factor=0,
	autovacuum_vacuum_threshold=10000,
	autovacuum_analyze_threshold=10000
);
CREATE INDEX block_copy_hash_index ON public.block_copy USING btree (hash);
CREATE INDEX block_copy_height_index ON public.block_copy USING btree (height);
CREATE INDEX block_copy_proposer_address_index ON public.block_copy USING btree (proposer_address);


-- create trigger func
CREATE OR REPLACE FUNCTION public.block_copy_func()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.block_copy (
        height,
        hash,
        num_txs,
        total_gas,
        proposer_address,
        "timestamp"
    ) VALUES (
        NEW.height,
        NEW.hash,
        NEW.num_txs,
        NEW.total_gas,
        NEW.proposer_address,
        NEW."timestamp"
    )
    ON CONFLICT (height) 
    DO UPDATE SET
        hash = EXCLUDED.hash,
        num_txs = EXCLUDED.num_txs,
        total_gas = EXCLUDED.total_gas,
        proposer_address = EXCLUDED.proposer_address,
        "timestamp" = EXCLUDED."timestamp";
    
    RETURN NEW;
END;
$$;


-- create trigger
DROP TRIGGER IF EXISTS block_copy_trigger ON public.block;
CREATE TRIGGER block_copy_trigger
AFTER INSERT ON public.block
FOR EACH ROW
EXECUTE FUNCTION public.block_copy_func();


-- create table
DROP TABLE IF EXISTS public.transaction_copy;
CREATE TABLE IF NOT EXISTS public.transaction_copy (
    hash text NOT NULL,
    height int8 NOT NULL,
    success bool NOT NULL,
    messages json DEFAULT '[]'::json NOT NULL,
    memo text NULL,
    signatures _text NOT NULL,
    signer_infos jsonb DEFAULT '[]'::jsonb NOT NULL,
    fee jsonb DEFAULT '{}'::jsonb NOT NULL,
    gas_wanted int8 DEFAULT 0 NULL,
    gas_used int8 DEFAULT 0 NULL,
    raw_log text NULL,
    logs jsonb NULL,
    partition_id int8 DEFAULT 0 NOT NULL,
    CONSTRAINT transaction_copy_unique_tx UNIQUE (hash, partition_id),
    CONSTRAINT transaction_copy_height_fkey FOREIGN KEY (height) REFERENCES public.block(height)
);
CREATE INDEX transaction_copy_hash_index ON public.transaction_copy USING btree (hash);
CREATE INDEX transaction_copy_height_index ON public.transaction_copy USING btree (height);
CREATE INDEX transaction_copy_partition_id_index ON public.transaction_copy USING btree (partition_id);


-- create trigger func
CREATE OR REPLACE FUNCTION public.transaction_copy_func()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.transaction_copy (
        hash, height, success, messages, memo, signatures,
        signer_infos, fee, gas_wanted, gas_used, raw_log,
        logs, partition_id
    ) VALUES (
        NEW.hash, NEW.height, NEW.success, NEW.messages, NEW.memo, NEW.signatures,
        NEW.signer_infos, NEW.fee, NEW.gas_wanted, NEW.gas_used, NEW.raw_log,
        NEW.logs, NEW.partition_id
    )
    ON CONFLICT (hash, partition_id) 
    DO UPDATE SET
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
    
    RETURN NEW;
END;
$$;


-- create trigger
DROP TRIGGER IF EXISTS transaction_copy_trigger ON public."transaction";
CREATE TRIGGER transaction_copy_trigger
AFTER INSERT ON public."transaction"
FOR EACH ROW
EXECUTE FUNCTION public.transaction_copy_func();


-- create table
DROP TABLE IF EXISTS public.message_copy;
CREATE TABLE IF NOT EXISTS public.message_copy (
    transaction_hash text NOT NULL,
    "index" int8 NOT NULL,
    "type" text NOT NULL,
    value json NOT NULL,
    involved_accounts_addresses _text NOT NULL,
    partition_id int8 DEFAULT 0 NOT NULL,
    height int8 NOT NULL,
    CONSTRAINT message_copy_unique_message_per_tx UNIQUE (transaction_hash, "index", partition_id),
    CONSTRAINT message_copy_transaction_hash_fkey FOREIGN KEY (transaction_hash, partition_id) 
        REFERENCES public."transaction"(hash, partition_id),
    CONSTRAINT message_copy_type_fkey FOREIGN KEY ("type") 
        REFERENCES public.message_type("type")
);
CREATE INDEX message_copy_involved_accounts_index ON public.message_copy USING gin (involved_accounts_addresses);
CREATE INDEX message_copy_transaction_hash_index ON public.message_copy USING btree (transaction_hash);
CREATE INDEX message_copy_type_index ON public.message_copy USING btree (type);
CREATE INDEX message_copy_partition_id_index ON public.message_copy USING btree (partition_id);
CREATE INDEX message_copy_height_index ON public.message_copy USING btree (height);


-- create trigger func
CREATE OR REPLACE FUNCTION public.message_copy_func()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.message_copy (
        transaction_hash, "index", "type", value,
        involved_accounts_addresses, partition_id, height
    ) VALUES (
        NEW.transaction_hash, NEW."index", NEW."type", NEW.value,
        NEW.involved_accounts_addresses, NEW.partition_id, NEW.height
    )
    ON CONFLICT (transaction_hash, "index", partition_id) 
    DO UPDATE SET
        "type" = EXCLUDED."type",
        value = EXCLUDED.value,
        involved_accounts_addresses = EXCLUDED.involved_accounts_addresses,
        height = EXCLUDED.height;
    
    RETURN NEW;
END;
$$;


-- create trigger
DROP TRIGGER IF EXISTS message_copy_trigger ON public.message;
CREATE TRIGGER message_copy_trigger
AFTER INSERT ON public.message
FOR EACH ROW
EXECUTE FUNCTION public.message_copy_func();


-- create table
DROP TABLE IF EXISTS public.fee_records_copy;
CREATE TABLE IF NOT EXISTS public.fee_records_copy (
    id bigserial NOT NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    deleted_at timestamptz NULL,
    height int8 NOT NULL,
    tx_hash text NOT NULL,
    fee_payer text NULL,
    fee_amount int8 NULL,
    fee_denom text NULL,
    invoke_address _text NULL,
    receivers public."_fee_received" NULL,
    partition_id int8 DEFAULT 0 NOT NULL,
    CONSTRAINT fee_records_copy_pkey PRIMARY KEY (tx_hash, height),
    CONSTRAINT fee_records_copy_transaction_fkey FOREIGN KEY (tx_hash, partition_id) 
        REFERENCES public."transaction"(hash, partition_id)
);
CREATE INDEX idx_fee_records_copy_deleted_at ON public.fee_records_copy USING btree (deleted_at);
CREATE INDEX idx_fee_records_copy_height ON public.fee_records_copy USING btree (height);
CREATE INDEX idx_fee_records_copy_invoke_address_gin ON public.fee_records_copy USING gin (invoke_address);
CREATE INDEX idx_fee_records_copy_tx_hash ON public.fee_records_copy USING btree (tx_hash);
CREATE INDEX idx_fee_records_copy_partition_id ON public.fee_records_copy USING btree (partition_id);


-- create trigger func
CREATE OR REPLACE FUNCTION public.fee_records_copy_func()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.fee_records_copy (
        id, created_at, updated_at, deleted_at,
        height, tx_hash, fee_payer, fee_amount,
        fee_denom, invoke_address, receivers,
        partition_id
    ) VALUES (
        NEW.id, NEW.created_at, NEW.updated_at, NEW.deleted_at,
        NEW.height, NEW.tx_hash, NEW.fee_payer, NEW.fee_amount,
        NEW.fee_denom, NEW.invoke_address, NEW.receivers,
        NEW.partition_id
    )
    ON CONFLICT (tx_hash, height) 
    DO UPDATE SET
        created_at = EXCLUDED.created_at,
        updated_at = EXCLUDED.updated_at,
        deleted_at = EXCLUDED.deleted_at,
        fee_payer = EXCLUDED.fee_payer,
        fee_amount = EXCLUDED.fee_amount,
        fee_denom = EXCLUDED.fee_denom,
        invoke_address = EXCLUDED.invoke_address,
        receivers = EXCLUDED.receivers,
        partition_id = EXCLUDED.partition_id;
    
    RETURN NEW;
END;
$$;


-- create trigger
DROP TRIGGER IF EXISTS fee_records_copy_trigger ON public.fee_records;
CREATE TRIGGER fee_records_copy_trigger
AFTER INSERT ON public.fee_records
FOR EACH ROW
EXECUTE FUNCTION public.fee_records_copy_func();




