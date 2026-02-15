# glue-app

## 概要
このプロジェクトは、AWS GlueとAI機能（具体的にはAWS Bedrock）を統合したデータ分析プラットフォームのポートフォリオです。

## アーキテクチャ
- **インフラストラクチャ**: Terraformで管理 (`infra/`)
- **ETLジョブ**: AWS Glueスクリプト (`src/`)
- **AI統合**: boto3を使用してAWS Bedrockと対話し、高度なデータ処理を行います。

## 構成図
![アーキテクチャ図](diagrams/glue-app.png)
[構成図 (Draw.io)](diagrams/glue-app.drawio)

### 各コンポーネントの説明

1. **データのアップロード（データ投入）**
   ユーザーがローカル環境からCSV形式のソースデータを S3（生データ用：Bronzeバケット） へアップロードします。これがパイプライン全体のトリガーとなります。

2. **イベント検知とオーケストレーション**
   S3へのファイル設置を Amazon EventBridge が検知し、AWS Step Functions を起動します。Step Functionsを用いることで、後続の処理（Glueジョブ等）の依存関係やリトライ処理をコードベースで管理し、堅牢なオーケストレーションを実現しています。

3. **ETLジョブの起動**
   Step Functionsのワークフローに従い、AWS Glue のETLジョブが起動します。VPC接続（Glue Connection）を介して、セキュアなプライベートネットワーク内での処理が開始されます。

4. **Rawデータの読み取り（Bronze層）**
   Glueジョブが S3 Bronzeバケット から未加工（Raw）の状態のCSVデータを読み取ります。ここでのデータは、元の形式を保持したままの「唯一の真実（Single Source of Truth）」となります。

5. **AIによるデータ拡張（Amazon Bedrock連携）**
   本パイプラインの最大の特徴です。Glueジョブ内で Amazon Bedrock を呼び出し、データのクレンジング、カテゴリ分類、あるいは自然言語処理による付加情報の生成を行います。従来の手続き型コードでは困難だった「非構造化データの意味理解」をパイプラインに組み込んでいます。

6. **加工データの保存（Silver層）**
   Bedrockによる処理やスキーマ変換が完了したデータは、S3 Silverバケット にParquet等の最適化された形式で保存されます。この層のデータは、クレンジング済みで信頼性が高く、汎用的な分析に利用できる状態です。

7. **最終データロード（Gold層 / RDS）**
   最終的に、業務利用やBIツールからの参照に適した形に集計・加工されたデータが、RDS（Gold層：PostgreSQL） へロードされます。マルチAZ構成のRDSを採用することで、データの高可用性と耐久性を確保した分析基盤を構築しています。

## RDSへの診断接続手順

開発・デバッグ時にRDSへ直接接続する必要がある場合、以下の手順で一時的な診断環境を構築できます。

### 前提条件
- AWS CLI がインストールされていること
- Session Manager Plugin がインストールされていること
- PostgreSQL クライアント（`psql`）がインストールされていること

### 接続手順

1. **診断用リソースの有効化**
   ```bash
   # infra/diag.tf と infra/outputs.tf のコメントアウトを解除
   # （既に解除済みの場合はスキップ）
   ```

2. **インフラのデプロイ**
   ```bash
   cd infra
   terraform plan  # 変更内容を確認
   terraform apply
   ```

3. **ポートフォワーディングセッションの開始**
   ```bash
   # terraform output で取得した値を使用
   aws ssm start-session --target <インスタンスID> \
     --document-name AWS-StartPortForwardingSessionToRemoteHost \
     --parameters '{"host":["<RDSのエンドポイント>"],"portNumber":["5432"],"localPortNumber":["15432"]}'
   ```

4. **PostgreSQLへの接続**（新しいターミナルで実行）
   ```bash
   psql -h localhost -p 15432 -U postgres_admin -d gold_db
   ```

5. **作業完了後のクリーンアップ**
   ```bash
   # 診断用リソースを削除してコストを削減
   # infra/diag.tf と infra/outputs.tf をコメントアウトして再度 apply
   cd infra
   terraform apply
   ```

> **注意**: 診断用EC2インスタンスは使用していない時はコメントアウトして削除することを推奨します。

## ディレクトリ構成
- `diagrams/`: アーキテクチャ図
- `infra/`: Terraform設定ファイル
- `src/`: GlueジョブおよびLambda関数のソースコード
- `data/`: サンプルデータ
- `tests/`: ユニットテストおよび統合テスト
- `docs/adr/`: アーキテクチャ決定記録 (ADR)
