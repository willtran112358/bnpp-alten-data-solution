-- =============================================================================
-- Satellite loader: SAT_CAMPAIGN_METRICS (hashdiff incremental)
-- Grain: link_hk + metric_date; new version only when hashdiff changes
-- =============================================================================

CREATE OR REPLACE PACKAGE rv.pkg_load_sat_campaign_metrics AS
    PROCEDURE load_from_psa(p_batch_id IN VARCHAR2);
END pkg_load_sat_campaign_metrics;
/

CREATE OR REPLACE PACKAGE BODY rv.pkg_load_sat_campaign_metrics AS

    FUNCTION fn_hk_campaign(p_bk IN VARCHAR2, p_rs IN VARCHAR2) RETURN RAW IS
    BEGIN
        RETURN STANDARD_HASH(UPPER(TRIM(p_bk)) || '|' || UPPER(TRIM(p_rs)), 'SHA256');
    END;

    FUNCTION fn_hk_channel(p_code IN VARCHAR2, p_rs IN VARCHAR2) RETURN RAW IS
    BEGIN
        RETURN STANDARD_HASH(UPPER(TRIM(p_code)) || '|' || UPPER(TRIM(p_rs)), 'SHA256');
    END;

    FUNCTION fn_hk_subsidiary(p_code IN VARCHAR2, p_rs IN VARCHAR2) RETURN RAW IS
    BEGIN
        RETURN STANDARD_HASH(UPPER(TRIM(p_code)) || '|' || UPPER(TRIM(p_rs)), 'SHA256');
    END;

    FUNCTION fn_link_hk(
        p_campaign_hk   RAW,
        p_channel_hk    RAW,
        p_subsidiary_hk RAW
    ) RETURN RAW IS
    BEGIN
        RETURN STANDARD_HASH(
            RAWTOHEX(p_campaign_hk) || '|' ||
            RAWTOHEX(p_channel_hk)  || '|' ||
            RAWTOHEX(p_subsidiary_hk),
            'SHA256'
        );
    END;

    FUNCTION fn_hashdiff(
        p_impressions NUMBER,
        p_clicks      NUMBER,
        p_spend_eur   NUMBER
    ) RETURN RAW IS
        l_cpc NUMBER;
    BEGIN
        l_cpc := CASE WHEN NVL(p_clicks, 0) = 0 THEN NULL
                      ELSE ROUND(p_spend_eur / p_clicks, 6) END;
        RETURN STANDARD_HASH(
            NVL(TO_CHAR(p_impressions), '?') || '|' ||
            NVL(TO_CHAR(p_clicks), '?')      || '|' ||
            NVL(TO_CHAR(p_spend_eur), '?')   || '|' ||
            NVL(TO_CHAR(l_cpc), '?'),
            'SHA256'
        );
    END;

    PROCEDURE load_from_psa(p_batch_id IN VARCHAR2) IS
        l_started  TIMESTAMP := SYSTIMESTAMP;
        l_rows_out NUMBER := 0;
    BEGIN
        -- Ensure link rows exist (idempotent insert)
        INSERT INTO rv.link_campaign_channel (
            link_hk, campaign_hk, channel_hk, subsidiary_hk, load_dts, record_source
        )
        SELECT
            fn_link_hk(
                fn_hk_campaign(s.campaign_bk, s.record_source),
                fn_hk_channel(s.channel_code, s.record_source),
                fn_hk_subsidiary(s.subsidiary_code, s.record_source)
            ),
            fn_hk_campaign(s.campaign_bk, s.record_source),
            fn_hk_channel(s.channel_code, s.record_source),
            fn_hk_subsidiary(s.subsidiary_code, s.record_source),
            MIN(s.load_dts),
            MIN(s.record_source)
        FROM psa.psa_ads_campaign_daily s
        WHERE s.batch_id = p_batch_id
          AND NOT EXISTS (
                SELECT 1 FROM rv.link_campaign_channel l
                WHERE l.link_hk = fn_link_hk(
                    fn_hk_campaign(s.campaign_bk, s.record_source),
                    fn_hk_channel(s.channel_code, s.record_source),
                    fn_hk_subsidiary(s.subsidiary_code, s.record_source)
                )
            )
        GROUP BY
            fn_hk_campaign(s.campaign_bk, s.record_source),
            fn_hk_channel(s.channel_code, s.record_source),
            fn_hk_subsidiary(s.subsidiary_code, s.record_source);

        INSERT INTO rv.sat_campaign_metrics (
            link_hk, load_dts, metric_date, hashdiff, record_source,
            impressions, clicks, spend_eur, cpc
        )
        SELECT
            fn_link_hk(
                fn_hk_campaign(s.campaign_bk, s.record_source),
                fn_hk_channel(s.channel_code, s.record_source),
                fn_hk_subsidiary(s.subsidiary_code, s.record_source)
            ) AS link_hk,
            s.load_dts,
            s.metric_date,
            fn_hashdiff(s.impressions, s.clicks, s.spend_eur) AS hashdiff,
            s.record_source,
            s.impressions,
            s.clicks,
            s.spend_eur,
            CASE WHEN NVL(s.clicks, 0) = 0 THEN NULL
                 ELSE ROUND(s.spend_eur / s.clicks, 6) END AS cpc
        FROM psa.psa_ads_campaign_daily s
        WHERE s.batch_id = p_batch_id
          AND NOT EXISTS (
                SELECT 1
                FROM rv.sat_campaign_metrics cur
                WHERE cur.link_hk = fn_link_hk(
                          fn_hk_campaign(s.campaign_bk, s.record_source),
                          fn_hk_channel(s.channel_code, s.record_source),
                          fn_hk_subsidiary(s.subsidiary_code, s.record_source)
                      )
                  AND cur.metric_date = s.metric_date
                  AND cur.load_dts = (
                        SELECT MAX(x.load_dts)
                        FROM rv.sat_campaign_metrics x
                        WHERE x.link_hk = cur.link_hk
                          AND x.metric_date = cur.metric_date
                      )
                  AND cur.hashdiff = fn_hashdiff(s.impressions, s.clicks, s.spend_eur)
            );

        l_rows_out := SQL%ROWCOUNT;

        INSERT INTO aud.batch_run (
            batch_id, process_name, started_at, finished_at,
            status, rows_in, rows_out, message
        ) VALUES (
            p_batch_id, 'LOAD_SAT_CAMPAIGN_METRICS', l_started, SYSTIMESTAMP,
            'SUCCESS', NULL, l_rows_out, 'Incremental satellite versions inserted'
        );
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            INSERT INTO aud.batch_run (
                batch_id, process_name, started_at, finished_at,
                status, rows_in, rows_out, message
            ) VALUES (
                p_batch_id, 'LOAD_SAT_CAMPAIGN_METRICS', l_started, SYSTIMESTAMP,
                'FAILED', NULL, 0, SUBSTR(SQLERRM, 1, 4000)
            );
            COMMIT;
            RAISE;
    END load_from_psa;

END pkg_load_sat_campaign_metrics;
/
