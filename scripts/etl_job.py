import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# ジョブの初期化
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# --- 1. S3 (Bronze) からのデータ読み取り ---
# ※バケット名は後ほどTerraformの引数から動的に渡すことも可能です
datasource = glueContext.create_dynamic_frame.from_options(
    format_options={"withHeader": True, "separator": ","},
    connection_type="s3",
    format="csv",
    connection_options={"paths": ["s3://glue-app-bronze-ap-northeast-1/test_data.csv"]},
    transformation_ctx="datasource"
)

# --- 2. RDS (PostgreSQL) への書き込み ---
# 'glue-app-connection' という名前のコネクションを後ほど定義します
glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=datasource,
    catalog_connection="glue-app-connection", # Terraformで作成したコネクション名
    connection_options={
        "dbtable": "products",
        "database": "gold_db"
    }
)

job.commit()
