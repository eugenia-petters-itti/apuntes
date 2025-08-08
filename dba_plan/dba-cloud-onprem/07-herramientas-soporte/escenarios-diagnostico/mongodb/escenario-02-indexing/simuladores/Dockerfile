FROM python:3.9-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create logs directory
RUN mkdir -p /app/logs

# Set permissions
RUN chmod +x *.py

# Default command
CMD ["python", "main_simulator.py"]
