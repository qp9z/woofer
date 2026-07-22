import pytest

import main


@pytest.fixture(autouse=True)
def _reset_rate_limit():
    """The rate limiter is process-global; clear it so per-test request counts
    don't bleed across the suite (every test shares the 'testclient' IP)."""
    main._rate_hits.clear()
    yield
    main._rate_hits.clear()
