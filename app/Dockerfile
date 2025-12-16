# SimpleTimeService - Works with both docker run AND AWS Lambda
FROM python:3.12-slim

LABEL description="SimpleTimeService - Returns timestamp and visitor IP"
LABEL maintainer="Particle41 DevOps Challenge"

# Create non-root user (Task 1 requirement)
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY main.py .

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port for standalone mode
EXPOSE 8080

# Default: Run uvicorn for standalone docker run
# For Lambda: Override with CMD ["python", "-c", "..."] or use mangum handler
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
