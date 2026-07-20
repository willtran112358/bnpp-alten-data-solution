-- =============================================================================
-- Data quality checks — freshness, orphans, reconciliation
-- =============================================================================

-- DQ-01: Staging freshness (fail if latest PSA load older than 4 hours)
INSERT INTO aud.dq_result (
    check_id, batch_id, checked_at, severity, passed, metric_value, threshold_value, details
)
SELECT
    'DQ_ADS_FRESHNESS_4H',
    :batch_id,
    SYSTIMESTAMP,
    'CRITICAL',
    CASE WHEN hours_lag <= 4 THEN 'Y' ELSE 'N' END,
    hours_lag,
    4,
    'Hours since latest PSA load_dts'
FROM (
    SELECT (SYSTIMESTAMP - MAX(load_dts)) * 24 AS hours_lag
    FROM psa.psa_ads_campaign_daily
    WHERE batch_id = :batch_id
);

-- DQ-02: Orphan links (link HK without hub parents) — should be 0
INSERT INTO aud.dq_result (
    check_id, batch_id, checked_at, severity, passed, metric_value, threshold_value, details
)
SELECT
    'DQ_ORPHAN_LINK_CAMPAIGN',
    :batch_id,
    SYSTIMESTAMP,
    'CRITICAL',
    CASE WHEN cnt = 0 THEN 'Y' ELSE 'N' END,
    cnt,
    0,
    'Links missing hub parents'
FROM (
    SELECT COUNT(*) AS cnt
    FROM rv.link_campaign_channel l
    WHERE NOT EXISTS (SELECT 1 FROM rv.hub_campaign c WHERE c.campaign_hk = l.campaign_hk)
       OR NOT EXISTS (SELECT 1 FROM rv.hub_channel ch WHERE ch.channel_hk = l.channel_hk)
       OR NOT EXISTS (SELECT 1 FROM rv.hub_subsidiary s WHERE s.subsidiary_hk = l.subsidiary_hk)
);

-- DQ-03: PSA vs mart spend reconciliation (tolerance 0.01 EUR)
INSERT INTO aud.dq_result (
    check_id, batch_id, checked_at, severity, passed, metric_value, threshold_value, details
)
SELECT
    'DQ_RECON_SPEND_EUR',
    :batch_id,
    SYSTIMESTAMP,
    'HIGH',
    CASE WHEN ABS(NVL(psa_spend, 0) - NVL(mart_spend, 0)) <= 0.01 THEN 'Y' ELSE 'N' END,
    ABS(NVL(psa_spend, 0) - NVL(mart_spend, 0)),
    0.01,
    'Absolute difference PSA vs IM spend_eur for batch metric dates'
FROM (
    SELECT
        (SELECT SUM(spend_eur) FROM psa.psa_ads_campaign_daily WHERE batch_id = :batch_id) AS psa_spend,
        (SELECT SUM(m.spend_eur)
         FROM rv.sat_campaign_metrics m
         WHERE m.record_source IN (
             SELECT DISTINCT record_source FROM psa.psa_ads_campaign_daily WHERE batch_id = :batch_id
         )
           AND m.metric_date IN (
             SELECT DISTINCT metric_date FROM psa.psa_ads_campaign_daily WHERE batch_id = :batch_id
         )
        ) AS mart_spend
    FROM dual
);

-- Gate helper: block mart publish if any CRITICAL failed for batch
-- SELECT CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS dq_gate
-- FROM aud.dq_result
-- WHERE batch_id = :batch_id AND severity = 'CRITICAL' AND passed = 'N';
