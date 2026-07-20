# BNP Paribas — Data Development & Advanced Analytics

**Portfolio data solution** for **ALTEN Germany → BNP Paribas** engagement: **Data Development & Advanced Analytics (1 FTE)**. Aligns with BNPP **Finance & Banking** EDWH needs — **Data Vault 2.0**, **Oracle / PL-SQL**, BI — and public domain patterns from **CIB Global Markets** warehouses plus **group advertising analytics**.

| Meta | Value |
|------|-------|
| **Client** | BNP Paribas (via ALTEN Germany) |
| **Domain** | Finance & Banking · Risk · Marketing Analytics |
| **Core stack** | Oracle EDWH · Data Vault 2.0 · PL/SQL · BI (Power BI / APEX) |
| **Nice-to-have** | WhereScape / WhereScape 3D · Enterprise DWH · Risk / Insurance |
| **Working hours** | Max overlap with **08:00–17:00 CET** (= **13:00–22:00 VNT**) |
| **Target start** | **September 2026** |

> **Disclaimer:** Educational / interview portfolio case study. No confidential BNPP data, proprietary ALTEN deliverables, or production credentials. Patterns inferred from public JDs and LinkedIn role descriptions only.

---

## Table of contents

1. [Business](#1-business)
2. [Solution design](#2-solution-design)
3. [Sample engineering code](#3-sample-engineering-code)
4. [JD mapping & interview pitch](#4-jd-mapping--interview-pitch)
5. [Repo map](#5-repo-map)

**Concepts:** [Data Vault vs Kimball in banking](docs/03-dv-vs-kimball.md) — vault integrates/historize; stars consume KPIs (both coexist).

---

## 1. Business

### 1.1 Why BNPP needs this capability

BNP Paribas operates as a **global universal bank** (Retail, CIB, Investment Partners). Analytics demand spans:

| Value stream | Business need | Data symptom today (typical) |
|--------------|---------------|------------------------------|
| **CIB Global Markets** | Pre-/post-trading controls, market-abuse surveillance, regulatory extracts | Multi-protocol feeds (REST, SFTP, CFT, DB, encrypted files) into Oracle DWH |
| **Group Marketing / Ads** | Unified campaign performance across **20+ subsidiaries** | Siloed Google / Meta / LinkedIn / TikTok / Bing / Snap / Trade Desk extracts |
| **Risk & Compliance** | Fraud / abuse detection, operational controls | Late T+1 marts; weak lineage for audit |
| **Digital Data offering** | Database Factory + Analytics platforms (Oracle, Kafka, OpenSearch, Splunk) | Productized DB/analytics services on cloud + on-prem |

**Executive one-liner:**

> *Group and CIB need one governed Enterprise Data Warehouse pattern — Data Vault 2.0 raw vault for auditability, information marts for campaign & risk KPIs, Oracle/PL-SQL for bank-grade reliability — so campaign managers and risk officers share a single source of truth.*

### 1.2 Stakeholder landscape

```mermaid
flowchart TB
    classDef exec fill:#E8F5E9,stroke:#2E7D32,stroke-width:2px,color:#1B5E20
    classDef biz fill:#E3F2FD,stroke:#1565C0,stroke-width:2px,color:#0D47A1
    classDef risk fill:#FFF3E0,stroke:#EF6C00,stroke-width:2px,color:#E65100
    classDef tech fill:#F3E5F5,stroke:#7B1FA2,stroke-width:2px,color:#4A148C
    classDef partner fill:#FCE4EC,stroke:#C2185B,stroke-width:2px,color:#880E4F

    CDO["CDO / Data Management<br/>Head of Data"]:::exec
    MKT["Campaign Managers<br/>Group Marketing"]:::biz
    GM["CIB Global Markets<br/>Pre / Post Trading"]:::biz
    RISK["Risk · Fraud · Compliance"]:::risk
    PO["Digital Data PO<br/>Database Factory"]:::tech
    DBA["Oracle / Multi-DB Factory"]:::tech
    ALTEN["ALTEN DE<br/>Data Dev & Analytics"]:::partner
    DE["Data Developer<br/>DV2.0 · PL/SQL · BI"]:::partner

    CDO --> PO
    CDO --> RISK
    MKT --> PO
    GM --> PO
    RISK --> DE
    PO --> ALTEN
    ALTEN --> DE
    DBA --> DE
    DE --> MKT
    DE --> GM
```

### 1.3 Two flagship business domains (from public BNPP roles)

#### A) Unified Advertising Analytics (Group)

- Integrate **20+ media sources**: Google Ads, Meta, LinkedIn, TikTok, Bing, Snapchat, The Trade Desk, …
- Automate **reliable, standardized ingestion** across subsidiaries
- Deliver **unified dashboards**: impressions, CPC, channel profitability — **one SSOT** for campaign managers

```mermaid
flowchart LR
    classDef src fill:#FFEBEE,stroke:#C62828,stroke-width:2px,color:#B71C1C
    classDef pipe fill:#FFF8E1,stroke:#F9A825,stroke-width:2px,color:#F57F17
    classDef vault fill:#E8EAF6,stroke:#3949AB,stroke-width:2px,color:#1A237E
    classDef mart fill:#E0F7FA,stroke:#00838F,stroke-width:2px,color:#006064
    classDef bi fill:#E8F5E9,stroke:#43A047,stroke-width:2px,color:#1B5E20

    GADS["Google Ads"]:::src
    META["Meta Ads"]:::src
    LI["LinkedIn"]:::src
    TT["TikTok"]:::src
    OTH["Bing · Snap · TTD · …"]:::src

    ING["Ingestion Hub<br/>API · SFTP · Files"]:::pipe
    STG["Staging / PSA<br/>Oracle"]:::pipe
    RV["Raw Vault DV2.0<br/>Hubs · Links · Sats"]:::vault
    BV["Business Vault<br/>Rules · Soft biz"]:::vault
    IM["Info Marts<br/>Campaign KPIs"]:::mart
    DASH["Unified Dashboards<br/>Power BI / APEX"]:::bi

    GADS --> ING
    META --> ING
    LI --> ING
    TT --> ING
    OTH --> ING
    ING --> STG --> RV --> BV --> IM --> DASH
```

#### B) CIB Global Markets Pre-/Post-Trading DWH

Public role patterns (Pre-Trading / Post-Trading Data Warehouse):

| Capability | Typical work |
|------------|--------------|
| **ETL multi-protocol** | REST API, SFTP, CFT, Database, encrypted payloads → Oracle DWH |
| **Surveillance** | Market-abuse detection algorithms; high-volume performance tuning |
| **Ops tooling** | Dynatrace, Oracle APEX, OpenSearch for model/production monitoring |
| **Quality** | Non-regression + unit tests (Pytest / SQL); S3 artifacts for test data |
| **Regulatory BI** | APEX apps, Power BI, Kibana for GM activity & control indicators |

```mermaid
flowchart TB
    classDef feed fill:#FFCDD2,stroke:#D32F2F,stroke-width:2px,color:#B71C1C
    classDef mid fill:#FFE0B2,stroke:#F57C00,stroke-width:2px,color:#E65100
    classDef core fill:#C5CAE9,stroke:#303F9F,stroke-width:2px,color:#1A237E
    classDef out fill:#B2DFDB,stroke:#00796B,stroke-width:2px,color:#004D40

    subgraph Sources["Source systems"]
        API["REST APIs"]:::feed
        SFTP["SFTP / CFT"]:::feed
        DB["Trading DBs"]:::feed
        ENC["Encrypted files"]:::feed
    end

    subgraph Platform["GM Data Warehouse (Oracle)"]
        ETL["ETL / ELT<br/>PL/SQL · Python"]:::mid
        DV["Data Vault 2.0<br/>audit-friendly history"]:::core
        SURV["Abuse / Fraud<br/>detection models"]:::core
        CTRL["Control indicators<br/>& regulatory extracts"]:::mid
    end

    subgraph Consumers["Consumers"]
        APEX["Oracle APEX"]:::out
        PBI["Power BI"]:::out
        OS["OpenSearch / Kibana"]:::out
        MON["Dynatrace monitors"]:::out
    end

    API --> ETL
    SFTP --> ETL
    DB --> ETL
    ENC --> ETL
    ETL --> DV
    DV --> SURV
    DV --> CTRL
    SURV --> APEX
    CTRL --> PBI
    SURV --> OS
    ETL --> MON
```

### 1.4 Pain points → outcomes

| Pain | Business impact | Target outcome |
|------|-----------------|----------------|
| Fragmented media extracts per subsidiary | No group CPC / ROI view | Unified ads info mart + dashboard |
| Opaque lineage in classic 3NF DWH | Audit / model risk findings | DV2.0 hubs/links/sats + record source |
| Late batch only | Fraud & campaign lag | Incremental loads + SLA-backed freshness |
| Manual WhereScape-less DDL sprawl | Slow EDWH change | Optional WhereScape 3D automation |
| CET / APAC collaboration friction | Handoff gaps | Clear runbooks + CET-overlap windows |

Detail: [`docs/01-business.md`](docs/01-business.md)

---

## 2. Solution design

### 2.1 Target architecture (Oracle EDWH + Data Vault 2.0)

```mermaid
flowchart TB
    classDef src fill:#FFCDD2,stroke:#C62828,stroke-width:2px,color:#B71C1C
    classDef land fill:#FFE082,stroke:#FF8F00,stroke-width:2px,color:#E65100
    classDef raw fill:#9FA8DA,stroke:#3949AB,stroke-width:2px,color:#1A237E
    classDef biz fill:#CE93D8,stroke:#8E24AA,stroke-width:2px,color:#4A148C
    classDef info fill:#80CBC4,stroke:#00897B,stroke-width:2px,color:#004D40
    classDef cons fill:#A5D6A7,stroke:#43A047,stroke-width:2px,color:#1B5E20
    classDef gov fill:#B0BEC5,stroke:#546E7A,stroke-width:2px,color:#263238
    classDef tool fill:#F8BBD0,stroke:#AD1457,stroke-width:2px,color:#880E4F

    subgraph L0["L0 — Sources"]
        ADS["Media APIs<br/>20+ platforms"]:::src
        TRD["Trading / Post-trade<br/>systems"]:::src
        REF["Ref / Party / Org<br/>masters"]:::src
    end

    subgraph L1["L1 — Landing & PSA (Oracle)"]
        LD["Landing schema<br/>append-only files/API"]:::land
        PSA["Persistent Staging<br/>hash + load_dts"]:::land
    end

    subgraph L2["L2 — Raw Vault (DV2.0)"]
        H["Hubs<br/>Campaign · Party · Account"]:::raw
        L["Links<br/>Campaign–Channel–Sub"]:::raw
        S["Satellites<br/>metrics · attrs · multi-active"]:::raw
    end

    subgraph L3["L3 — Business Vault"]
        BR["Business rules<br/>FX · attribution · SCD"]:::biz
        PI["Same-as / PIT / Bridge"]:::biz
    end

    subgraph L4["L4 — Information Marts"]
        CAM["Campaign performance mart"]:::info
        RISK["Surveillance / control mart"]:::info
        FIN["Profitability / cost mart"]:::info
    end

    subgraph L5["L5 — Consumption"]
        BI["Power BI · APEX"]:::cons
        API2["Internal APIs"]:::cons
        AL["Alerts · OpenSearch"]:::cons
    end

    META["Metadata · DQ · Lineage<br/>WhereScape 3D optional"]:::gov
    ORCH["Scheduler<br/>Airflow / Control-M / DBMS_SCHEDULER"]:::tool

    ADS --> LD
    TRD --> LD
    REF --> LD
    LD --> PSA --> H & L & S
    H & L & S --> BR --> PI
    PI --> CAM & RISK & FIN
    CAM & RISK & FIN --> BI & API2 & AL
    META -.-> L1 & L2 & L3 & L4
    ORCH -.-> L1 & L2 & L3 & L4
```

### 2.2 Data Vault 2.0 entity map (Ads + Markets)

```mermaid
erDiagram
    HUB_CAMPAIGN ||--o{ LINK_CAMPAIGN_CHANNEL : "runs_on"
    HUB_CHANNEL ||--o{ LINK_CAMPAIGN_CHANNEL : "hosts"
    HUB_SUBSIDIARY ||--o{ LINK_CAMPAIGN_CHANNEL : "owns"
    HUB_CAMPAIGN ||--o{ SAT_CAMPAIGN_ATTR : "describes"
    LINK_CAMPAIGN_CHANNEL ||--o{ SAT_CAMPAIGN_METRICS : "measures"
    HUB_PARTY ||--o{ LINK_TRADE_PARTY : "participates"
    HUB_INSTRUMENT ||--o{ LINK_TRADE_PARTY : "traded"
    LINK_TRADE_PARTY ||--o{ SAT_TRADE_DETAIL : "details"
    HUB_PARTY ||--o{ SAT_PARTY_KYC : "kyc"

    HUB_CAMPAIGN {
        raw campaign_hk "hash key"
        string business_key
        timestamp load_dts
        string record_source
    }
    HUB_CHANNEL {
        raw channel_hk
        string channel_code
        timestamp load_dts
        string record_source
    }
    HUB_SUBSIDIARY {
        raw subsidiary_hk
        string legal_entity_code
        timestamp load_dts
        string record_source
    }
    LINK_CAMPAIGN_CHANNEL {
        raw link_hk
        raw campaign_hk
        raw channel_hk
        raw subsidiary_hk
        timestamp load_dts
        string record_source
    }
    SAT_CAMPAIGN_METRICS {
        raw link_hk
        timestamp load_dts
        raw hashdiff
        number impressions
        number clicks
        number spend_eur
        number cpc
    }
```

### 2.3 Load pattern (hash keys, incremental, audit)

```mermaid
sequenceDiagram
    autonumber
    participant SRC as Media / Trading Source
    participant LD as Landing (Oracle)
    participant PSA as PSA
    participant HUB as Hub Loader
    participant LNK as Link Loader
    participant SAT as Satellite Loader
    participant DQ as DQ Gate
    participant MART as Info Mart

    SRC->>LD: Extract (API/SFTP/CFT)
    LD->>PSA: Stage + CDC watermark
    PSA->>HUB: INSERT new business keys (HK)
    PSA->>LNK: INSERT new relationships (LK)
    PSA->>SAT: INSERT changed hashdiffs only
    SAT->>DQ: Completeness · freshness · referential
    alt DQ PASS
        DQ->>MART: Rebuild / merge KPIs
    else DQ FAIL
        DQ-->>DQ: Quarantine + alert (OpenSearch/Dynatrace)
    end
```

### 2.4 WhereScape / EDWH acceleration (nice-to-have)

```mermaid
flowchart LR
    classDef ws fill:#E1F5FE,stroke:#0277BD,stroke-width:2px,color:#01579B
    classDef ora fill:#FFF3E0,stroke:#EF6C00,stroke-width:2px,color:#E65100
    classDef out fill:#E8F5E9,stroke:#2E7D32,stroke-width:2px,color:#1B5E20

    W3D["WhereScape 3D<br/>source model · DV design"]:::ws
    WRED["WhereScape RED<br/>generate DDL + loads"]:::ws
    ORA["Oracle EDWH<br/>schemas RV / BV / IM"]:::ora
    SCH["Schedules · docs · lineage"]:::out

    W3D --> WRED --> ORA --> SCH
```

| Practice | Benefit for BNPP / ALTEN |
|----------|--------------------------|
| Model hubs/links/sats in **WhereScape 3D** | Faster EDWH design reviews with Data Management |
| Generate load procedures | Consistent HK / hashdiff / load_dts patterns |
| Keep hand-crafted PL/SQL for complex surveillance | Performance & market-abuse logic stay under DE control |

### 2.5 Operating model — CET overlap

```mermaid
gantt
    title Daily collaboration window (illustrative)
    dateFormat HH:mm
    axisFormat %H:%M

    section CET (BNPP / ALTEN DE)
    Core business hours           :active, cet, 08:00, 17:00
    Standup / design sync         :crit, sync, 09:00, 10:00

    section VNT (VN engineer)
    Overlap block                 :active, vnt, 13:00, 22:00
    Deep work / loads             :work, 14:00, 18:00
    Handoff pack to CET morning   :crit, hand, 21:00, 22:00
```

### 2.6 Security, DQ & observability

```mermaid
flowchart TB
    classDef sec fill:#FFCDD2,stroke:#C62828,stroke-width:2px,color:#B71C1C
    classDef dq fill:#C8E6C9,stroke:#388E3C,stroke-width:2px,color:#1B5E20
    classDef obs fill:#BBDEFB,stroke:#1976D2,stroke-width:2px,color:#0D47A1

    SEC["Security<br/>encrypted ingest · least privilege · no PII in ads marts"]:::sec
    DQ["Data Quality<br/>freshness · null spikes · HK orphans · reconciliation"]:::dq
    OBS["Observability<br/>Dynatrace · OpenSearch · APEX ops · load audit tables"]:::obs

    SEC --> DQ --> OBS
```

Detail: [`docs/02-solution-design.md`](docs/02-solution-design.md)

### 2.7 Data Vault vs Kimball (banking)

In a bank EDW they usually **both** exist — **different jobs**; **vault feeds the stars**.

| | **Hubs / Links / Sats (DV)** | **Star schema (Kimball)** |
|---|--------------------------------|---------------------------|
| **Job** | Integrate & historize many sources | Report KPIs fast |
| **Audience** | Data engineers, audit, risk IT | Analysts, risk / finance BI |
| **History** | Full source-aware versions | Often SCD Type 2 on dims only |

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

> **DV** = integration/history (*what did we know, from which source, when?*) · **Star** = consumption (*NPL, balances, CPC by day*).

Full write-up: [`docs/03-dv-vs-kimball.md`](docs/03-dv-vs-kimball.md)

---

## 3. Sample engineering code

Runnable **illustrative** artifacts (not production BNPP code):

| Path | Purpose |
|------|---------|
| [`src/sql/01_dv2_ddl_ads.sql`](src/sql/01_dv2_ddl_ads.sql) | Oracle DDL — hubs, links, satellites (Ads domain) |
| [`src/sql/02_load_hub_campaign.plsql`](src/sql/02_load_hub_campaign.plsql) | PL/SQL hub loader with hash key |
| [`src/sql/03_load_sat_metrics.plsql`](src/sql/03_load_sat_metrics.plsql) | Satellite loader (hashdiff incremental) |
| [`src/sql/04_info_mart_campaign.sql`](src/sql/04_info_mart_campaign.sql) | Campaign performance information mart |
| [`src/sql/05_dq_checks.sql`](src/sql/05_dq_checks.sql) | DQ checks — freshness, orphans, reconciliation |
| [`src/python/ingest_media_api.py`](src/python/ingest_media_api.py) | Sample multi-source media API ingest → staging |
| [`src/python/test_hash_key.py`](src/python/test_hash_key.py) | Pytest for HK / hashdiff helpers |
| [`src/bi/campaign_kpi_model.md`](src/bi/campaign_kpi_model.md) | BI semantic model notes (Power BI / APEX) |

### 3.1 Engineering flow (code map)

```mermaid
flowchart LR
    classDef py fill:#FFF9C4,stroke:#FBC02D,stroke-width:2px,color:#F57F17
    classDef sql fill:#BBDEFB,stroke:#1E88E5,stroke-width:2px,color:#0D47A1
    classDef bi fill:#C8E6C9,stroke:#43A047,stroke-width:2px,color:#1B5E20
    classDef test fill:#F3E5F5,stroke:#8E24AA,stroke-width:2px,color:#4A148C

    PY["ingest_media_api.py"]:::py
    DDL["01_dv2_ddl_ads.sql"]:::sql
    HUB["02_load_hub_*.plsql"]:::sql
    SAT["03_load_sat_*.plsql"]:::sql
    MART["04_info_mart_*.sql"]:::sql
    DQ["05_dq_checks.sql"]:::sql
    UT["test_hash_key.py"]:::test
    BI["campaign_kpi_model.md"]:::bi

    PY --> DDL --> HUB --> SAT --> DQ --> MART --> BI
    UT -.-> HUB
    UT -.-> SAT
```

### 3.2 Hash key convention (shared by SQL + Python)

```text
HK  = SHA256( UPPER(TRIM(business_key)) || '|' || record_source_system )
HD  = SHA256( concatenated descriptive attributes in stable column order )
Load metadata: LOAD_DTS, RECORD_SOURCE, BATCH_ID
```

---

## 4. JD mapping & interview pitch

| JD requirement | How this solution demonstrates it |
|----------------|-----------------------------------|
| **Data Vault 2.0 (≥2y in last 3y)** | Full raw vault + loaders + PIT-ready sats for Ads & Trade |
| **Oracle / PL-SQL** | DDL + package-style loaders + mart SQL |
| **Data warehouse / BI** | EDWH layers L0–L5 + Power BI / APEX semantic notes |
| **WhereScape (nice)** | Explicit 3D → RED → Oracle acceleration path |
| **Risk / Finance / Insurance (nice)** | GM surveillance mart + control indicators |
| **ENG + CET overlap** | Docs in English; operating model gantt for 13–22 VNT |

**30-second pitch:**

> *I design Oracle Enterprise DWH with Data Vault 2.0 so BNPP can unify subsidiary campaign metrics and CIB control data with full audit lineage. I implement PL/SQL loaders, DQ gates, and BI marts, and can accelerate delivery with WhereScape when the factory standard calls for it — available September 2026 with strong CET overlap.*

Prep notes: [`prep/interview-pitch.md`](prep/interview-pitch.md)

---

## 5. Repo map

```text
bnpp-alten-data-solution/
├── README.md                          ← you are here (Business · Design · Code)
├── docs/
│   ├── 01-business.md
│   ├── 02-solution-design.md
│   └── 03-dv-vs-kimball.md            ← DV hubs/links/sats vs star schema
├── src/
│   ├── sql/                           ← Oracle DV2.0 + marts + DQ
│   ├── python/                        ← ingest + pytest
│   └── bi/                            ← KPI model notes
├── prep/
│   └── interview-pitch.md
└── .gitignore
```

---

## License / use

Portfolio & interview preparation only. Not affiliated with BNP Paribas or ALTEN. Do not deploy against real bank systems without formal engagement and security clearance.
