# Interview pitch — BNPP / ALTEN Data Dev & Advanced Analytics

## 30-second

I build **Oracle Enterprise DWH** with **Data Vault 2.0** so group marketing and CIB controls share **auditable history** and **consumer-ready marts**. I implement **PL/SQL** loaders, **DQ gates**, and **BI** models, and can accelerate EDWH delivery with **WhereScape** when that is the factory standard. Available **Sep 2026**, strong **CET overlap (13:00–22:00 VNT)**.

## 2-minute walkthrough (use this repo)

1. **Business** — two domains: unified ads analytics (20+ sources) + GM pre/post-trade DWH patterns  
2. **Design** — L0→L5, DV hubs/links/sats, hash keys, WhereScape optional path  
3. **Code** — open `src/sql/02_load_hub_campaign.plsql` and explain HK + incremental sat  

## Likely deep-dive questions

| Question | Anchor answer |
|----------|---------------|
| Why DV2.0 vs Kimball only? | Both coexist: DV integrates/historize; Kimball marts for BI — see [`docs/03-dv-vs-kimball.md`](../docs/03-dv-vs-kimball.md) |
| Multi-active satellite? | Grain keys in PK with load_dts; e.g. device×geo metrics |
| Hash collision / unicode BK? | UTF-8 normalize + UPPER/TRIM; document BK rules per source |
| How do you test? | Pytest on hash helpers + SQL non-regression on row counts / checksums |
| WhereScape experience? | Be honest; describe 3D→RED→override pattern from this design |

## CET collaboration habits

- Written handoff before 22:00 VNT for DE morning  
- Overlap standup ~09:00 CET  
- All docs / commit messages in English  

## Do / Don't

| Do | Don't |
|----|-------|
| Cite DV terms precisely (HK, HD, RS, LDTS) | Invent confidential BNPP project names |
| Show Oracle PL/SQL comfort | Oversell Fabric-only / lakehouse-only story |
| Map risk/finance domain language | Claim production access you never had |
