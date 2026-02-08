# glue-app

## Overview
This project is a data analysis platform portfolio that integrates AWS Glue with AI capabilities (specifically AWS Bedrock).

## Architecture
- **Infrastructure**: Managed via Terraform (`infra/`)
- **ETL Jobs**: AWS Glue scripts (`src/`)
- **AI Integration**: Uses boto3 to interact with AWS Bedrock for advanced data processing.

## Structure
- `diagrams/`: Architecture diagrams
- `infra/`: Terraform configurations
- `src/`: Source code for Glue jobs and Lambda functions
- `data/`: Sample data
- `tests/`: Unit and integration tests
- `docs/adr/`: Architecture Decision Records
