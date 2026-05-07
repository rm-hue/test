# ─────────────────────────────────────────────────────────────────────────────
#  Aerotender — Defence Tender Scraper
#  Dockerfile for Railway deployment
#  Base: Python 3.11 slim + Chromium (headless)
# ─────────────────────────────────────────────────────────────────────────────

FROM python:3.11-slim

# ── System dependencies ───────────────────────────────────────────────────────
# We install ONLY Chromium (the browser). We intentionally DO NOT install
# 'chromium-driver' via apt-get. Instead, we let Python's 'webdriver-manager'
# download the exact matching ChromeDriver version to prevent version-mismatch
# crashes (which are the #1 cause of "session not created" errors).
RUN apt-get update && apt-get install -y --no-install-recommends \
        chromium \
        fonts-liberation \
        libnss3 \
        libatk-bridge2.0-0 \
        libgtk-3-0 \
        libxss1 \
        libgbm1 \
        libasound2 \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ── Tell aerotender to use the system Chromium binary ────────────────────────
ENV CHROME_BIN=/usr/bin/chromium
# CHROMEDRIVER_PATH is intentionally omitted here so that aerotender.py
# falls back to: ChromeDriverManager().install()

# ── App directory ─────────────────────────────────────────────────────────────
WORKDIR /app

# ── Python dependencies ───────────────────────────────────────────────────────
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── Application source ────────────────────────────────────────────────────────
COPY . .

# Railway injects $PORT automatically; gunicorn binds to it.
# Timeout is 600s because the scraping process takes several minutes.
# Workers=1 prevents memory spikes (two Chrome instances run inside the thread pool).
CMD gunicorn app:app \
        --bind 0.0.0.0:${PORT:-8000} \
        --workers 1 \
        --threads 4 \
        --timeout 600 \
        --log-level info