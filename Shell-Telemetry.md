La idea es que sea:

- reproducible
- modular
- fácil de mantener
- portable a otras máquinas

Tu **telemetría de shell** será básicamente un pequeño sistema llamado por ejemplo:

```
shell-telemetry
```

y guardará eventos de **Zsh** en una base **SQLite**.

---

# 1. Estructura del proyecto

Te recomiendo algo así:

```
~/.local/share/shell-telemetry
│
├─ db/
│  └─ telemetry.db
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
└─ README.md
```

Qué hace cada parte:

|carpeta|propósito|
|---|---|
|db|base de datos|
|bin|scripts ejecutables|
|hooks|integración con shell|
|schema|estructura SQL|
|queries|análisis|
|README|documentación|

---

# 2. Crear la estructura

Ejecuta esto:

```bash
mkdir -p ~/.local/share/shell-telemetry/{db,bin,hooks,schema,queries}
```

---

# 3. Esquema de base de datos

Archivo:

```
~/.local/share/shell-telemetry/schema/schema.sql
```

Contenido:

```sql
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
```

---

# 4. Crear la base de datos

```bash
sqlite3 ~/.local/share/shell-telemetry/db/telemetry.db < \
~/.local/share/shell-telemetry/schema/schema.sql
```

Esto inicializa **SQLite**.

---

# 5. Script que inserta eventos

Archivo:

```
~/.local/share/shell-telemetry/bin/telemetry-insert
```

Contenido:

```bash
#!/usr/bin/env bash

DB="$HOME/.local/share/shell-telemetry/db/telemetry.db"

cmd="$1"
exit_code="$2"
duration="$3"
cwd="$4"
timestamp="$5"

base_cmd=$(echo "$cmd" | awk '{print $1}')
args=$(echo "$cmd" | cut -d' ' -f2-)

sqlite3 "$DB" <<EOF
INSERT INTO commands(
 timestamp,
 command,
 base_cmd,
 args,
 cwd,
 exit_code,
 duration_ms,
 host,
 user
)
VALUES(
 $timestamp,
 "$cmd",
 "$base_cmd",
 "$args",
 "$cwd",
 $exit_code,
 $duration,
 "$(hostname)",
 "$(whoami)"
);
EOF
```

Hacer ejecutable:

```
chmod +x ~/.local/share/shell-telemetry/bin/telemetry-insert
```

---

# 6. Hooks de Zsh

Archivo:

```
~/.local/share/shell-telemetry/hooks/zsh-hooks.zsh
```

Contenido:

```zsh
CMD_START_TIME=0
CMD_EXEC=""

preexec() {
  CMD_START_TIME=$(date +%s%3N)
  CMD_EXEC="$1"
}

precmd() {
  local exit_code=$?
  local end=$(date +%s%3N)
  local duration=$((end - CMD_START_TIME))

  ~/.local/share/shell-telemetry/bin/telemetry-insert \
    "$CMD_EXEC" \
    "$exit_code" \
    "$duration" \
    "$PWD" \
    "$(date +%s)"
}
```

---

# 7. Activar el sistema

En tu `.zshrc` agrega:

```zsh
source ~/.local/share/shell-telemetry/hooks/zsh-hooks.zsh
```

Reinicia la shell.

Ahora **cada comando se guarda automáticamente**.

---

# 8. Queries útiles

### comandos más usados

`queries/most_used.sql`

```sql
SELECT base_cmd, COUNT(*) as count
FROM commands
GROUP BY base_cmd
ORDER BY count DESC
LIMIT 20;
```

---

### comandos más lentos

`queries/slow_commands.sql`

```sql
SELECT command, duration_ms
FROM commands
ORDER BY duration_ms DESC
LIMIT 20;
```

---

### comandos con errores

`queries/failures.sql`

```sql
SELECT command, COUNT(*)
FROM commands
WHERE exit_code != 0
GROUP BY command
ORDER BY COUNT(*) DESC;
```

---

# 9. Cómo consultar

Ejemplo:

```bash
sqlite3 ~/.local/share/shell-telemetry/db/telemetry.db \
< ~/.local/share/shell-telemetry/queries/most_used.sql
```

---

# 10. A dónde puede evolucionar esto

Este sistema se puede volver **muy poderoso**.

Posibles mejoras:

### 1️⃣ contexto git

guardar:

```
git_branch
git_repo
commit
```

---

### 2️⃣ pipelines parseados

ejemplo:

```
grep foo | sort | uniq
```

guardarlo como:

```
["grep","sort","uniq"]
```

---

### 3️⃣ dashboard

analizar con:SQLite

- DuckDB
    
- Grafana
    
- Jupyter Notebook
    

---

### 4️⃣ sincronizar entre máquinas

como hace **Atuin**.

---

