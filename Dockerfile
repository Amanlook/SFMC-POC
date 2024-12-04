FROM python:3.8
 
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
    vim \
    libpq-dev \
    python3-dev \
    python3-psycopg2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
 
# Install Python dependencies
COPY requirements.txt $APP_HOME/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
 
# Copy the application code
COPY . $APP_HOME
 
# Ensure scripts have the correct permissions
RUN ["chmod", "+x", "/application/server/script/entrypoint.sh"]
 
# Expose the Flask app port
EXPOSE 5000
 
# Default entrypoint command to run the Flask app
ENTRYPOINT ["/application/server/script/entrypoint.sh"]