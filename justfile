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
    @echo "🚀 Spinning up Spark + MinIO Cluster..."
    docker compose up -d --build
    @echo "✅ Infrastructure Ready!"
    @echo "   - Jupyter:      http://localhost:8888"
    @echo "   - MinIO Console: http://localhost:9001 (User: admin / Pass: password)"
    @echo "   - Spark Master:  http://localhost:8080"

down:
    @echo "🛑 Stopping cluster..."
    docker compose down

logs:
    docker compose logs -f spark-client

nuke:
    @echo "☢️  Nuking environment..."
    docker compose down --volumes --rmi local
    @echo "✨ Clean slate."

# ------------------------------------------------------------------------------
# Development & Interaction
# ------------------------------------------------------------------------------

# Run the comprehensive infrastructure test suite
infra-test:
    @echo "🧪 Running Combined Infrastructure Test..."
    docker compose exec spark-client spark-submit \
        --master spark://spark-master:7077 \
        --deploy-mode client \
        --packages io.delta:delta-spark_2.12:3.0.0,org.apache.hadoop:hadoop-aws:3.3.4,com.amazonaws:aws-java-sdk-bundle:1.12.262 \
        --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" \
        --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog" \
        --conf "spark.hadoop.fs.s3a.endpoint=http://minio:9000" \
        --conf "spark.hadoop.fs.s3a.access.key=admin" \
        --conf "spark.hadoop.fs.s3a.secret.key=password" \
        --conf "spark.hadoop.fs.s3a.path.style.access=true" \
        --conf "spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem" \
        /opt/spark/work-dir/infra_test.py

shell:
    docker compose exec spark-client /bin/bash

# SQL with S3 support
sql:
    @echo "⚡ Starting Spark SQL..."
    docker compose exec spark-client /opt/spark/bin/spark-sql \
        --master spark://spark-master:7077 \
        --packages io.delta:delta-spark_2.12:3.0.0,org.apache.hadoop:hadoop-aws:3.3.4,com.amazonaws:aws-java-sdk-bundle:1.12.262 \
        --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" \
        --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog" \
        --conf "spark.hadoop.fs.s3a.endpoint=http://minio:9000" \
        --conf "spark.hadoop.fs.s3a.access.key=admin" \
        --conf "spark.hadoop.fs.s3a.secret.key=password" \
        --conf "spark.hadoop.fs.s3a.path.style.access=true"


# Show current infrastructure state
status:
    @echo "----------------------------------------------------------------"
    @echo "🐳 Container Status"
    @echo "----------------------------------------------------------------"
    @docker compose ps
    @echo ""
    @echo "----------------------------------------------------------------"
    @echo "🔗 Service Endpoints"
    @echo "----------------------------------------------------------------"
    @echo "📓 Jupyter Lab:      http://localhost:8888"
    @echo "✨ Spark Master UI:  http://localhost:8080"
    @echo "🧠 Spark Driver UI:  http://localhost:4040 (Active jobs only)"
    @echo "🪣 MinIO Console:    http://localhost:9001"
    @echo "   - User:          admin"
    @echo "   - Password:      password"
    @echo "   - API Endpoint:  http://localhost:9000 (Internal: http://minio:9000)"
    @echo "----------------------------------------------------------------"