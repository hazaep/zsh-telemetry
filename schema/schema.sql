CREATE TABLE commands (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    timestamp INTEGER NOT NULL,

    command TEXT NOT NULL,
    base_cmd TEXT,
    args TEXT,

    cwd TEXT,

    exit_code INTEGER,

    duration_ms INTEGER,

    host TEXT,
    user TEXT
);

CREATE INDEX idx_timestamp ON commands(timestamp);
CREATE INDEX idx_base_cmd ON commands(base_cmd);
CREATE INDEX idx_exit_code ON commands(exit_code);
