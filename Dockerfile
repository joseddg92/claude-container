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
	gnupg \
	lsb-release \
    && rm -rf /var/lib/apt/lists/*

# ── PostgreSQL 17 client binaries ─────────────────────────────────────────────
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] \
        https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client-17 \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js 22 LTS (required for Claude Code) ────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── Claude Code CLI ───────────────────────────────────────────────────────────
RUN npm install -g @anthropic-ai/claude-code

# ── Foundry (forge, cast, anvil, chisel) ─────────────────────────────────────
RUN curl -L https://foundry.paradigm.xyz | bash \
    && /root/.foundry/bin/foundryup \
    && cp /root/.foundry/bin/forge \
           /root/.foundry/bin/cast \
           /root/.foundry/bin/anvil \
           /root/.foundry/bin/chisel \
           /usr/local/bin/ \
    && rm -rf /root/.foundry

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
