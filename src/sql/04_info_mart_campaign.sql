-- =============================================================================
-- Information mart: unified campaign performance (current satellite version)
-- Consumed by Power BI / Oracle APEX
-- =============================================================================

CREATE OR REPLACE VIEW im.v_campaign_performance_daily AS
SELECT
    sub.legal_entity_code                          AS subsidiary_code,
    ch.channel_code                                AS channel_code,
    camp.campaign_bk                               AS campaign_id,
    attr.campaign_name,
    attr.campaign_status,
    attr.objective,
    m.metric_date,
    m.impressions,
    m.clicks,
    m.spend_eur,
    m.cpc,
    CASE WHEN NVL(m.impressions, 0) = 0 THEN NULL
         ELSE ROUND(m.clicks / m.impressions, 6) END AS ctr,
    m.record_source,
    m.load_dts                                     AS metrics_load_dts
FROM rv.sat_campaign_metrics m
JOIN rv.link_campaign_channel l
  ON l.link_hk = m.link_hk
JOIN rv.hub_campaign camp
  ON camp.campaign_hk = l.campaign_hk
JOIN rv.hub_channel ch
  ON ch.channel_hk = l.channel_hk
JOIN rv.hub_subsidiary sub
  ON sub.subsidiary_hk = l.subsidiary_hk
LEFT JOIN rv.sat_campaign_attr attr
  ON attr.campaign_hk = camp.campaign_hk
 AND attr.load_dts = (
        SELECT MAX(a2.load_dts)
        FROM rv.sat_campaign_attr a2
        WHERE a2.campaign_hk = camp.campaign_hk
     )
WHERE m.load_dts = (
        SELECT MAX(m2.load_dts)
        FROM rv.sat_campaign_metrics m2
        WHERE m2.link_hk = m.link_hk
          AND m2.metric_date = m.metric_date
      );

-- Group-level rollup for campaign managers (SSOT)
CREATE OR REPLACE VIEW im.v_channel_profitability_mtd AS
SELECT
    subsidiary_code,
    channel_code,
    TRUNC(metric_date, 'MM') AS month_start,
    SUM(impressions)         AS impressions,
    SUM(clicks)              AS clicks,
    SUM(spend_eur)           AS spend_eur,
    CASE WHEN SUM(clicks) = 0 THEN NULL
         ELSE ROUND(SUM(spend_eur) / SUM(clicks), 6) END AS cpc,
    CASE WHEN SUM(impressions) = 0 THEN NULL
         ELSE ROUND(SUM(clicks) / SUM(impressions), 6) END AS ctr
FROM im.v_campaign_performance_daily
GROUP BY
    subsidiary_code,
    channel_code,
    TRUNC(metric_date, 'MM');
