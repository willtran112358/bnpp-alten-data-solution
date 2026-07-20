"""
Sample multi-source media API ingest → Oracle PSA (portfolio illustration).

NOT production BNPP code. Shows standardized staging shape for 20+ ad platforms.
"""

from __future__ import annotations

import hashlib
import json
import logging
from dataclasses import dataclass
from datetime import date, datetime, timezone
from typing import Any, Iterable, Protocol

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class StagedCampaignMetric:
    batch_id: str
    load_dts: datetime
    record_source: str
    subsidiary_code: str
    channel_code: str
    campaign_bk: str
    campaign_name: str | None
    campaign_status: str | None
    objective: str | None
    metric_date: date
    impressions: int | None
    clicks: int | None
    spend_eur: float | None


class MediaConnector(Protocol):
    channel_code: str
    record_source: str

    def fetch_daily(self, metric_date: date, subsidiary_code: str) -> list[dict[str, Any]]:
        ...


def normalize_google_ads(row: dict[str, Any], *, subsidiary_code: str, batch_id: str) -> StagedCampaignMetric:
    return StagedCampaignMetric(
        batch_id=batch_id,
        load_dts=datetime.now(timezone.utc),
        record_source="GOOGLE_ADS",
        subsidiary_code=subsidiary_code,
        channel_code="GOOGLE_ADS",
        campaign_bk=str(row["campaign.id"]),
        campaign_name=row.get("campaign.name"),
        campaign_status=row.get("campaign.status"),
        objective=row.get("campaign.advertising_channel_type"),
        metric_date=date.fromisoformat(row["segments.date"]),
        impressions=int(row.get("metrics.impressions") or 0),
        clicks=int(row.get("metrics.clicks") or 0),
        spend_eur=float(row.get("metrics.cost_micros", 0)) / 1_000_000.0,
    )


def normalize_meta_ads(row: dict[str, Any], *, subsidiary_code: str, batch_id: str) -> StagedCampaignMetric:
    return StagedCampaignMetric(
        batch_id=batch_id,
        load_dts=datetime.now(timezone.utc),
        record_source="META_ADS",
        subsidiary_code=subsidiary_code,
        channel_code="META_ADS",
        campaign_bk=str(row["campaign_id"]),
        campaign_name=row.get("campaign_name"),
        campaign_status=row.get("status"),
        objective=row.get("objective"),
        metric_date=date.fromisoformat(row["date_start"]),
        impressions=int(row.get("impressions") or 0),
        clicks=int(row.get("clicks") or 0),
        spend_eur=float(row.get("spend") or 0),
    )


NORMALIZERS = {
    "GOOGLE_ADS": normalize_google_ads,
    "META_ADS": normalize_meta_ads,
}


def campaign_hash_key(business_key: str, record_source: str) -> bytes:
    """Match Oracle STANDARD_HASH(UPPER(TRIM(bk)) || '|' || UPPER(TRIM(rs)), 'SHA256')."""
    payload = f"{business_key.strip().upper()}|{record_source.strip().upper()}".encode("utf-8")
    return hashlib.sha256(payload).digest()


def metrics_hashdiff(impressions: int | None, clicks: int | None, spend_eur: float | None) -> bytes:
    cpc = None if not clicks else round((spend_eur or 0) / clicks, 6)
    parts = [
        "?" if impressions is None else str(impressions),
        "?" if clicks is None else str(clicks),
        "?" if spend_eur is None else str(spend_eur),
        "?" if cpc is None else str(cpc),
    ]
    return hashlib.sha256("|".join(parts).encode("utf-8")).digest()


def stage_rows(
    connectors: Iterable[MediaConnector],
    *,
    metric_date: date,
    subsidiary_code: str,
    batch_id: str,
) -> list[StagedCampaignMetric]:
    staged: list[StagedCampaignMetric] = []
    for connector in connectors:
        raw_rows = connector.fetch_daily(metric_date, subsidiary_code)
        normalizer = NORMALIZERS[connector.channel_code]
        for row in raw_rows:
            staged.append(normalizer(row, subsidiary_code=subsidiary_code, batch_id=batch_id))
        logger.info(
            "staged %s rows from %s for %s",
            len(raw_rows),
            connector.channel_code,
            subsidiary_code,
        )
    return staged


def to_psa_jsonl(rows: Iterable[StagedCampaignMetric]) -> str:
    """Serialize for file drop / SFTP landing before SQL*Loader or external table."""
    lines = []
    for r in rows:
        lines.append(
            json.dumps(
                {
                    "batch_id": r.batch_id,
                    "load_dts": r.load_dts.isoformat(),
                    "record_source": r.record_source,
                    "subsidiary_code": r.subsidiary_code,
                    "channel_code": r.channel_code,
                    "campaign_bk": r.campaign_bk,
                    "campaign_name": r.campaign_name,
                    "campaign_status": r.campaign_status,
                    "objective": r.objective,
                    "metric_date": r.metric_date.isoformat(),
                    "impressions": r.impressions,
                    "clicks": r.clicks,
                    "spend_eur": r.spend_eur,
                },
                ensure_ascii=True,
            )
        )
    return "\n".join(lines) + ("\n" if lines else "")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    demo = [
        normalize_google_ads(
            {
                "campaign.id": "1001",
                "campaign.name": "Brand FR Q3",
                "campaign.status": "ENABLED",
                "campaign.advertising_channel_type": "SEARCH",
                "segments.date": "2026-07-19",
                "metrics.impressions": 12000,
                "metrics.clicks": 340,
                "metrics.cost_micros": 560_000_000,
            },
            subsidiary_code="BNPP_FR",
            batch_id="BATCH_DEMO_001",
        )
    ]
    print(to_psa_jsonl(demo))
    print("HK:", campaign_hash_key("1001", "GOOGLE_ADS").hex())
