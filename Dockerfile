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

# ── SSH daemon hardening ──────────────────────────────────────────────────────
# (no mkdir needed — openssh-server already creates /var/run/sshd)
RUN sed -i \
        -e 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' \
        -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' \
        -e 's/PasswordAuthentication yes/PasswordAuthentication no/' \
        -e 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' \
        -e 's/X11Forwarding yes/X11Forwarding no/' \
        /etc/ssh/sshd_config \
    && echo "AllowUsers claude" >> /etc/ssh/sshd_config \
    && echo "AuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config

# ── Non-root user: claude ─────────────────────────────────────────────────────
RUN useradd -m -s /bin/bash claude \
    && usermod -aG sudo claude \
    && echo "claude ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/claude \
    && chmod 0440 /etc/sudoers.d/claude \
    # Prepare .ssh directory with correct permissions
    && mkdir -p /home/claude/.ssh \
    && chmod 700 /home/claude/.ssh \
    && chown -R claude:claude /home/claude/.ssh

# Workspace that Claude Code will use
RUN mkdir -p /workspace && chown claude:claude /workspace

WORKDIR /workspace

# ── Entrypoint ────────────────────────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
