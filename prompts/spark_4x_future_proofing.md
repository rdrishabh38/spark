# Spark 4.0 & Delta 4.0: The "Serverless" & AI Era
**Target Version:** Spark 4.0.0 (Preview/Beta)
**Goal:** Master the architecture that decouples Compute from the Interface.

## Phase 1: The Architecture Shift (Spark Connect)
*The biggest change in Spark's history. The "Driver" is no longer on your machine.*

### Module 1.1: The Thin Client
* **Concept:** gRPC communication vs. JVM interop.
* **The Lab:**
    * Setup: A Docker container running `spark-connect-server`.
    * Client: A local python script with *no Java installed*.
    * Task: Connect using `SparkSession.builder.remote("sc://localhost").getOrCreate()`.
    * **Challenge:** Try to use a "local file" (CSV on your laptop). It will fail. Learn to use `spark.addArtifacts` to ship files/dependencies to the server.

## Phase 2: The Data Typing Revolution (VARIANT)
*Solving the "JSON Schema Hell" that plagued Spark 2.x and 3.x.*

### Module 2.1: The VARIANT Type
* **Concept:** Storing arbitrary JSON structures in a highly optimized binary format (not just strings).
* **The Lab:**
    * Ingest a JSON dataset where the schema changes every 10 rows.
    * Store it in a Delta table as a single `VARIANT` column.
    * Query it using dot notation: `select v:details:sku from table`.
    * **Benchmark:** Compare the storage size and query speed of `VARIANT` vs. `MapType` vs. `StringType`.

### Module 2.2: Type Widening (Delta 4.0)
* **Concept:** Changing column types without rewriting the data.
* **The Lab:**
    * Create a table with a `byte` column. Write data.
    * Alter the table to `short`, then `int`, then `long`.
    * Write new data.
    * Verify how Delta handles the mixed-type files on read (it "widens" on the fly).

## Phase 3: Python-First Extensions
*Spark 2.4/3.x required Scala for custom logic. Spark 4.0 loves Python.*

### Module 3.1: Python Data Sources
* **Concept:** Write a `read()` and `write()` connector in pure Python.
* **The Lab:**
    * Write a Data Source that reads data directly from a public REST API (e.g., CoinGecko or Weather API).
    * Register it.
    * Usage: `spark.read.format("my_weather_api").load()`.

### Module 3.2: Python UDTFs (User Defined Table Functions)
* **Concept:** Functions that return a *table* (multiple rows/columns) from a single input.
* **The Lab:** Write a UDTF that takes a sentence and "explodes" it into a table of words with their POS (Part of Speech) tags (using NLTK or spacy).

## Phase 4: Streaming Observability (The Black Box Opened)
* **Module 4.1: The State Data Source**
    * **Problem:** In Spark 2.4/3.x, if a stream output was wrong, you couldn't see *why* (state was in binary files).
    * **Solution:** Query the state as a table.
    * **The Lab:** Run a `mapGroupsWithState`. While it runs, use a batch query to `spark.read.format("statestore").load()` and inspect the active session keys.

## Capstone Project: "The Serverless Lakehouse"
1.  **Architecture:** Run the Compute on Docker (Connect Server). Run the Logic on your Host (VS Code / PyCharm).
2.  **Ingest:** Use a **Python Data Source** to fetch live data (stock/crypto prices).
3.  **Store:** Save into **Delta 4.0** using **Type Widening** (start with float, widen to double).
4.  **Analyze:** Use **Spark SQL** with the new **ANSI** mode enabled (force yourself to handle `try_cast` errors).