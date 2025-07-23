# Wekan Docker Compose Deployment (with Caddy Reverse Proxy)

This repository provides a production-ready Docker Compose configuration for deploying [Wekan](https://wekan.github.io/) — an open-source kanban board — with MongoDB as the database backend and Caddy as a reverse proxy. The setup includes automatic initialization, SMTP support (with optional SOCKS5h proxy), and Keycloak OAuth2 integration.

## Setup Instructions

### 1. Clone the Repository

Clone the project to your server in the `/docker/wekan/` directory:

```bash
mkdir -p /docker/wekan
cd /docker/wekan

# Clone the main Wekan project
git clone https://github.com/ldev1281/docker-compose-wekan.git .
```
### 2. Create Docker Network and Set Up Reverse Proxy

This project is designed to work with the reverse proxy configuration provided by [`docker-compose-caddy`](https://github.com/ldev1281/docker-compose-caddy). To enable this integration, follow these steps:

1. **Create the shared Docker network** (if it doesn't already exist):

   ```bash
   docker network create --driver bridge proxy-client-wekan
   ```

2. **Set up the Caddy reverse proxy** by following the instructions in the [`docker-compose-caddy`](https://github.com/ldev1281/docker-compose-caddy).  

Once Caddy is installed, it will automatically detect the Wekan container via the caddy-wekan network and route traffic accordingly.

### 3. Configure and Start the Application

Configuration Variables:

| Variable Name                  | Description                                                          | Default Value                             |
|-------------------------------|----------------------------------------------------------------------|-------------------------------------------|
| `WEKAN_MONGO_VERSION`         | MongoDB image tag                                                    | `7`                                       |
| `WEKAN_VERSION`               | Wekan Docker image tag                                               | `v7.92`                                   |
| `WEKAN_APP_HOSTNAME`          | Public domain name for accessing Wekan                               | `wekan.example.com`                       |
| `WEKAN_SMTP_FROM`             | Email address used as the sender                                     | `wekan@sandbox123.mailgun.org`           |
| `WEKAN_SMTP_USER`             | SMTP username                                                        | `postmaster@sandbox123.mailgun.org`      |
| `WEKAN_SMTP_PASS`             | SMTP password                                                        | `password`                                |
| `WEKAN_SMTP_PORT`             | SMTP port                                                            | `587`                                     |
| `WEKAN_KEYCLOAK_OAUTH`        | Enable Keycloak OAuth2 (`yes` to enable, empty to disable)           | `yes`                                     |
| `WEKAN_KEYCLOAK_REALM`        | Keycloak realm name                                                  | `master`                                  |
| `WEKAN_KEYCLOAK_CLIENT_ID`    | OAuth client ID                                                      | `wekan`                                   |
| `WEKAN_KEYCLOAK_SECRET`       | OAuth client secret                                                  | `secret`                                  |
| `WEKAN_KEYCLOAK_SERVER_URL`   | Keycloak base URL (without `/realms/...`)                            | `https://auth.example.com`                |

To configure and launch all required services, run the provided script:

```bash
./tools/init.bash
```

The script will:

- Prompt you to enter configuration values (press `Enter` to accept defaults).
- Generate the .env file
- Clean up volumes and start the containers

**Important:**  
Make sure to securely store your `.env` file locally for future reference or redeployment.


### 4. Start the Wekan Service

```
docker compose up -d
```

This will start Wekan and make your configured domains available.

### 5. Verify Running Containers

```
docker compose ps
```

You should see the `Wekan-app` container running.

### 6. Persistent Data Storage

Wekan and MongoDB use the following bind-mounted volumes for data persistence:

- `./vol/wekan-db:/data/db` – MongoDB database volume
- `./vol/wekan-app/data:/data` – Wekan runtime data and attachments

---

### Example Directory Structure

```
/docker/wekan/
├── docker-compose.yml
├── tools/
│   └── init.bash
├── vol/
│   ├── wekan-app/
│   │   └── data/
│   └── wekan-db/
├── .env
```


## Creating a Backup Task for Wekan

To create a backup task for your Wekan deployment using [`backup-tool`](https://github.com/jordimock/backup-tool), add a new task file to `/etc/limbo-backup/rsync.conf.d/`:

```bash
sudo nano /etc/limbo-backup/rsync.conf.d/10-wekan.conf.bash
```

Paste the following contents:

```bash
CMD_BEFORE_BACKUP="docker compose --project-directory /docker/wekan down"
CMD_AFTER_BACKUP="docker compose --project-directory /docker/wekan up -d"

INCLUDE_PATHS=(
  "/docker/wekan/.env"
  "/docker/wekan/vol"
)
```

## License

Licensed under the Prostokvashino License. See [LICENSE](LICENSE) for details.
