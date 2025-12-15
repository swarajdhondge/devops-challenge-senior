FROM python:3.12-slim AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --target=/app/dependencies -r requirements.txt

FROM python:3.12-slim

LABEL description="SimpleTimeService"

WORKDIR /app

RUN groupadd --gid 1000 appgroup && \
    useradd --uid 1000 --gid appgroup --shell /bin/bash --create-home appuser

# Copy dependencies and application
COPY --from=builder /app/dependencies /app/dependencies
COPY main.py .

ENV PYTHONPATH=/app/dependencies
ENV PYTHONUNBUFFERED=1

USER appuser

EXPOSE 8000

CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

