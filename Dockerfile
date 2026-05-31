# Claude Code sandbox
# Base: Python 3.14 slim (Debian Trixie) — official Docker image
# Adds: Node.js 22 LTS (required by Claude Code), OpenSSH server, common dev tools
FROM python:3.14-slim-trixie

# ── System packages ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        openssh-server \
        curl \
        git \
        build-essential \
        ca-certificates \
        vim \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js 22 LTS (required for Claude Code) ────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── Claude Code CLI ───────────────────────────────────────────────────────────
RUN npm install -g @anthropic-ai/claude-code

# ── SSH daemon setup ──────────────────────────────────────────────────────────
RUN mkdir /var/run/sshd

# Harden SSH: disable root login, require password auth, no X11
RUN sed -i \
        -e 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' \
        -e 's/#PasswordAuthentication yes/PasswordAuthentication yes/' \
        -e 's/X11Forwarding yes/X11Forwarding no/' \
        /etc/ssh/sshd_config \
    && echo "AllowUsers claude" >> /etc/ssh/sshd_config

# ── Non-root user: claude ─────────────────────────────────────────────────────
# Password is set at container start-up via the entrypoint (injected from .env)
RUN useradd -m -s /bin/bash claude \
    && usermod -aG sudo claude \
    # Allow passwordless sudo so Claude Code can install system packages
    && echo "claude ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/claude \
    && chmod 0440 /etc/sudoers.d/claude

# Workspace that Claude Code will use
RUN mkdir -p /workspace && chown claude:claude /workspace

WORKDIR /workspace

# ── Entrypoint: set password then start SSH ───────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
