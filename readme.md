![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?logo=gnu-bash&logoColor=white)
![MariaDB](https://img.shields.io/badge/Database-MariaDB-003545?logo=mariadb&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue.svg)
# Automated MariaDB Backup Pipeline

A production-grade Bash script that automates MariaDB database backups with local and off-site redundancy, retention management, and cron-driven scheduling.

---

## Overview

This pipeline was designed to protect a live MariaDB database by maintaining compressed, timestamped backups across two independent locations — a local server and a remote VPS (Hostinger). It runs unattended via cron and keeps storage usage bounded through automated retention policies on both ends.

**Architecture at a glance:**

```
Local Server                        Remote VPS (Hostinger)
─────────────────────               ──────────────────────
MariaDB  →  gzip archive  ──SCP──►  /remote/backup/dir
              │                            │
     Keep last 5 locally          Keep last 5 remotely
              │
         Log rotation
```

---

## Features

- **Compressed dumps** — `mariadb-dump` output is piped directly into `gzip`, producing a `.sql.gz` archive with no intermediate uncompressed file on disk.
- **Dual-location redundancy** — backups are copied to a remote server over SCP immediately after creation, providing off-site protection.
- **Automated retention** — the 5 most recent backups are kept on both the local server and the remote VPS; older archives are removed automatically.
- **Key-based SSH authentication** — all remote operations (SCP transfer and SSH cleanup) authenticate via private key, with no passwords in the script or in transit.
- **Log rotation** — the cron-managed log file is trimmed to the last 360 lines at the end of each run to prevent unbounded growth.
- **Timestamped filenames** — archives are named `db_backup_YYYY-MM-DD_HH-MM.sql.gz` for easy identification and sorting.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| `mariadb-dump` | Available at `/usr/bin/mariadb-dump` |
| `gzip`, `ssh`, `scp` | Standard on most Linux distributions |
| SSH key pair | Private key path set in `ID_FILE`; public key installed on the remote host |
| Cron access | To schedule the script and capture its output to `LOG_FILE` |

---

## Configuration

Edit the variables at the top of `backup.sh` before deploying:

```bash
DB_USER="db_user"               # MariaDB username
DB_PASS="db_pass"               # MariaDB password
DB_NAME="db_name"               # Database to back up
LOCAL_DIR="/local/backup/dir"   # Local directory for archives
LOG_FILE="/path/to/backup.log"  # Log file path (written by cron)
REMOTE_DIR="/remote/backup/dir" # Remote directory for archives
ID_FILE="/path/to/ssh/key"      # Path to SSH private key
REMOTE_USER="remote_user"       # Remote server username
REMOTE_IP="remote_ip"           # Remote server IP or hostname
PORT="remote_port"              # SSH port on the remote server
```

---

## Deployment

**1. Make the script executable:**
```bash
chmod +x /path/to/backup.sh
```

**2. Schedule it with cron** (example: daily at 2:00 AM):
```bash
crontab -e # Or use a CRON interface from cPanel or other panels.
```
```
0 2 * * * /path/to/backup.sh >> /path/to/backup.log 2>&1
```

The cron redirect (`>>`) is what writes to `LOG_FILE`. The script trims that file at the end of each run.

---

## Security Considerations

- The script uses SSH key authentication — no passwords are stored or transmitted.
- `DB_PASS` is passed directly on the command line. For higher-security environments, consider using a MariaDB `.my.cnf` credentials file with restricted permissions (`chmod 600`) instead.
- Ensure `ID_FILE` has permissions set to `chmod 600` and is owned by the user running the cron job.

---

## Project Structure

```
backup_pipeline/
├── backup.sh        # Main backup script
├── .gitignore
└── readme.md
```
