FROM python:3.9-slim

# Install dependencies
WORKDIR /app
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Copy app files
COPY . .

# Expose Flask port
EXPOSE 5000

CMD ["python", "app.py"]

