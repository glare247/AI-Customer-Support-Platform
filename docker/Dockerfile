FROM python:3.11-slim AS builder

WORKDIR /build

RUN pip install --no-cache-dir hatchling

COPY pyproject.toml ./
COPY src/ai_platform/__init__.py ./src/ai_platform/__init__.py

RUN pip install --no-cache-dir --prefix=/install .

FROM python:3.11-slim AS runtime

RUN addgroup --system appgroup \
 && adduser --system --ingroup appgroup --no-create-home appuser

WORKDIR /app

COPY --from=builder /install /usr/local

COPY src/ai_platform ./ai_platform

RUN mkdir -p /tmp/ai-platform-uploads \
 && chown appuser:appgroup /tmp/ai-platform-uploads

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD python -c \
  "import urllib.request; urllib.request.urlopen('http://localhost:8000/healthz')"

CMD ["uvicorn", "ai_platform.main:app", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--workers", "2", \
     "--no-access-log"]
