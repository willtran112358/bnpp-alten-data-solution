# Data Vault vs Kimball (star schema) in banking

In banking EDW they usually **both** exist — **different jobs**. You do not pick one instead of the other: **vault feeds the stars**.

## Side-by-side

| | **Hubs / Links / Sats (Data Vault)** | **Star schema (Kimball)** |
|---|--------------------------------------|---------------------------|
| **Job** | Integrate & historize many sources | Report KPIs fast |
| **Audience** | Data engineers, audit, risk IT | Analysts, risk / finance BI |
| **Change** | Add sat / source without redesigning marts | Change dims / facts when report grain changes |
| **History** | Full source-aware versions (`load_dts`, `record_source`) | Often SCD Type 2 on dims only |
| **Example** | `HUB_CUSTOMER` + `LINK_CUSTOMER_ACCOUNT` + sats from core, CRM, AML | `Fact_Transaction` + `Dim_Customer` + `Dim_Account` + `Dim_Date` |

## Flow in a bank EDW

```mermaid
flowchart LR
    classDef src fill:#FFCDD2,stroke:#C62828,stroke-width:2px,color:#B71C1C
    classDef dv fill:#BBDEFB,stroke:#1565C0,stroke-width:2px,color:#0D47A1
    classDef star fill:#C8E6C9,stroke:#2E7D32,stroke-width:2px,color:#1B5E20
    classDef biz fill:#FFE0B2,stroke:#EF6C00,stroke-width:2px,color:#E65100

    CORE["Core banking"]:::src
    CRM["CRM / AML / Cards"]:::src
    DV["DV: Hub / Link / Sat<br/>audit · lineage · multi-source"]:::dv
    STAR["Star: Fact + Dims<br/>dashboards · regulatory packs"]:::star
    BI["Risk · Finance · GM BI"]:::biz

    CORE --> DV
    CRM --> DV
    DV --> STAR --> BI
```

## Banking rule of thumb

| Pattern | One-liner |
|---------|-----------|
| **DV** | System of **integration / history** — *what did we know, from which source, when?* |
| **Star** | System of **consumption** — *NPL, balances, campaign CPC by day* |

```text
DV    = HOW you model integrated history (hubs / links / sats)
Star  = HOW you present metrics for BI (facts / dims)
```

## DV core logic (quick)

```mermaid
flowchart LR
    classDef h fill:#BBDEFB,stroke:#1565C0,stroke-width:2px,color:#0D47A1
    classDef l fill:#FFE0B2,stroke:#EF6C00,stroke-width:2px,color:#E65100
    classDef s fill:#C8E6C9,stroke:#2E7D32,stroke-width:2px,color:#1B5E20

    H["HUB<br/>who / what<br/>business key only"]:::h
    L["LINK<br/>how they relate"]:::l
    S["SAT<br/>attributes over time"]:::s

    H --- L
    L --- S
    H --- S
```

```text
HUB  = unique business key            (Customer, Campaign)
LINK = relationship between hubs      (Customer–Account)
SAT  = descriptive history on hub/link (name, status, metrics)

Keys & relationships stay stable;
changing attributes version in satellites with load_dts + record_source.
```

## DV 1.0 vs DV 2.0 — sample ER (same banking grain)

Same pattern (Customer–Account). Difference is **how keys & change detection work**.

| | **DV 1.0** | **DV 2.0** |
|---|------------|------------|
| Hub / link PK | Sequence / surrogate (`*_SQN`) | **Hash key** (`*_HK`) from business key |
| Satellite change | Column compare (or optional checksum) | **`HASHDIFF`** |
| Loads | Often more sequential | Built for **parallel** loads |

### Data Vault 1.0 (sequence keys)

```mermaid
erDiagram
    HUB_CUSTOMER ||--o{ LINK_CUSTOMER_ACCOUNT : "owns"
    HUB_ACCOUNT ||--o{ LINK_CUSTOMER_ACCOUNT : "owned_by"
    HUB_CUSTOMER ||--o{ SAT_CUSTOMER_ATTR : "history"
    LINK_CUSTOMER_ACCOUNT ||--o{ SAT_ACCOUNT_BALANCE : "history"

    HUB_CUSTOMER {
        number customer_sqn PK "sequence"
        string customer_bk
        timestamp load_dts
        string record_source
    }
    HUB_ACCOUNT {
        number account_sqn PK "sequence"
        string account_bk
        timestamp load_dts
        string record_source
    }
    LINK_CUSTOMER_ACCOUNT {
        number link_sqn PK "sequence"
        number customer_sqn FK
        number account_sqn FK
        timestamp load_dts
        string record_source
    }
    SAT_CUSTOMER_ATTR {
        number customer_sqn PK_FK
        timestamp load_dts PK
        string name
        string status
        string record_source
    }
    SAT_ACCOUNT_BALANCE {
        number link_sqn PK_FK
        timestamp load_dts PK
        number balance
        string currency
        string record_source
    }
```

### Data Vault 2.0 (hash keys + hashdiff)

```mermaid
erDiagram
    HUB_CUSTOMER ||--o{ LINK_CUSTOMER_ACCOUNT : "owns"
    HUB_ACCOUNT ||--o{ LINK_CUSTOMER_ACCOUNT : "owned_by"
    HUB_CUSTOMER ||--o{ SAT_CUSTOMER_ATTR : "history"
    LINK_CUSTOMER_ACCOUNT ||--o{ SAT_ACCOUNT_BALANCE : "history"

    HUB_CUSTOMER {
        raw customer_hk PK "SHA256 of BK"
        string customer_bk
        timestamp load_dts
        string record_source
    }
    HUB_ACCOUNT {
        raw account_hk PK "SHA256 of BK"
        string account_bk
        timestamp load_dts
        string record_source
    }
    LINK_CUSTOMER_ACCOUNT {
        raw link_hk PK "SHA256 of child HKs"
        raw customer_hk FK
        raw account_hk FK
        timestamp load_dts
        string record_source
    }
    SAT_CUSTOMER_ATTR {
        raw customer_hk PK_FK
        timestamp load_dts PK
        raw hashdiff "change detect"
        string name
        string status
        string record_source
    }
    SAT_ACCOUNT_BALANCE {
        raw link_hk PK_FK
        timestamp load_dts PK
        raw hashdiff "change detect"
        number balance
        string currency
        string record_source
    }
```

```text
DV1: insert hub → get next SQN → use SQN in links/sats
DV2: compute HK/HASHDIFF in parallel → insert if new / changed
```

This repo’s Oracle samples follow **DV 2.0** (`*_HK`, `HASHDIFF`) — see [`src/sql/01_dv2_ddl_ads.sql`](../src/sql/01_dv2_ddl_ads.sql).

## How this maps in this repo

| Layer in solution | Pattern |
|-------------------|---------|
| PSA / Landing | Source-shaped staging |
| `RV` hubs / links / sats | **Data Vault** (integration) |
| `IM` views / campaign marts | **Kimball-style** consumption (wide KPI / star-ready) |
| Power BI / APEX | BI on top of stars / marts |

See also: [Solution design](02-solution-design.md) · sample mart [`src/sql/04_info_mart_campaign.sql`](../src/sql/04_info_mart_campaign.sql)
