FROM python:3.11-slim-bookworm

WORKDIR /app

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

# Install Python, essential packages, and VNC dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    gnupg \
    ca-certificates \
    procps \
    unzip \
    curl \
    git \
    # VNC and X11 dependencies
    x11vnc \
    xvfb \
    fluxbox \
    xterm \
    # Additional dependencies that Playwright might need
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libgconf-2-4 \
    libxss1 \
    libxtst6 \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create symlink for python command
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install Chrome/Chromium based on architecture
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        # Install Google Chrome for amd64
        wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/googlechrome-linux-keyring.gpg && \
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
        apt-get update && \
        apt-get install -y google-chrome-stable && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    else \
        # Install Chromium for ARM64 and other architectures
        apt-get update && \
        apt-get install -y chromium-browser && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Create Chrome/Chromium wrapper script to ensure compatibility
RUN echo '#!/bin/bash\n\
if command -v google-chrome-stable >/dev/null 2>&1; then\n\
    exec google-chrome-stable "$@"\n\
elif command -v chromium-browser >/dev/null 2>&1; then\n\
    exec chromium-browser "$@"\n\
else\n\
    echo "No Chrome/Chromium browser found"\n\
    exit 1\n\
fi' > /usr/local/bin/chrome && chmod +x /usr/local/bin/chrome

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright browsers
RUN playwright install chromium --with-deps

# Copy the rest of the application
COPY . .

# Create a data directory with proper permissions
RUN mkdir -p /app/data && chmod 777 /app/data

# Create a non-root user to run the app
RUN adduser --disabled-password --gecos "" appuser

# Setup VNC directories and permissions
RUN mkdir -p /home/appuser/.vnc \
    && mkdir -p /home/appuser/.fluxbox \
    && echo "session.screen0.workspaces: 1" > /home/appuser/.fluxbox/init \
    && echo "session.screen0.toolbar.visible: false" >> /home/appuser/.fluxbox/init

# Give appuser permissions to the necessary directories
RUN chown -R appuser:appuser /app \
    && chown -R appuser:appuser /home/appuser

# Expose the port the app runs on and VNC port
EXPOSE 8000 5901

# Switch to appuser
USER appuser

# Remove and move env files
RUN rm .env
RUN mv .env-docker .env

# Create VNC startup script
RUN echo '#!/bin/bash\n\
export DISPLAY=:1\n\
Xvfb :1 -screen 0 1024x768x24 &\n\
sleep 2\n\
fluxbox &\n\
x11vnc -display :1 -nopw -listen 0.0.0.0 -rfbport 5901 -xkb -ncache 10 -ncache_cr -forever &\n\
python app.py' > /home/appuser/start.sh && chmod +x /home/appuser/start.sh

# Set healthcheck to ensure the service is running properly
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8000/api/v1/ping || exit 1

# Command to run the application with VNC
CMD ["/home/appuser/start.sh"] 