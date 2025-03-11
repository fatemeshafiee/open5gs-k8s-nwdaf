from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import StreamTableEnvironment

# Initialize Flink environment
env = StreamExecutionEnvironment.get_execution_environment()
table_env = StreamTableEnvironment.create(env)

# MongoDB Change Streams Source
table_env.execute_sql("""
    CREATE TABLE mongo_stream (
        _id STRING,
        operationType STRING,
        fullDocument ROW<seID INT, SrcIp STRING, DstIp STRING, SrcPort INT, DstPort INT>
    ) WITH (
        'connector' = 'mongodb',
        'uri' = 'mongodb://nwdaf-database.open5gs.svc.cluster.local:27017',
        'database' = 'testing',
        'collection' = 'upf',
        'change.stream' = 'true'
    )
""")

# Process updates
stream = table_env.sql_query("SELECT fullDocument.seID, fullDocument.SrcIp FROM mongo_stream")
stream.execute().print()
