FROM python:3.11-alpine

WORKDIR /app

# Install runtime dependencies
RUN apk update && apk add --no-cache \
    openssl \
    bash \
    curl \
    ca-certificates \
    libstdc++ \
    gcompat \
    && rm -rf /var/cache/apk/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
RUN chmod +x app.py

# Prefer /tmp for ephemeral container filesystem
ENV PORT=3000
ENV FILE_PATH=/tmp/.cache
ENV SHOW_LOG=true

RUN mkdir -p /tmp/.cache

EXPOSE 3000

CMD ["python3", "app.py"]
