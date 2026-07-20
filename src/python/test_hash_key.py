"""Unit tests for DV2.0 hash helpers used by Python ingest + aligned with Oracle loaders."""

from __future__ import annotations

from src.python.ingest_media_api import campaign_hash_key, metrics_hashdiff


def test_campaign_hash_key_is_stable_and_normalized():
    a = campaign_hash_key("  camp-1 ", "google_ads")
    b = campaign_hash_key("CAMP-1", "GOOGLE_ADS")
    assert a == b
    assert len(a) == 32


def test_campaign_hash_key_differs_by_source():
    assert campaign_hash_key("CAMP-1", "GOOGLE_ADS") != campaign_hash_key("CAMP-1", "META_ADS")


def test_metrics_hashdiff_changes_when_spend_changes():
    h1 = metrics_hashdiff(100, 10, 5.0)
    h2 = metrics_hashdiff(100, 10, 5.5)
    assert h1 != h2


def test_metrics_hashdiff_stable_for_same_inputs():
    assert metrics_hashdiff(100, 10, 5.0) == metrics_hashdiff(100, 10, 5.0)
