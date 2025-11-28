# Apache Spark Learning Lab: Distributed Architecture

**Current Status:** ✅ Verified & Operational
**Last Validated:** November 2025

This repository contains a production-grade, containerized environment for mastering **Apache Spark 3.x/4.x** and **Delta Lake**. It is designed to mimic a real distributed cluster (Master/Worker topology) while solving common local development friction points like dependency management, storage persistence, and Python version parity.

---

## 🏗 Infrastructure Architecture

Unlike standard "tutorial" setups that run Spark in `local[*]` mode, this environment runs a full **Standalone Cluster**.

### Core Components
| Service | Image Base | Role |
| :--- | :--- | :--- |
| **Spark Master** | `spark:3.5.3` (Official) | Resource Manager (Port 8080) |
| **Spark Workers** | `spark:3.5.3` (Official) | Compute Nodes (2x Replicas) |
| **Spark Client** | Custom Build (`Dockerfile.client`) | **Edge Node**. Contains Jupyter, Delta libs, and Dev tools. Built on the *exact* same OS layer as workers to guarantee Python compatibility. |

### Key Design Decisions
1.  **Strict Version Parity:**
    * **Spark:** 3.5.3
    * **Delta Lake:** 3.0.0
    * **Python:** 3.10 (Ubuntu 22.04 base)
    * **Java:** 17
    * *Why:* Prevents the `PySparkRuntimeError: Python version mismatch` often seen when submitting jobs from a laptop to a cluster.

2.  **Persistent Storage (Bind Mounts):**
    * The local `./work` directory is mounted to `/opt/spark/work-dir` inside **all** containers.
    * Files saved here survive container restarts and are accessible by Master, Workers, and Client simultaneously.

3.  **Permission Management:**
    * Containers run as `root` user to bypass WSL2/Linux bind-mount permission conflicts.
    * The `just up` command automatically sets `chmod 777` on the `./work` directory.

---

## 🚀 Quick Start

**Prerequisites:**
* Docker & Docker Compose
* [Just](https://github.com/casey/just) (Command runner)

### 1. Spin Up
This command handles directory creation, permissions, image building, and container startup.
```bash
just up
```

### 2. Verify Access
* **Jupyter Lab:** [http://localhost:8888](http://localhost:8888) (No token required)
* **Spark Master UI:** [http://localhost:8080](http://localhost:8080)
* **Spark Driver UI:** [http://localhost:4040](http://localhost:4040) (Only active during job execution)

### 3. Run a Job (Production Simulation)
To simulate a `spark-submit` from a CI/CD pipeline or Edge Node:
1.  Create a script in `./work/app.py`.
2.  Run:
    ```bash
    just submit
    ```

---

## 🛠 Command Reference (`justfile`)

| Command | Description |
| :--- | :--- |
| `just up` | Preps workspace, builds client image, and starts the cluster. |
| `just down` | Stops and removes containers and networks. |
| `just test` | Submits `./work/app.py` to the cluster with Delta packages pre-loaded to test the project setup. |
| `just sql` | Opens the **Spark SQL CLI** with Delta support enabled. |
| `just logs` | Streams logs from the Client container. |
| `just shell` | Opens a Bash shell inside the Client container. |
| `just nuke` | **WARNING:** Deep clean. Removes containers, volumes, and built images. |

---

## 📚 Learning Paths

This repository supports two distinct learning curriculums (files included in repo):

1.  **`spark_3x_migration_mastery.md`**:
    * Focus: Spark 2.4 -> 3.x Migration.
    * Topics: Adaptive Query Execution (AQE), Dynamic Partition Pruning (DPP), Delta Merge/Update.

2.  **`spark_4x_future_proofing.md`** (Planned):
    * Focus: Spark Connect, Serverless architecture, VARIANT data type.

---

## 📝 License

**GPLv3**.
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.