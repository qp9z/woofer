"""Makes the bridge importable for the offline tests.

The Python sources live in src/main/python (that's what Chaquopy packages into the
APK); the tests live here, in src/test/python, so they are never shipped.
"""

import sys
from pathlib import Path

BRIDGE_DIR = Path(__file__).resolve().parents[2] / "main" / "python"
sys.path.insert(0, str(BRIDGE_DIR))
