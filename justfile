# Default recipe
default:
    @just --list

# ------------------------------------------------------------------------------
# Infrastructure Management
# ------------------------------------------------------------------------------

# Build images and start the cluster
up:
    @echo "📂 Preparing workspace..."
    mkdir -p work
    chmod 777 work
    @echo "🚀 Building Client and Spinning up Spark Cluster..."
    docker compose up -d --build
    @echo "✅ Cluster Ready!"
    @echo "   - Jupyter (Edge Node): http://localhost:8888"
    @echo "   - Master UI:           http://localhost:8080"
    @echo "   - Driver UI:           http://localhost:4040 (When job is running)"

# Stop the cluster
down:
    @echo "🛑 Stopping cluster..."
    docker compose down

# Stream logs from the client (Use Ctrl+C to exit)
logs:
    docker compose logs -f spark-client

# Nuke everything (Containers + Volumes + Images) - CAREFUL!
nuke:
    @echo "☢️  Nuking the environment..."
    docker compose down --volumes --rmi local
    @echo "✨ Clean slate."

# ------------------------------------------------------------------------------
# Development & Interaction
# ------------------------------------------------------------------------------

# Submit a Python script to the cluster
test:
    @echo "📦 Submitting job to cluster..."
    docker compose exec spark-client spark-submit \
        --master spark://spark-master:7077 \
        --deploy-mode client \
        --packages io.delta:delta-spark_2.12:3.0.0 \
        --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" \
        --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog" \
        /opt/spark/work-dir/app.py

# Open a Bash shell inside the Client container
shell:
    docker compose exec spark-client /bin/bash

# Open the Spark SQL REPL (Pre-configured for Delta Lake)
sql:
    @echo "⚡ Starting Spark SQL CLI with Delta support..."
    docker compose exec spark-client /opt/spark/bin/spark-sql \
        --master spark://spark-master:7077 \
        --packages io.delta:delta-spark_2.12:3.0.0 \
        --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension \
        --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog