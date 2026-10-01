# Port Checker

A cross-platform port checker that determines whether a TCP port is **open** or **closed**. The project includes a **Linux container** (Docker + Ubuntu) running a Bash script, and a **PowerShell script** that runs natively on **Windows 11** (outside Docker).

---

## 📁 Project Structure

```mermaid
graph TD
    A[port-checker/] --> B[Dockerfile]
    A --> C[check_port.sh]
    A --> D[Check-Port.ps1]
    A --> E[README.md]

    B -->|builds| F[Linux container image]
    C -->|runs inside| F
    D -->|runs on| G[Windows 11 host]
    F -->|verifies| H[(TCP ports)]
    G -->|verifies| H
```

---

## 🏗️ Architecture Overview

```mermaid
flowchart LR
    subgraph Windows11["🪟 Windows 11 Host"]
        PS["Check-Port.ps1"]
    end

    subgraph Docker["🐳 Docker Desktop"]
        subgraph Container["port-checker:1.0 (Ubuntu)"]
            SH["check_port.sh"]
            NC["netcat"]
            SH --> NC
        end
    end

    subgraph Targets["🎯 Verification Targets"]
        T1["127.0.0.1 (host)"]
        T2["host.docker.internal"]
        T3["Remote hosts (google.com, 8.8.8.8)"]
        T4["Other containers (nginx, etc.)"]
    end

    PS --> T1
    PS --> T3
    PS --> T4
    NC --> T2
    NC --> T3
    NC --> T4
```

---

## 🐧 Part 1 — Linux Container (Docker)

### Requirements

- Docker installed (Docker Desktop or Docker Engine).
- No additional dependencies: `netcat` is installed inside the image.

### Workflow

```mermaid
flowchart TD
    A[Start] --> B[docker build -t port-checker:1.0 .]
    B --> C{Image built?}
    C -->|Yes| D[docker run --rm port-checker:1.0 PORT HOST]
    C -->|No| E[Check Dockerfile / logs]
    D --> F{Port open?}
    F -->|Yes| G[Exit 0 — ABERTO]
    F -->|No| H[Exit 1 — CERRADO]
```

### Build the image

From the `port-checker/` directory:

```bash
docker build -t port-checker:1.0 .
```

Verify the image was created:

```bash
docker images | grep port-checker
```

### Run the container

**Usage:**

```bash
docker run --rm port-checker:1.0 <port> [host]
```

**Examples:**

```bash
docker run --rm port-checker:1.0 9999
docker run --rm port-checker:1.0 53 8.8.8.8
docker run --rm port-checker:1.0 443 google.com
docker run --rm port-checker:1.0
```

**Expected output:**

```
🔍 Verificando puerto 443 en google.com...
✅ El puerto 443 está ABIERTO en google.com
```

**Exit codes:**

| Code | Meaning |
|------|---------|
| `0`  | Port is open |
| `1`  | Port is closed, timeout, or invalid argument |

### Verifying a container from the host

```mermaid
flowchart LR
    subgraph Host["Host machine"]
        H1["127.0.0.1 / host.docker.internal"]
    end
    subgraph C1["Container A: port-checker"]
        NC["netcat"]
    end
    subgraph C2["Container B: nginx"]
        NG["port 80"]
    end

    NC -->|"--network host"| H1
    NC -->|"host.docker.internal"| H1
    NC -->|"--network test-net"| NG
```

- **Linux/macOS:**
  ```bash
  docker run --rm --network host port-checker:1.0 8000 127.0.0.1
  ```
- **Windows/macOS (Docker Desktop):**
  ```bash
  docker run --rm port-checker:1.0 8000 host.docker.internal
  ```

To verify a port exposed by another container on the same network:

```bash
docker network create test-net
docker run -d --name mi-nginx --network test-net -p 8080:80 nginx
docker run --rm --network test-net port-checker:1.0 80 mi-nginx
```

---

## 🪟 Part 2 — PowerShell Script (Windows 11 host)

This script runs **outside Docker**, directly in PowerShell on your Windows 11 machine.

### Requirements

- Windows 11 with PowerShell 5.1 or PowerShell 7+.
- No external dependencies (uses `System.Net.Sockets.TcpClient`).

### Execution flow

```mermaid
flowchart TD
    A[Start] --> B[Set-ExecutionPolicy -Scope Process Bypass]
    B --> C[.\Check-Port.ps1 -Puerto PORT -HostDestino HOST]
    C --> D[Create TcpClient]
    D --> E[BeginConnect async]
    E --> F{WaitOne timeout?}
    F -->|Timeout| G[Close + Exit 1<br/>CERRADO]
    F -->|Connected| H[EndConnect + Close<br/>Exit 0<br/>ABIERTO]
    F -->|Exception| I[Catch + Exit 1<br/>CERRADO]
```

### Allow script execution (once per session)

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

> This only affects the current session and reverts when the window is closed.

### Run the script

**Usage:**

```powershell
.\Check-Port.ps1 -Puerto <port> [-HostDestino <host>] [-Timeout <ms>]
```

**Parameters:**

| Parameter      | Type   | Required | Default       | Description                        |
|----------------|--------|----------|---------------|------------------------------------|
| `-Puerto`      | int    | Yes      | —             | Port number (1–65535)              |
| `-HostDestino` | string | No       | `127.0.0.1`   | Host or IP to check                |
| `-Timeout`     | int    | No       | `3000`        | Connection timeout in milliseconds |

**Examples:**

```powershell
.\Check-Port.ps1 -Puerto 9999
.\Check-Port.ps1 -Puerto 3389
.\Check-Port.ps1 -Puerto 443 -HostDestino google.com
.\Check-Port.ps1 -Puerto 3306 -HostDestino 192.168.1.50 -Timeout 5000
.\Check-Port.ps1 443 google.com
```

**Expected output:**

```
[*] Verificando puerto 8080 en 127.0.0.1 (timeout 3000ms)...
[OK] El puerto 8080 esta ABIERTO en 127.0.0.1
```

**Exit codes:**

| Code | Meaning |
|------|---------|
| `0`  | Port is open |
| `1`  | Port is closed, timeout, or connection error |

### Notes

- `$Host` is a **reserved PowerShell variable**. The parameter was renamed to `$HostDestino` to avoid a `VariableNotWritable` error.
- Avoid emojis in `.ps1` files unless saved with the correct encoding (UTF-8).

---

## 🔗 Part 3 — Verifying a Docker Container from PowerShell

```mermaid
sequenceDiagram
    participant U as User (PowerShell)
    participant D as Docker Engine
    participant C as Container (nginx)
    participant S as Check-Port.ps1

    U->>D: docker run -d --name web-demo -p 8080:80 nginx
    D->>C: Start container, publish 8080->80
    U->>D: docker port web-demo
    D-->>U: 80/tcp -> 0.0.0.0:8080
    U->>S: .\Check-Port.ps1 -Puerto 8080
    S->>S: TcpClient connect 127.0.0.1:8080
    S-->>U: [OK] Puerto 8080 ABIERTO
    U->>D: docker rm -f web-demo
```

### Step 1 — Start a container

```powershell
docker run -d --name web-demo -p 8080:80 nginx
```

### Step 2 — Discover the published port

```powershell
docker port web-demo
```

Example output:

```
80/tcp -> 0.0.0.0:8080
```

### Step 3 — Verify the port from PowerShell

```powershell
.\Check-Port.ps1 -Puerto 8080
```

Native alternative:

```powershell
Get-NetTCPConnection -LocalPort 8080 -State Listen
```

### Step 4 — Clean up

```powershell
docker rm -f web-demo
```

---

## 📊 Comparison

```mermaid
mindmap
  root((Port Checker))
    Linux Bash
      nc netcat
      Timeout -w 3
      Regex validation
      Runs in Docker
    Windows PowerShell
      TcpClient native
      AsyncWaitHandle timeout
      ValidateRange attribute
      Runs on host
```

| Feature            | Linux (Bash)              | Windows (PowerShell)                     |
|--------------------|---------------------------|------------------------------------------|
| Tool used          | `nc` (netcat)             | `System.Net.Sockets.TcpClient` (native)  |
| Timeout            | `-w 3`                    | `AsyncWaitHandle.WaitOne(3000)`          |
| Range validation   | Regex + comparison        | `[ValidateRange(1,65535)]`               |
| Arguments          | `$1`, `$2`                | `param()` with attributes                |
| Color output       | ANSI/emoji                | `-ForegroundColor`                       |
| Runs inside Docker | Yes                       | No                                       |

---

## 🧪 Quick Test Scenarios

```mermaid
flowchart LR
    T1["1. Closed port (local)"]
    T2["2. Open remote port"]
    T3["3. Container port from host"]
    T4["4. Timeout behavior"]

    T1 --> R1["docker run port-checker:1.0 9999<br/>.\\Check-Port.ps1 -Puerto 9999"]
    T2 --> R2["docker run port-checker:1.0 53 8.8.8.8<br/>.\\Check-Port.ps1 -Puerto 443 -HostDestino google.com"]
    T3 --> R3["docker run -d -p 8080:80 nginx<br/>.\\Check-Port.ps1 -Puerto 8080"]
    T4 --> R4[".\\Check-Port.ps1 -Puerto 80 -HostDestino 10.255.255.1 -Timeout 3000"]
```

1. **Closed port (local)**
2. **Open remote port**
3. **Docker container port from host**
4. **Timeout behavior**

---

## 📄 License

Educational project — free to use and modify.