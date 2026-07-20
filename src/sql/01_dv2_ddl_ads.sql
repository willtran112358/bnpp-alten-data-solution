-- =============================================================================
-- BNP Paribas portfolio sample — Data Vault 2.0 DDL (Advertising domain)
-- Oracle 19c+ illustrative schema. NOT production BNPP code.
-- =============================================================================

CREATE USER rv IDENTIFIED BY "ChangeMe_RV" QUOTA UNLIMITED ON users;
CREATE USER psa IDENTIFIED BY "ChangeMe_PSA" QUOTA UNLIMITED ON users;
CREATE USER im IDENTIFIED BY "ChangeMe_IM" QUOTA UNLIMITED ON users;
CREATE USER aud IDENTIFIED BY "ChangeMe_AUD" QUOTA UNLIMITED ON users;

-- ---------------------------------------------------------------------------
-- PSA: flattened Google Ads style campaign daily metrics
-- ---------------------------------------------------------------------------
CREATE TABLE psa.psa_ads_campaign_daily (
    batch_id            VARCHAR2(64)   NOT NULL,
    load_dts            TIMESTAMP      NOT NULL,
    record_source       VARCHAR2(64)   NOT NULL,
    subsidiary_code     VARCHAR2(32)   NOT NULL,
    channel_code        VARCHAR2(32)   NOT NULL,
    campaign_bk         VARCHAR2(128)  NOT NULL,
    campaign_name       VARCHAR2(512),
    campaign_status     VARCHAR2(64),
    objective           VARCHAR2(128),
    metric_date         DATE           NOT NULL,
    impressions         NUMBER(18,0),
    clicks              NUMBER(18,0),
    spend_eur           NUMBER(18,4),
    extract_watermark   TIMESTAMP
);

CREATE INDEX ix_psa_ads_bk ON psa.psa_ads_campaign_daily (campaign_bk, metric_date, batch_id);

-- ---------------------------------------------------------------------------
-- Hubs
-- ---------------------------------------------------------------------------
CREATE TABLE rv.hub_campaign (
    campaign_hk     RAW(32)        NOT NULL,
    campaign_bk     VARCHAR2(128)  NOT NULL,
    load_dts        TIMESTAMP      NOT NULL,
    record_source   VARCHAR2(64)   NOT NULL,
    CONSTRAINT pk_hub_campaign PRIMARY KEY (campaign_hk)
);

CREATE UNIQUE INDEX ux_hub_campaign_bk ON rv.hub_campaign (campaign_bk);

CREATE TABLE rv.hub_channel (
    channel_hk      RAW(32)       NOT NULL,
    channel_code    VARCHAR2(32)  NOT NULL,
    load_dts        TIMESTAMP     NOT NULL,
    record_source   VARCHAR2(64)  NOT NULL,
    CONSTRAINT pk_hub_channel PRIMARY KEY (channel_hk)
);

CREATE UNIQUE INDEX ux_hub_channel_bk ON rv.hub_channel (channel_code);

CREATE TABLE rv.hub_subsidiary (
    subsidiary_hk       RAW(32)       NOT NULL,
    legal_entity_code   VARCHAR2(32)  NOT NULL,
    load_dts            TIMESTAMP     NOT NULL,
    record_source       VARCHAR2(64)  NOT NULL,
    CONSTRAINT pk_hub_subsidiary PRIMARY KEY (subsidiary_hk)
);

CREATE UNIQUE INDEX ux_hub_subsidiary_bk ON rv.hub_subsidiary (legal_entity_code);

-- ---------------------------------------------------------------------------
-- Link: campaign runs on channel owned by subsidiary
-- ---------------------------------------------------------------------------
CREATE TABLE rv.link_campaign_channel (
    link_hk         RAW(32)       NOT NULL,
    campaign_hk     RAW(32)       NOT NULL,
    channel_hk      RAW(32)       NOT NULL,
    subsidiary_hk   RAW(32)       NOT NULL,
    load_dts        TIMESTAMP     NOT NULL,
    record_source   VARCHAR2(64)  NOT NULL,
    CONSTRAINT pk_link_campaign_channel PRIMARY KEY (link_hk),
    CONSTRAINT fk_lcc_campaign   FOREIGN KEY (campaign_hk)   REFERENCES rv.hub_campaign (campaign_hk),
    CONSTRAINT fk_lcc_channel    FOREIGN KEY (channel_hk)    REFERENCES rv.hub_channel (channel_hk),
    CONSTRAINT fk_lcc_subsidiary FOREIGN KEY (subsidiary_hk) REFERENCES rv.hub_subsidiary (subsidiary_hk)
);

CREATE UNIQUE INDEX ux_lcc_natural ON rv.link_campaign_channel (campaign_hk, channel_hk, subsidiary_hk);

-- ---------------------------------------------------------------------------
-- Satellites
-- ---------------------------------------------------------------------------
CREATE TABLE rv.sat_campaign_attr (
    campaign_hk     RAW(32)        NOT NULL,
    load_dts        TIMESTAMP      NOT NULL,
    hashdiff        RAW(32)        NOT NULL,
    record_source   VARCHAR2(64)   NOT NULL,
    campaign_name   VARCHAR2(512),
    campaign_status VARCHAR2(64),
    objective       VARCHAR2(128),
    CONSTRAINT pk_sat_campaign_attr PRIMARY KEY (campaign_hk, load_dts),
    CONSTRAINT fk_sca_hub FOREIGN KEY (campaign_hk) REFERENCES rv.hub_campaign (campaign_hk)
);

CREATE TABLE rv.sat_campaign_metrics (
    link_hk         RAW(32)       NOT NULL,
    load_dts        TIMESTAMP     NOT NULL,
    metric_date     DATE          NOT NULL,
    hashdiff        RAW(32)       NOT NULL,
    record_source   VARCHAR2(64)  NOT NULL,
    impressions     NUMBER(18,0),
    clicks          NUMBER(18,0),
    spend_eur       NUMBER(18,4),
    cpc             NUMBER(18,6),
    CONSTRAINT pk_sat_campaign_metrics PRIMARY KEY (link_hk, metric_date, load_dts),
    CONSTRAINT fk_scm_link FOREIGN KEY (link_hk) REFERENCES rv.link_campaign_channel (link_hk)
);

-- ---------------------------------------------------------------------------
-- Audit
-- ---------------------------------------------------------------------------
CREATE TABLE aud.batch_run (
    batch_id        VARCHAR2(64)  NOT NULL,
    process_name    VARCHAR2(128) NOT NULL,
    started_at      TIMESTAMP     NOT NULL,
    finished_at     TIMESTAMP,
    status          VARCHAR2(32),
    rows_in         NUMBER,
    rows_out        NUMBER,
    message         VARCHAR2(4000),
    CONSTRAINT pk_batch_run PRIMARY KEY (batch_id, process_name, started_at)
);

CREATE TABLE aud.dq_result (
    check_id        VARCHAR2(64)  NOT NULL,
    batch_id        VARCHAR2(64)  NOT NULL,
    checked_at      TIMESTAMP     NOT NULL,
    severity        VARCHAR2(16)  NOT NULL,
    passed          CHAR(1)       NOT NULL,
    metric_value    NUMBER,
    threshold_value NUMBER,
    details         VARCHAR2(4000),
    CONSTRAINT pk_dq_result PRIMARY KEY (check_id, batch_id, checked_at)
);
