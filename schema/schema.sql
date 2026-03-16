CREATE TABLE IF NOT EXISTS commands (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp INTEGER NOT NULL,
    command TEXT NOT NULL,
    base_cmd TEXT,
    args TEXT,
    cwd TEXT,
    git_repo TEXT,
    git_branch TEXT,
    tty TEXT,
    session_id TEXT,
    exit_code INTEGER,
    duration_ms INTEGER,
    host TEXT,
    user TEXT
);

CREATE INDEX IF NOT EXISTS idx_timestamp ON commands(timestamp);
CREATE INDEX IF NOT EXISTS idx_base_cmd ON commands(base_cmd);
CREATE INDEX IF NOT EXISTS idx_exit_code ON commands(exit_code);
CREATE INDEX IF NOT EXISTS idx_repo ON commands(git_repo);

