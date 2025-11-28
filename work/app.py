import sys
import os
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, expr
from delta.tables import DeltaTable

def validate_environment():
    print("="*50)
    print("1. ENVIRONMENT CHECK")
    print("="*50)
    
    spark = SparkSession.builder \
        .appName("Infrastructure_Validation") \
        .getOrCreate()
    
    print(f"Spark Version: {spark.version}")
    
    # Path on the Bind Mount
    table_path = "/opt/spark/work-dir/delta_validation"

    print("\n" + "="*50)
    print("2. DELTA LAKE WRITE TEST")
    print("="*50)
    
    # Create 100 rows (0 to 99)
    data = [(i, f"Item_{i}", i * 10) for i in range(100)]
    df = spark.createDataFrame(data, ["id", "name", "value"])
    
    df.write.format("delta").mode("overwrite").save(table_path)
    print("✅ Write Successful.")

    print("\n" + "="*50)
    print("3. DELTA LAKE UPDATE & TIME TRAVEL")
    print("="*50)
    
    deltaTable = DeltaTable.forPath(spark, table_path)
    
    # Update all Even IDs. 
    # Old Value of ID 0 = 0.
    # New Value = 0 + 2000 = 2000. (This is safely > 1000)
    print("Running Delta UPDATE (Adding 2000 to even IDs)...")
    deltaTable.update(
        condition = expr("id % 2 == 0"),
        set = { "value": expr("value + 2000") }
    )
    
    # Verify Update
    # We expect exactly 50 rows (0, 2, 4 ... 98)
    updated_count = spark.read.format("delta").load(table_path).filter("value > 1000").count()
    print(f"Rows updated: {updated_count} (Expected: 50)")
    
    # Time Travel Check (Go back to Version 0)
    # The max value in V0 was ID 99 * 10 = 990.
    print("Checking Time Travel (Version 0)...")
    v0_df = spark.read.format("delta").option("versionAsOf", 0).load(table_path)
    v0_max = v0_df.agg({"value": "max"}).collect()[0][0]
    print(f"Max value in Version 0: {v0_max} (Expected: 990)")
    
    if updated_count == 50 and v0_max == 990:
         print("\n✅✅✅ SUCCESS: INFRASTRUCTURE IS 100% READY ✅✅✅")
    else:
         print("\n❌ Logic error still present.")
         sys.exit(1)

    spark.stop()

if __name__ == "__main__":
    validate_environment()