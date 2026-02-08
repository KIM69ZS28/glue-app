import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import boto3
import json

# Initialize Glue context
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)

# Initialize Bedrock client
bedrock = boto3.client(service_name='bedrock-runtime')

def invoke_bedrock(prompt):
    """
    Sample function to invoke AWS Bedrock model
    """
    body = json.dumps({
        "prompt": prompt,
        "max_tokens_to_sample": 300,
        "temperature": 0.5,
        "top_k": 250,
        "top_p": 1,
        "stop_sequences": ["\\n\\nHuman:"]
    })
    
    modelId = 'anthropic.claude-v2' # Example model ID
    accept = 'application/json'
    contentType = 'application/json'
    
    try:
        response = bedrock.invoke_model(
            body=body, 
            modelId=modelId, 
            accept=accept, 
            contentType=contentType
        )
        response_body = json.loads(response.get('body').read())
        return response_body.get('completion')
    except Exception as e:
        print(f"Error invoking Bedrock: {e}")
        return None

# Main execution logic
if __name__ == "__main__":
    # Example usage
    prompt_data = "\\n\\nHuman: Explain AWS Glue in one sentence.\\n\\nAssistant:"
    result = invoke_bedrock(prompt_data)
    print(f"Bedrock Response: {result}")
    
    job.commit()
