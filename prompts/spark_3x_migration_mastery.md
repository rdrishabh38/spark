# Spark 3.x & Delta Lake: The Modern "Brownfield" Standard
**Target Version:** Spark 3.5.0 | Delta Lake 3.0
**Goal:** Master the architecture running 90% of the world's current data pipelines.

## Phase 1: The Optimizer Revolution (Spark 3.0 - 3.2)
*In Spark 2.4, the plan you saw in `explain()` was the plan you got. In 3.x, the plan changes while the query runs.*

### Module 1.1: Adaptive Query Execution (AQE)
* **Concept:** How Spark dynamically switches join strategies and coalesces partitions at runtime.
* **The Lab:**
    * Create a skewed join scenario (one key has 80% of data).
    * Run with `spark.sql.adaptive.enabled=false` (Simulate 2.4). Observe the stragglers in the UI.
    * Run with `spark.sql.adaptive.enabled=true`. Observe the "Custom Shuffle Reader" in the SQL UI and how it handles the skew automatically.
* **Key Configurations:** `spark.sql.adaptive.coalescePartitions.enabled`, `spark.sql.adaptive.skewJoin.enabled`.

### Module 1.2: Dynamic Partition Pruning (DPP)
* **Concept:** "Fact Table" scanning optimization.
* **The Lab:**
    * Join a massive Partitioned Fact Table with a filtered Dimension Table.
    * **Spark 2.4 Behavior:** Scans all partitions of the Fact table, then joins.
    * **Spark 3.x Behavior:** Injects the dimension filter *into* the Fact table scan.
    * **Verify:** Check the Physical Plan for `DynamicPruningExpression`.

## Phase 2: The Storage Evolution (Delta Lake 1.0 - 3.0)
*Moving from "Files" (Parquet) to "Tables" (Delta).*

### Module 2.1: The Transaction Log (`_delta_log`)
* **Deep Dive:** Manually inspect the JSON commits and checkpoint parquet files in the `_delta_log` folder. Understand how "Atomic Visibility" works.
* **Lab:** Perform a `vacuum` operation and see how it invalidates old snapshots.

### Module 2.2: Evolution of MERGE
* **Concept:** The `MERGE INTO` command (Upsert) did not exist in Spark 2.4.
* **The Lab:** Implement a "SCD Type 2" merge.
    * *Challenge:* Handle the "Schema Evolution" (adding a new column) inside the Merge statement using `whenNotMatchedBySource`.

### Module 2.3: Change Data Feed (CDF) (New in Delta 2.0)
* **Concept:** Reading the "Delta" between versions without a full table scan.
* **The Lab:**
    * Enable `delta.enableChangeDataFeed`.
    * Perform Insert/Update/Delete.
    * Read the stream: `spark.read.format("delta").option("readChangeFeed", "true")`.
    * Inspect `_change_type` column (insert, update_preimage, update_postimage, delete).

## Phase 3: Performance Tuning 3.x
* **Module 3.1: The "Small File" Problem Solvers:**
    * **Auto Optimize:** `delta.autoOptimize.optimizeWrite` (Writes smaller files? No, writes larger files by shuffling first).
    * **Liquid Clustering (Spark 3.4+):** The replacement for Hive-style partitioning and Z-Ordering.
    * **Lab:** Compare query performance of a Hive-Partitioned table vs. a Liquid Clustered table on a high-cardinality column.

## Phase 4: Migration Pitfalls (2.4 -> 3.x)
* **Datetime Parsing:** Spark 3.0 switched to Proleptic Gregorian calendar. Formats like `yyyy-MM-dd` might fail if you have legacy data. Learn `spark.sql.legacy.timeParserPolicy`.
* **View Resolution:** How Spark 3 resolves temporary views vs global views differently.

## Capstone Project: "The Migration"
1.  **Ingest:** Write a "Legacy" job using standard Parquet (mimic 2.4).
2.  **Transform:** "Migrate" it to a Delta Lake Bronze/Silver/Gold architecture.
3.  **Optimize:** Apply Liquid Clustering to the Gold layer.
4.  **Observe:** Use the Spark 3.x Structured Streaming UI (which is much better than 2.4) to monitor lag.