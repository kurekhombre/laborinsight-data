FROM mcr.microsoft.com/playwright/python:v1.47.0-jammy

WORKDIR /app

COPY functions/extract/nfj/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY functions/extract/nfj /app/functions/extract/nfj

ENV PYTHONUNBUFFERED=1

# uruchamia Twój scraper
CMD ["python", "functions/extract/nfj/main.py"]
