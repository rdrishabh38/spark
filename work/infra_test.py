import sys
import time
from pyspark.sql import SparkSession
from pyspark.sql.functions import expr
from delta.tables import DeltaTable

def log(msg):
    print(f"\n{'-'*60}")
    print(f"{msg}")
    print(f"{'-'*60}")

def test_local_bind_mount(spark):
    log("STEP 1: Testing Local Storage & Delta Logic (Bind Mount)")
    
    # Path inside the container (mapped to your local ./work folder)
    local_path = "/opt/spark/work-dir/delta_local_test"
    
    # 1. Write Data
    print(f"1.1 Writing 100 rows to {local_path}...")
    data = [(i, f"Item_{i}", i * 10) for i in range(100)]
    df = spark.createDataFrame(data, ["id", "name", "value"])
    df.write.format("delta").mode("overwrite").save(local_path)
    
    # 2. Update Data (Delta Logic)
    print("1.2 Running Delta UPDATE (Adding 2000 to even IDs)...")
    deltaTable = DeltaTable.forPath(spark, local_path)
    deltaTable.update(
        condition = expr("id % 2 == 0"),
        set = { "value": expr("value + 2000") }
    )
    
    # 3. Verify Update Logic
    # Old Value of ID 0 was 0. New is 2000. 2000 > 1000.
    updated_count = spark.read.format("delta").load(local_path).filter("value > 1000").count()
    print(f"    > Updated Rows: {updated_count} (Expected: 50)")
    
    if updated_count != 50:
        raise Exception(f"Local Delta Update Logic Failed. Expected 50, got {updated_count}")
        
    print("✅ Local Storage & Delta Logic Passed.")

def test_s3_connectivity(spark):
    log("STEP 2: Testing MinIO/S3 Connectivity")
    
    # Path in MinIO (Bucket created by minio-init container)
    s3_path = "s3a://test-bucket/delta_s3_test"
    
    # 1. Write Data
    print(f"2.1 Writing data to {s3_path}...")
    # We use a smaller dataset for network test
    data = [("S3_Test", 999)]
    df = spark.createDataFrame(data, ["name", "val"])
    
    try:
        df.write.format("delta").mode("overwrite").save(s3_path)
    except Exception as e:
        print(f"❌ S3 Write Failed. Check MinIO logs.")
        raise e
        
    # 2. Read Data
    print("2.2 Reading back from S3...")
    read_df = spark.read.format("delta").load(s3_path)
    count = read_df.count()
    
    print(f"    > Rows Read: {count}")
    
    if count != 1:
        raise Exception("S3 Read/Write Integrity Failed.")
        
    print("✅ MinIO/S3 Connectivity Passed.")

def main():
    print("="*60)
    print("🚀 STARTING INFRASTRUCTURE VALIDATION")
    print("="*60)
    
    # Initialize Spark once for both tests
    spark = SparkSession.builder \
        .appName("Combined_Infra_Test") \
        .getOrCreate()
        
    print(f"Spark Version: {spark.version}")
    
    try:
        test_local_bind_mount(spark)
        test_s3_connectivity(spark)
        
        print("\n" + "="*60)
        print("✅✅✅ ALL SYSTEMS GO: INFRASTRUCTURE READY ✅✅✅")
        print("="*60)
        
    except Exception as e:
        print("\n" + "!"*60)
        print(f"❌ TEST FAILED: {e}")
        print("!"*60)
        sys.exit(1)
    finally:
        spark.stop()

if __name__ == "__main__":
    main()