# PostgreSQL on AWS ECS Fargate: Infrastructure Documentation

Welcome to the **Database on ECS Fargate** repository. This project provisions a resilient, serverless PostgreSQL database running on **Amazon ECS (Fargate)** with persistent storage backed by **Amazon EFS**, service discovery via **AWS Cloud Discovery**, and automated infrastructure deployments via **GitHub Actions and Terraform**.

---

## 🏗️ Architecture Overview

The following Mermaid diagram outlines the infrastructure components, showing how incoming traffic, container orchestration, persistent storage, and remote state configuration interact across the AWS cloud environment.

```mermaid
graph TD
    subgraph GitHub Actions
        GA_Deploy[Deploy Workflow] -->|Terraform Apply| TF_Infra[Infra Workspace]
        GA_Destroy[Destroy Workflow] -->|Terraform Destroy| TF_Infra
    end

    subgraph AWS Cloud us-east-1
        subgraph S3 State Storage
            S3_Bucket[(S3 Bucket: my-new-ecs-project-state-2026)]
        end

        subgraph VPC [AWS VPC: 10.0.0.0/16]
            IGW[Internet Gateway]
            
            subgraph Public Subnets
                Subnet1[Public Subnet 1: 10.0.1.0/24]
                Subnet2[Public Subnet 2: 10.0.2.0/24]
            end

            subgraph Security Groups
                DB_SG[PostgreSQL SG: Port 5432]
                EFS_SG[EFS SG: Port 2049]
            end

            subgraph Service Discovery
                DNS[Private Namespace: database.local]
            end

            subgraph Storage Layer
                EFS[Amazon EFS File System]
                AP[EFS Access Point UID/GID 999]
                EFS --> AP
            end

            subgraph Compute Layer
                Cluster[ECS Cluster: db-project-cluster]
                Service[ECS Service: postgres-service]
                Task[ECS Task Definition: PostgreSQL Fargate]
                
                Cluster --> Service
                Service --> Task
                Task -->|Mounts Volume| AP
                Task -.->|Registers DNS| DNS
            end

            IGW --> Subnet1
            IGW --> Subnet2
            Subnet1 --> Task
            Subnet2 --> Task
        end

        subgraph ECR Registry
            ECR[AWS ECR Repository: db-fargate-project-app]
        end

        Task -->|Pulls Image| ECR
    end

    TF_Infra -.->|State & Native Lockfile| S3_Bucket
    GA_Deploy -.->|OIDC AssumeRole| IAM[GitHubActionsServiceRole]
