FROM python:3.10
 
LABEL summary="SMFC ACTIVITY CONTAINER" \
    name="gale-smfc-activity" \
    version="1.0" \
    maintainer="Gale" \
    build="docker build -t flask-app:1.0 ."
 
# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=linux
ENV HOME=/root
ENV APP_HOME=/application/server
ENV PYTHONUNBUFFERED=1
 
# Define en_US locale
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8
ENV LC_MESSAGES=en_US.UTF-8
 
# Set the working directory
WORKDIR $APP_HOME
 
# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    build-essential \
    gcc \
    libpq-dev \
    python3-dev \
    python3-psycopg2 \
    vim \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
 
# Install Python dependencies
COPY requirements.txt $APP_HOME/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
 
# Copy specific application files and directories
COPY server/config/ $APP_HOME/config/
COPY server/script/ $APP_HOME/script/
COPY server/app.py $APP_HOME/app.py
 
# Expose the Flask app port
EXPOSE 5000
