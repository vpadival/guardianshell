# 🛡️ GuardianShell Daemon

**GuardianShell Daemon** is a robust UNIX-compliant system monitoring utility and secure backup agent designed to run as an interactive control panel or a headless CLI tool. 

It proactively audits system health parameters (Disk space, CPU utilization, and Swap memory thrashing), logs security alerts from authentication logs, and automates regex-based backups locked with strict read-only permissions.

---

## 📁 Directory Architecture

The project is structured like a standard UNIX utility:

```text
guardianshell/
├── config/
│   └── threshold.conf      # Sourced config file containing environment variables
├── logs/
│   └── system_monitor.log  # Output file capturing system alert logs
├── scripts/
│   ├── monitor.sh          # Audits disk space, thrashing, CPU load, and login safety
│   └── backup.sh           # Locates matching files via regex and creates read-only archives
├── .gitignore              # Restricts path configurations, logs, and venv files
└── main.sh                 # Entry point / shell interpretive cycle menu
```

---

## 🚀 Key Features

* **Interpretive Control Loop**: A fully interactive, loop-driven menu wrapper built using standard UNIX `while` cycles and `case` branches.
* **Here-Document Configuration**: Automatic self-healing configuration generator. Sourced environment variables are created on the fly if deleted or missing.
* **Redirection & Logging**: Routes operational logs to `stdout` (FD 1) and redirects warnings and security errors to `stderr` (FD 2) to append directly to the log file.
* **Thrashing Detection**: Monitors paging activity by reading page-in (`si`) and page-out (`so`) rates from `vmstat`.
* **Security log Auditing**: Parses system logs (e.g. `/var/log/auth.log`) using regex search pipelines to verify failed login patterns.
* **Smart Backups**: Finds targeted extension styles (`.sh`, `.log`, `.conf`) inside the source folder and packages them into tar archives.
* **Security Hardening**: Locks backup archives to strictly read-only modes (`chmod 400`) to prevent accidental override or deletion.

---

## ⚙️ Installation & Setup

1. Clone or copy this repository into your workspace:
   ```bash
   git clone <your-repo-link>
   cd guardianshell/
   ```

2. Make the scripts executable:
   ```bash
   chmod +x main.sh scripts/monitor.sh scripts/backup.sh
   ```

3. Initialize the default threshold configuration:
   ```bash
   ./main.sh -s
   ```
   This will auto-generate the `config/threshold.conf` file.

---

## 💻 Usage

### 1. Interactive Menu
To launch the interactive control cycle:
```bash
./main.sh
```
Follow the screen prompts to run system monitor checks, execute smart backups, read warning logs, or regenerate configuration values.

### 2. Direct CLI Modes (Positional Arguments)
Run tasks non-interactively using positional parameters:

* **Audit System Metrics**:
  ```bash
  ./main.sh -m
  ```
* **Run Smart Archive Backup**:
  ```bash
  ./main.sh -b
  ```
* **Override Backup Scan Target**:
  You can pass a custom folder path as an argument to the backup direct CLI run:
  ```bash
  ./scripts/backup.sh /path/to/custom/folder
  ```
* **Regenerate Configurations**:
  ```bash
  ./main.sh -s
  ```
* **Display Help Instructions**:
  ```bash
  ./main.sh -h
  ```
