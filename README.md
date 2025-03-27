# WeKan Docker Setup with Mailgun SMTP Proxy

This repository provides a self-hosted deployment of [WeKan](https://wekan.github.io/) using Docker Compose, with support for sending email via [Mailgun](https://www.mailgun.com/) using a lightweight TLS proxy (`socat`).

---

## 📦 Services

- **wekan-app** — the main WeKan application
- **wekan-db** — MongoDB for data storage
- **wekan-socat-smtp** — a socat-based container acting as a STARTTLS → TLS proxy for Mailgun SMTP

---

## 🚀 Getting Started

1. Clone this repository  
2. Copy the environment file and configure it:

   ```bash
   cp .env.example .env
   ```

3. Start the stack:

   ```bash
   docker compose up -d --build
   ```

4. Access WeKan via your `ROOT_URL`

---

## 📁 Project Structure

```text
.
├── docker-compose.yml         # Main service definitions
├── .env.example               # Example environment variables
├── .gitignore                 # Files excluded from Git
├── socat-tls/                 # Dockerfile for socat with OpenSSL
│   └── Dockerfile
└── vol/                       # Persistent volumes (MongoDB, WeKan)
```

---

## 📬 SMTP Configuration

WeKan sends email through `wekan-socat-smtp`, which forwards traffic to Mailgun with STARTTLS → TLS handling via socat.

**Required `.env` variable:**

```env
MAIL_URL=smtp://your-login:your-password@wekan-socat-smtp:587/?tls.rejectUnauthorized=false
```

**Note:** The `?tls.rejectUnauthorized=false` suffix is required to avoid hostname mismatch errors with Mailgun certificates.

---

## ✅ Logs & Debugging

- `wekan-db` includes a Docker healthcheck
- `socat` runs in verbose mode (`-d -d -v`) to help debug SMTP communication

---

## 🧪 Testing Email

Create a user in the WeKan web UI — WeKan should send a verification email using the configured SMTP proxy.

To verify logs:

```bash
docker logs wekan-app
docker logs $(docker ps -qf name=wekan-socat-smtp)
```

---

## 🧹 Cleaning Up

To stop and remove containers:

```bash
docker compose down
```

---