💡 **Te digo algo interesante:**  
Este tipo de proyecto es **exactamente el tipo de tooling personal que construyen muchos ingenieros senior**.

Porque terminas teniendo **observabilidad de tu propia terminal**.

---

Si quieres, en el siguiente paso podemos hacer algo **MUY más elegante aún**:

1️⃣ Guardar los eventos en **JSON estructurado**  
2️⃣ Insertarlos con **DuckDB** (que es absurdamente rápido)  
3️⃣ Crear **gráficas de uso de tu shell**

y tu ThinkPad terminaría teniendo un **mini observability stack personal**. 😄

---

Agregar **aliases o funciones al final de `zsh-hooks.zsh`** mantiene todo el sistema de telemetría encapsulado en un solo lugar.

Además, para consultas SQL **las funciones suelen ser mejores que alias**, porque permiten pasar parámetros.

Usaremos **SQLite** directamente desde **Zsh**.

---

# 1. Variable global de la base de datos

Primero agrega esto al inicio o antes de las funciones:

```zsh
TELEMETRY_DB="$HOME/.local/share/shell-telemetry/db/telemetry.db"
```

---

# 2. Función base para ejecutar queries

Esto evita repetir código.

Añádelo al final del archivo:

```zsh
telemetry-query() {
  sqlite3 -header -column "$TELEMETRY_DB" "$1"
}
```

---

# 3. Comandos útiles

### comandos más usados

```zsh
hist-top() {
  telemetry-query "
  SELECT base_cmd, COUNT(*) as count
  FROM commands
  GROUP BY base_cmd
  ORDER BY count DESC
  LIMIT 20;
  "
}
```

Uso:

```
hist-top
```

---

### comandos más lentos

```zsh
hist-slow() {
  telemetry-query "
  SELECT command, duration_ms
  FROM commands
  ORDER BY duration_ms DESC
  LIMIT 20;
  "
}
```

---

### comandos con errores

```zsh
hist-fail() {
  telemetry-query "
  SELECT command, COUNT(*) as errors
  FROM commands
  WHERE exit_code != 0
  GROUP BY command
  ORDER BY errors DESC
  LIMIT 20;
  "
}
```

---

### comandos recientes

```zsh
hist-last() {
  telemetry-query "
  SELECT datetime(timestamp, 'unixepoch') as time,
         command,
         exit_code
  FROM commands
  ORDER BY timestamp DESC
  LIMIT 20;
  "
}
```

---

### comandos por directorio actual

```zsh
hist-here() {
  telemetry-query "
  SELECT command, COUNT(*) as count
  FROM commands
  WHERE cwd = '$PWD'
  GROUP BY command
  ORDER BY count DESC
  LIMIT 20;
  "
}
```

---

# 4. Query con argumento

Ejemplo: buscar comandos.

```zsh
hist-search() {
  local term="$1"

  telemetry-query "
  SELECT datetime(timestamp,'unixepoch') as time,
         command
  FROM commands
  WHERE command LIKE '%$term%'
  ORDER BY timestamp DESC
  LIMIT 20;
  "
}
```

Uso:

```
hist-search docker
hist-search git
```

---

# 5. Estadística rápida

```zsh
hist-stats() {
  telemetry-query "
  SELECT
    COUNT(*) as total_commands,
    COUNT(DISTINCT base_cmd) as unique_commands,
    SUM(duration_ms)/1000 as total_seconds
  FROM commands;
  "
}
```

---

# 6. Resultado final en `zsh-hooks.zsh`

Quedará conceptualmente así:

```
zsh-hooks.zsh
│
├─ hooks
│   preexec
│   precmd
│
├─ variable DB
│
└─ comandos CLI
    hist-top
    hist-slow
    hist-fail
    hist-last
    hist-here
    hist-search
    hist-stats
```

Esto convierte la shell en algo parecido a una **CLI de observabilidad**.

Ejemplo de uso real:

```
hist-top
hist-fail
hist-search ssh
hist-here
hist-last
hist-stats
```

---

💡 **Pequeño detalle elegante que podríamos agregar después:**

Un comando tipo:

```
hist-dashboard
```

que muestre algo como:

```
📊 Shell Telemetry

Total commands: 15432
Unique commands: 287
Failures: 3.2%

Top commands
git      3421
ls       2011
docker    812
```

Eso convierte tu terminal en algo muy parecido a un **mini panel de telemetría personal**.

---

Si quieres, en el siguiente paso puedo enseñarte algo **muy poderoso que casi nadie hace**:

cómo hacer que tu telemetría detecte **proyectos automáticamente (git repos)** para saber:

```
qué comandos usas en cada proyecto
cuánto tiempo trabajas en cada repo
qué herramientas usa cada proyecto
```

y eso ya empieza a parecer **analytics de desarrollo personal**.