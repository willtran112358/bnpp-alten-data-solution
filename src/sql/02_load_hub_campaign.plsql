-- =============================================================================
-- Hub loader: HUB_CAMPAIGN (Oracle PL/SQL)
-- Inserts only new business keys. Hash key = SHA256(UPPER(TRIM(BK)) || '|' || RS)
-- =============================================================================

CREATE OR REPLACE PACKAGE rv.pkg_load_hub_campaign AS
    PROCEDURE load_from_psa(p_batch_id IN VARCHAR2);
END pkg_load_hub_campaign;
/

CREATE OR REPLACE PACKAGE BODY rv.pkg_load_hub_campaign AS

    FUNCTION fn_campaign_hk(
        p_campaign_bk   IN VARCHAR2,
        p_record_source IN VARCHAR2
    ) RETURN RAW IS
    BEGIN
        RETURN STANDARD_HASH(
            UPPER(TRIM(p_campaign_bk)) || '|' || UPPER(TRIM(p_record_source)),
            'SHA256'
        );
    END fn_campaign_hk;

    PROCEDURE load_from_psa(p_batch_id IN VARCHAR2) IS
        l_started   TIMESTAMP := SYSTIMESTAMP;
        l_rows_out  NUMBER := 0;
    BEGIN
        INSERT INTO rv.hub_campaign (
            campaign_hk,
            campaign_bk,
            load_dts,
            record_source
        )
        SELECT
            fn_campaign_hk(s.campaign_bk, s.record_source) AS campaign_hk,
            UPPER(TRIM(s.campaign_bk))                     AS campaign_bk,
            MIN(s.load_dts)                                AS load_dts,
            MIN(s.record_source)                           AS record_source
        FROM psa.psa_ads_campaign_daily s
        WHERE s.batch_id = p_batch_id
          AND NOT EXISTS (
                SELECT 1
                FROM rv.hub_campaign h
                WHERE h.campaign_hk = fn_campaign_hk(s.campaign_bk, s.record_source)
            )
        GROUP BY
            fn_campaign_hk(s.campaign_bk, s.record_source),
            UPPER(TRIM(s.campaign_bk));

        l_rows_out := SQL%ROWCOUNT;

        INSERT INTO aud.batch_run (
            batch_id, process_name, started_at, finished_at,
            status, rows_in, rows_out, message
        ) VALUES (
            p_batch_id,
            'LOAD_HUB_CAMPAIGN',
            l_started,
            SYSTIMESTAMP,
            'SUCCESS',
            NULL,
            l_rows_out,
            'New campaign hubs inserted'
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            INSERT INTO aud.batch_run (
                batch_id, process_name, started_at, finished_at,
                status, rows_in, rows_out, message
            ) VALUES (
                p_batch_id,
                'LOAD_HUB_CAMPAIGN',
                l_started,
                SYSTIMESTAMP,
                'FAILED',
                NULL,
                0,
                SUBSTR(SQLERRM, 1, 4000)
            );
            COMMIT;
            RAISE;
    END load_from_psa;

END pkg_load_hub_campaign;
/
