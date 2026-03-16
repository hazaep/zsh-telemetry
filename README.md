# Shell Telemetry

A lightweight personal **command telemetry system** for the shell.

It records every command executed in **Zsh** into a local **SQLite** database and provides simple queries to analyze usage patterns, failures, and performance.

The goal is to turn your shell history into **structured data** that can be explored and analyzed.

---

## Features

* Records every executed command
* Stores structured metadata
* Tracks execution duration
* Tracks exit status
* Stores working directory
* Query commands directly from the shell

All data is stored locally using **SQLite**.

No background services or daemons required.

---

## Data Collected

Each command execution stores:

* timestamp
* full command
* base command
* arguments
* working directory
* exit code
* execution duration
* hostname
* user

Example event:

```txt
timestamp: 1719871231
command: git commit -m fix
base_cmd: git
args: commit -m fix
cwd: /home/user/project
exit_code: 0
duration_ms: 182
host: thinkpad
user: haza
```

---

## Project Structure

```text
shell-telemetry/
│
├─ bin/
│  └─ telemetry-insert
│
├─ hooks/
│  └─ zsh-hooks.zsh
│
├─ schema/
│  └─ schema.sql
│
├─ queries/
│  ├─ most_used.sql
│  ├─ slow_commands.sql
│  └─ failures.sql
│
├─ db/
│  └─ telemetry.db   (ignored by git)
│
└─ README.md
```

The database directory is ignored because it contains **local command history**.

---

## Requirements

* Zsh
* SQLite

Install SQLite if needed:

Ubuntu / Debian

```bash
sudo apt install sqlite3
```

---

## Installation

Suggested location path: "~/.local/share"

Clone the repository:

```bash
cd ~/.local/share 
git clone git@github.com:hazaep/zsh-telemetry.git
```

Create the db:

```bash
touch ~/.local/share/shell-telemetry/db/telemetry.db
```

Initialize the database:

```bash
sqlite3 ~/.local/share/shell-telemetry/db/telemetry.db < ~/.local/share/shell-telemetry/schema/schema.sql
```

Add the hook to your `.zshrc`:

```zsh
export SHELL_TELEMETRY=/path/to_the/shell-telemetry
source ${SHELL_TELEMETRY}/hooks/zsh-hooks.zsh
```

Restart your shell.

Telemetry is now active.

---

## Query Commands

The shell hooks define several helper commands.

### Most used commands

```bash
hist-top
```

### Slowest commands

```bash
hist-slow
```

### Commands that fail most often

```bash
hist-fail
```

### Recent commands

```bash
hist-last
```

### Commands used in the current directory

```bash
hist-here
```

### Search command history

```bash
hist-search git
```

### Telemetry statistics

```bash
hist-stats
```

---

## Example Output

```text
hist-top

base_cmd     count
-------------------
git          1542
ls           1203
docker       430
ssh          214
vim          198
```

---

## Privacy

All telemetry data remains **local**.

Nothing is sent to external services.

The database is intentionally excluded from version control.

---

## Future Improvements

Possible extensions:

* Git repository detection
* Git branch tracking
* Pipeline parsing
* JSON event export
* Dashboard with DuckDB
* Visualization with Grafana
* Cross-machine synchronization

---

## Philosophy

Shell Telemetry treats the terminal like an **observable system**.

Instead of plain command history, you gain structured data that can be queried, analyzed, and visualized.

This allows you to discover patterns in your workflow and optimize your development environment.

---
