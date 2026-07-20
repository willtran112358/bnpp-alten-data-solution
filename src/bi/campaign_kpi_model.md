# Campaign KPI semantic model (Power BI / Oracle APEX)

Illustrative star shape over `IM` views — keeps BI simple while history lives in DV2.0.

## Tables / views

| Object | Role | Grain |
|--------|------|-------|
| `im.v_campaign_performance_daily` | Fact-like wide table | subsidiary × channel × campaign × date |
| `im.v_channel_profitability_mtd` | Aggregate | subsidiary × channel × month |

## Measures

| Measure | Expression (conceptual) | Use |
|---------|-------------------------|-----|
| Impressions | `SUM(impressions)` | Reach |
| Clicks | `SUM(clicks)` | Engagement |
| Spend EUR | `SUM(spend_eur)` | Cost |
| CPC | `Spend / Clicks` | Efficiency |
| CTR | `Clicks / Impressions` | Creative quality |
| Channel ROI proxy | `(attributed_revenue - spend) / spend` | Needs finance feed (phase 2) |

## Slicers / dimensions

- Subsidiary (`legal_entity_code`)
- Channel (`GOOGLE_ADS`, `META_ADS`, …)
- Campaign status / objective
- Date hierarchy (day → month → quarter)

## APEX ops page (suggested)

1. Batch run status from `aud.batch_run`
2. DQ traffic lights from `aud.dq_result`
3. Drill to failed `check_id` + quarantine counts

```mermaid
flowchart LR
    classDef im fill:#E0F7FA,stroke:#00838F,stroke-width:2px,color:#006064
    classDef bi fill:#E8F5E9,stroke:#2E7D32,stroke-width:2px,color:#1B5E20
    classDef ops fill:#FFF3E0,stroke:#EF6C00,stroke-width:2px,color:#E65100

    V1["v_campaign_performance_daily"]:::im
    V2["v_channel_profitability_mtd"]:::im
    PBI["Power BI<br/>Campaign SSOT"]:::bi
    APEX["Oracle APEX<br/>Ops + DQ"]:::ops
    AUD["aud.batch_run<br/>aud.dq_result"]:::ops

    V1 --> PBI
    V2 --> PBI
    AUD --> APEX
```

## Row-level security (conceptual)

Map Power BI / APEX roles to `subsidiary_code` so local campaign managers only see their legal entity, while group marketing sees all.
