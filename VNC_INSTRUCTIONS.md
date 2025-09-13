# VNC Access Instructions

This Docker setup includes VNC server for viewing Chrome running inside the container.

## Access the VNC Session

1. **Build and run the Docker container:**
   ```bash
   docker-compose up --build
   ```

2. **Connect to VNC:**
   - **Host:** localhost
   - **Port:** 5901
   - **Password:** None (no password required)

## VNC Client Options

### Option 1: macOS Built-in Screen Sharing
1. Open Finder
2. Press `Cmd + K` (Go > Connect to Server)
3. Enter: `vnc://localhost:5901`
4. Click Connect

### Option 2: VNC Viewer Applications
- **RealVNC Viewer:** Download from https://www.realvnc.com/en/connect/download/viewer/
- **TigerVNC:** Available via Homebrew: `brew install tiger-vnc`
- **TightVNC:** Download from https://www.tightvnc.com/

### Option 3: Command Line (Tiger VNC)
```bash
# Install Tiger VNC if not already installed
brew install tiger-vnc

# Connect to VNC session
vncviewer localhost:5901
```

## What You'll See

Once connected to VNC, you'll see:
- A desktop environment (Fluxbox window manager)
- Chrome browser running your automation tasks
- Terminal windows if needed

## Environment Details

- **Display:** :1
- **Resolution:** 1024x768x24
- **Window Manager:** Fluxbox (lightweight)
- **VNC Server:** x11vnc

## Troubleshooting

1. **Can't connect to VNC:**
   - Ensure the container is running: `docker-compose ps`
   - Check if port 5901 is exposed: `docker-compose logs`

2. **Black screen in VNC:**
   - Wait a few seconds for the desktop environment to load
   - Try refreshing the VNC connection

3. **Performance issues:**
   - VNC runs on localhost, so performance should be good
   - If needed, you can modify the resolution in the Dockerfile

## Security Note

This VNC setup is configured for local development only (listening on localhost). Do not expose port 5901 to external networks in production environments.
