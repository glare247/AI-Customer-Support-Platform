# AI Customer Support Platform — Production-Grade DevOps on AWS EKS

<div align="center">

![CI Pipeline](https://github.com/glare247/AI-Customer-Support-Platform/actions/workflows/ci.yml/badge.svg)
![CD Pipeline](https://github.com/glare247/AI-Customer-Support-Platform/actions/workflows/cd.yml/badge.svg)
![Python](https://img.shields.io/badge/python-3.11+-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-green)
![Kubernetes](https://img.shields.io/badge/kubernetes-1.35-blue)
![Terraform](https://img.shields.io/badge/terraform-1.x-purple)
![Helm](https://img.shields.io/badge/helm-3.x-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**A production-ready AI customer support chatbot deployed on AWS EKS with full DevOps infrastructure**

[Overview](#overview) · [Architecture](#architecture) · [Tech Stack](#tech-stack) · [Project Structure](#project-structure) · [Local Development](#local-development) · [AWS Deployment](#aws-deployment) · [CI/CD](#cicd-pipeline) · [Observability](#observability) · [Canary Deployments](#canary-deployments) · [Disaster Recovery](#disaster-recovery) · [Problems and Solutions](#problems-and-solutions)

</div>

---

## Overview

This project demonstrates how real companies operate AI systems in production. The focus is not just on building an AI chatbot, but on the **complete infrastructure around it** — provisioning cloud resources with Terraform, containerising the app, orchestrating it on Kubernetes, observing it with a full metrics/logs/traces stack, and continuously delivering changes through GitOps.

The platform enables a SaaS company to:

- Answer customer questions using Groq LLaMA 3.3 70B
- Persist conversation history across sessions in PostgreSQL
- Cache repeated questions in Redis to reduce LLM API costs
- Search a FAQ knowledge base using RAG (Retrieval Augmented Generation) with Qdrant
- Auto-scale pods between 1 and 4 replicas based on CPU/memory
- Deploy with zero downtime via GitOps (ArgoCD)
- Split traffic between two model versions with canary deployments
- Monitor every request with metrics, logs, and distributed traces
- Recover from failure with daily automated database backups to S3

---

## Architecture

```
                          Internet
                              |
              AWS Application Load Balancer (ALB)
              (managed by AWS Load Balancer Controller)
                    /                     \
           ~50% stable                ~50% canary
     ai-platform (v1)            ai-platform-canary (v2)
   llama-3.3-70b-versatile       llama-3.1-8b-instant
   HPA: 1-4 replicas              1 replica
                    \                    /
                     \                  /
            +---------+--------+--------+
            |                  |        |
        PostgreSQL           Redis    Qdrant
        (EBS 5Gi PVC)    (cache)  (FAQ embeddings)

    Observability Stack
    Prometheus + Grafana + Loki + Promtail + Tempo

    GitOps + CI/CD
    GitHub Actions --> ECR --> ArgoCD --> EKS

    AWS Infrastructure (Terraform)
    VPC | Subnets | NAT | IGW | EKS | ECR | EBS | IRSA
    Terraform state: S3 (versioned + encrypted)
```
<img width="1280" height="714" alt="ai architecture" src="https://github.com/user-attachments/assets/1d1f61ff-943e-4130-b89f-c0408ebf95ef" />


---

## Tech Stack

### Application
| Component | Technology | Purpose |
|---|---|---|
| API | FastAPI 0.115+ | REST endpoints |
| AI Model | Groq LLaMA 3.3 70B | Chat completions |
| Database | PostgreSQL 16 | Conversation history |
| Cache | Redis 7 | Response deduplication |
| Vector Store | Qdrant | FAQ embeddings (RAG) |
| Logging | structlog | JSON structured logs |
| Migrations | Alembic | Database schema versioning |
| Metrics | prometheus-fastapi-instrumentator | /metrics endpoint |
| Tracing | OpenTelemetry (OTLP to Tempo) | Distributed tracing |

### Infrastructure
| Component | Technology | Purpose |
|---|---|---|
| Cloud | AWS | Production hosting |
| IaC | Terraform | Provision all AWS resources |
| Orchestration | Kubernetes 1.35 (EKS) | Container management |
| Helm | Helm 3 | Kubernetes package management |
| Container Registry | AWS ECR | Docker image storage |
| Load Balancer | AWS ALB | Internet-facing ingress |
| Storage | AWS EBS gp2 | Persistent volumes |
| Remote State | AWS S3 | Terraform state backend |

### CI/CD and GitOps
| Component | Technology | Purpose |
|---|---|---|
| CI Pipeline | GitHub Actions | Lint, test, build, push to ECR |
| CD Pipeline | GitHub Actions | Update Helm values.yaml image tag |
| GitOps | ArgoCD | Auto-deploy on Git change |
| Pattern | App of Apps | Single bootstrap manages all ArgoCD apps |

### Observability
| Component | Technology | Purpose |
|---|---|---|
| Metrics | Prometheus (kube-prometheus-stack) | Scrape and store metrics |
| Dashboards | Grafana | Visualise metrics, logs, traces |
| Logs | Loki + Promtail | Centralised log aggregation |
| Traces | OpenTelemetry + Tempo | Distributed request tracing |

---

## Project Structure

```
AI-Customer-Support-Platform/
|
+-- src/
|   +-- ai_platform/
|   |   +-- api/
|   |   |   +-- chat.py              # POST /v1/chat
|   |   |   +-- conversations.py     # GET/PATCH/DELETE /v1/conversations
|   |   |   +-- health.py            # GET /healthz  GET /readyz
|   |   |   +-- rag.py               # POST /v1/rag
|   |   |   +-- files.py             # POST /v1/files (PDF, DOCX, etc.)
|   |   +-- core/
|   |   |   +-- logging.py           # structlog JSON setup
|   |   |   +-- middleware.py        # RequestID + Timing middleware
|   |   |   +-- telemetry.py         # OpenTelemetry OTLP exporter
|   |   +-- services/
|   |   |   +-- llm_client.py        # Groq API wrapper (httpx)
|   |   |   +-- cache_service.py     # Redis caching
|   |   |   +-- conversation_service.py
|   |   |   +-- rag_service.py       # Qdrant RAG pipeline
|   |   +-- db/
|   |   |   +-- versions/
|   |   |       +-- 001_initial.py   # conversations + messages tables
|   |   |       +-- 002_add_title.py
|   |   +-- models/                  # SQLAlchemy ORM models
|   |   +-- schemas/                 # Pydantic schemas
|   |   +-- config.py                # pydantic-settings config
|   |   +-- main.py                  # FastAPI app factory
|   |
|   +-- tests/
|   |   +-- test_health.py
|   |   +-- test_chat_endpoint.py
|   |   +-- test_cache_service.py
|   |   +-- test_llm_client.py
|   |
|   +-- scripts/
|       +-- seed_qdrant.py           # Load FAQ embeddings into Qdrant
|
+-- docker/
|   +-- Dockerfile                   # Multi-stage production build
|
+-- helm/
|   +-- ai-platform/
|   |   +-- values.yaml              # v1 stable values
|   |   +-- values-canary.yaml       # v2 canary overrides
|   |   +-- templates/
|   |       +-- deployment.yaml      # Rolling update + version labels
|   |       +-- service.yaml         # ClusterIP (skipped for canary)
|   |       +-- ingress.yaml         # ALB ingress (skipped for canary)
|   |       +-- hpa.yaml             # HPA 1-4 replicas
|   +-- monitoring/
|       +-- prometheus-values.yaml   # kube-prometheus-stack config
|       +-- loki-values.yaml         # Loki + Promtail config
|
+-- k8s/
|   +-- base/
|   |   +-- kustomization.yaml
|   |   +-- postgres.yaml            # Deployment + PVC 5Gi EBS + Service
|   |   +-- redis.yaml
|   |   +-- qdrant.yaml
|   |   +-- migration-job.yaml       # Alembic upgrade head
|   |   +-- seed-job.yaml            # Qdrant FAQ seeding
|   |   +-- network-policies.yaml    # Restrict backend access to app only
|   |   +-- postgres-backup.yaml     # Daily pg_dump CronJob to S3
|   |   +-- postgres-restore.yaml    # One-command restore Job
|   +-- monitoring/
|   |   +-- argocd-prometheus.yaml
|   |   +-- argocd-loki.yaml
|   |   +-- grafana-dashboard.yaml
|   +-- argocd-app.yaml
|   +-- argocd-app-base.yaml
|   +-- argocd-app-of-apps.yaml      # App of Apps bootstrap
|
+-- terraform/
|   +-- main.tf                      # VPC, EKS, ECR, OIDC, IRSA
|   +-- variables.tf
|   +-- outputs.tf
|   +-- providers.tf                 # S3 backend + AWS provider
|
+-- .github/
|   +-- workflows/
|       +-- ci.yml                   # Lint, Test, Build, Push to ECR
|       +-- cd.yml                   # Update Helm image tag
|
+-- docker-compose.yml               # Local dev services
+-- iam_policy.json                  # ALB Controller IAM policy
+-- pyproject.toml                   # Python deps and tool config
```

---

## Local Development

### Prerequisites

- Python 3.11+
- Docker Desktop
- Git

### Step 1 — Clone and configure

```bash
git clone https://github.com/glare247/AI-Customer-Support-Platform.git
cd AI-Customer-Support-Platform

cp .env.example .env
# Set LLM_API_KEY to your Groq API key (free at console.groq.com)
```

### Step 2 — Start backing services

```bash
docker compose up -d
# Starts: postgres:5432, redis:6379, qdrant:6333
```

### Step 3 — Install Python dependencies

```bash
python3 -m venv .venv
source .venv/bin/activate

pip install -e .
pip install -e ".[dev]"
```

### Step 4 — Run migrations and seed data

```bash
export PYTHONPATH=$PWD/src
alembic -c src/ai_platform/db/alembic.ini upgrade head

export $(cat .env | grep -v '#' | xargs)
python src/scripts/seed_qdrant.py
```

### Step 5 — Start the application

```bash
uvicorn ai_platform.main:app --host 0.0.0.0 --port 8000 --reload
```

### Step 6 — Verify

```bash
curl http://localhost:8000/healthz
# {"status":"ok"}

curl http://localhost:8000/readyz
# {"status":"ok","checks":{"database":"ok","redis":"ok","qdrant":"ok"}}

curl -X POST http://localhost:8000/v1/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is your return policy?"}'
```

Open the chat UI at http://localhost:8000

### Step 7 — Run tests

```bash
pytest src/tests/ -v
```

---

## AWS Deployment

### Prerequisites

- AWS CLI (configured with credentials)
- Terraform
- kubectl
- Helm

### Step 1 — Provision infrastructure

```bash
cd terraform/
terraform init
terraform apply
```

Creates: VPC, public/private subnets across 2 AZs, NAT Gateway, Internet Gateway, EKS cluster (Kubernetes 1.35), node group (t3.small x4), ECR repository, OIDC provider, IAM roles for IRSA.
<img width="1792" height="1120" alt="aws" src="https://github.com/user-attachments/assets/c2276a86-f853-45fd-9f08-327b02f58792" />

### Step 2 — Connect kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name sentinel-eks-cluster
kubectl get nodes
```

### Step 3 — Install cluster add-ons

```bash
# EBS CSI Driver (required for PersistentVolumeClaims)
aws eks create-addon \
  --cluster-name sentinel-eks-cluster \
  --addon-name aws-ebs-csi-driver \
  --service-account-role-arn <ebs-csi-role-arn>

# AWS Load Balancer Controller (required for ALB ingress)
helm repo add eks https://aws.github.io/eks-charts
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=sentinel-eks-cluster \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$(cd terraform && terraform output -raw alb_controller_role_arn)
```

### Step 4 — Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get admin password
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d && echo
``
### Step 5 — Create application secrets

```bash
kubectl create namespace ai-platform

kubectl create secret generic ai-platform-secrets \
  --namespace ai-platform \
  --from-literal=LLM_API_KEY=your-groq-key \
  --from-literal=DATABASE_URL="postgresql+asyncpg://aiplatform:aiplatform@postgres:5432/aiplatform" \
  --from-literal=REDIS_URL="redis://redis:6379/0" \
  --from-literal=QDRANT_HOST="qdrant" \
  --from-literal=QDRANT_PORT="6333"
```
<img width="1792" height="1120" alt="argocd homepage" src="https://github.com/user-attachments/assets/8b85d7a3-fdc8-4bb4-8f83-e116dd4a4109" />


### Step 6 — Bootstrap ArgoCD (App of Apps)

```bash
kubectl apply -f k8s/argocd-app-of-apps.yaml
```

This single command triggers ArgoCD to deploy the AI platform, all base services (postgres, redis, qdrant, migration job, seed job), and the monitoring stack.

### Step 7 — Run database migrations

```bash
kubectl apply -f k8s/base/migration-job.yaml
kubectl wait --for=condition=complete job/alembic-migration -n ai-platform --timeout=120s

# Verify
kubectl exec -n ai-platform $(kubectl get pod -n ai-platform -l app=postgres \
  -o jsonpath='{.items[0].metadata.name}') \
  -- psql -U aiplatform -d aiplatform -c "\dt"
```

### Step 8 — Verify

```bash
kubectl get pods -A
kubectl get ingress -n ai-platform

curl http://<alb-url>/healthz
curl -X POST http://<alb-url>/v1/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello!"}'
```

---

## CI/CD Pipeline

### Flow

```
git push origin main
       |
       v
GitHub Actions CI
  1. Lint with ruff
  2. Run pytest test suite
  3. Build Docker image (multi-stage)
  4. Push to AWS ECR
     Tag: sha-<short-commit>
       |
       v
GitHub Actions CD
  Updates helm/ai-platform/values.yaml:
    image.tag: sha-<short-commit>
  Commits and pushes to GitHub
       |
       v (ArgoCD detects values.yaml changed)
ArgoCD
  Pulls new image from ECR
  Rolling update in EKS
  Zero downtime (maxUnavailable: 0)
  Self-heals any manual drift within 3 minutes

```
<img width="1792" height="1120" alt="ci" src="https://github.com/user-attachments/assets/04a111c7-fc7e-4770-bf5f-730dfece2923" />

<img width="1792" height="1120" alt="ci2" src="https://github.com/user-attachments/assets/5e6d5ecf-40e7-4d0f-809c-91343d405c78" />



<img width="1792" height="1120" alt="ci new" src="https://github.com/user-attachments/assets/bced75f0-4758-431b-b381-386f179dd122" />

<img width="1792" height="1120" alt="argocd1" src="https://github.com/user-attachments/assets/a4a1e2c5-ee2d-4173-869f-07fe1b0beb72" />


<img width="1792" height="1120" alt="argocd2" src="https://github.com/user-attachments/assets/0b93766e-d48a-4134-8534-a40d2380db74" />

<img width="1792" height="1120" alt="argod3" src="https://github.com/user-attachments/assets/f4ee568d-a1bc-44c9-a8b3-6a82c2c783b9" />

### Rollback

```bash
# Option 1 - Helm (30 seconds)
helm history ai-platform -n ai-platform
helm rollback ai-platform 2 -n ai-platform

# Option 2 - Git revert (GitOps)
git revert HEAD && git push origin main
# ArgoCD auto-deploys the revert
```

---

## Observability

### Stack

| Tool | Access | Credentials |
|---|---|---|
| Grafana | LoadBalancer URL | admin / admin123 |
| Prometheus | kubectl port-forward 9090 | none |
| Loki | via Grafana Explore | none |
| Tempo | via Grafana Explore | none |


<img width="1792" height="1120" alt="grafana1" src="https://github.com/user-attachments/assets/035142e0-a94e-4bfc-a492-09224e3cc81f" />

<img width="1792" height="1120" alt="grafana2" src="https://github.com/user-attachments/assets/84aacd35-4b20-44c7-81d5-72decb88a09c" />

### Deploy

```bash
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f helm/monitoring/prometheus-values.yaml

helm upgrade --install loki grafana/loki-stack \
  -n monitoring -f helm/monitoring/loki-values.yaml

helm upgrade --install tempo grafana/tempo \
  -n monitoring --set tempo.storage.trace.backend=local

kubectl apply -f k8s/monitoring/grafana-dashboard.yaml
```

### What is collected

**Metrics (Prometheus):** HTTP latency p50/p95/p99, error rate, CPU, memory, cache hit rate. Auto-discovered via pod annotations.

**Logs (Loki + Promtail):** All pod logs in real time. structlog JSON fields parsed: level, event, request_id, duration_ms.
Query: `{app="ai-platform"} | json | level="error"`

**Traces (OpenTelemetry + Tempo):** Every HTTP request traced end-to-end with spans for FastAPI handler, SQLAlchemy queries, and Groq API calls. Search in Grafana Explore > Tempo by service name `ai-platform`.

---

## Canary Deployments

Two versions run simultaneously sharing the same Kubernetes Service. Traffic is split proportionally by replica count.

```
Service: ai-platform
    |-- v1 stable  (llama-3.3-70b-versatile, 1 replica) ~50%
    +-- v2 canary  (llama-3.1-8b-instant,    1 replica) ~50%
```

### Deploy canary

```bash
helm install ai-platform-canary helm/ai-platform/ \
  -n ai-platform \
  -f helm/ai-platform/values.yaml \
  -f helm/ai-platform/values-canary.yaml
```

### Adjust traffic split

```bash
# 10% canary: 9 stable replicas + 1 canary replica
kubectl scale deployment ai-platform -n ai-platform --replicas=9
```

### Roll back canary

```bash
helm delete ai-platform-canary -n ai-platform
```

### Compare versions in Grafana

Filter PromQL by `version="v1"` vs `version="v2"` to compare latency and error rate before promoting.

---

## Auto-Scaling (HPA)

```yaml
autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 4
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

```bash
kubectl get hpa -n ai-platform
```

---

## Network Policies

Pod-to-pod traffic is restricted. Only the app can reach the databases.

| Source | Destination | Allowed |
|---|---|---|
| ai-platform | postgres:5432 | Yes |
| ai-platform | redis:6379 | Yes |
| ai-platform | qdrant:6333 | Yes |
| ai-platform | internet:443 | Yes (Groq API) |
| any other pod | postgres | No |
| any other pod | redis | No |
| any other pod | qdrant | No |

---

## Disaster Recovery

### Pod or node failure
Kubernetes self-heals automatically. HPA maintains minimum replicas. No action required.

### Database failure

A CronJob runs pg_dump every night at 02:00 UTC.

```bash
# Manual backup
kubectl create job manual-backup --from=cronjob/postgres-backup -n ai-platform

# Restore from backup
# Set BACKUP_FILE in postgres-restore.yaml then:
kubectl apply -f k8s/base/postgres-restore.yaml
kubectl logs -f job/postgres-restore -n ai-platform
```

### Full cluster loss

Everything is in Git. Rebuild in ~15 minutes:

```bash
# 1. Recreate infrastructure
cd terraform/
terraform init   # reconnects to S3 remote state
terraform apply  # recreates VPC, EKS, ECR

# 2. Connect kubectl
aws eks update-kubeconfig --region us-east-1 --name sentinel-eks-cluster

# 3. Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 4. Bootstrap -- ArgoCD restores everything from Git
kubectl apply -f k8s/argocd-app-of-apps.yaml

# 5. Restore database from latest S3 backup
kubectl apply -f k8s/base/postgres-restore.yaml
```

<img width="1792" height="1120" alt="app1" src="https://github.com/user-attachments/assets/4e2d3384-7438-4f14-b99a-15ae4cd6561c" />


<img width="1792" height="1120" alt="app2" src="https://github.com/user-attachments/assets/a391b517-55a6-4414-bb12-406d179cb73d" />



---

## Problems and Solutions

This documents every major problem encountered during this project and how it was solved.

---

### Problem 1: Terraform resources already existed outside state

**Error:**
```
Error: creating IAM Policy: EntityAlreadyExistsException
Error: creating ECR repository: RepositoryAlreadyExistsException
```

**Cause:** AWS resources had been created manually or by a previous run and were not tracked in Terraform state.

**Solution:** Import each existing resource into state:
```bash
terraform import aws_ecr_repository.app ai-platform
terraform import aws_iam_policy.alb_controller arn:aws:iam::502759712845:policy/AWSLoadBalancerControllerIAMPolicy
terraform import aws_subnet.public_b subnet-0b50c6db565e99fa0
```

**Lesson:** Always import existing resources before applying. Use `terraform state list` to audit what Terraform tracks.

---

### Problem 2: Terraform provider version locked to wrong constraint

**Error:**
```
locked provider hashicorp/aws 6.41.0 does not match constraints ~> 5.0
```

**Solution:** Updated `providers.tf` version constraint from `~> 5.0` to `~> 6.0` to match the locked version.

---

### Problem 3: EKS node group failed — instance type not Free Tier eligible

**Error:**
```
CREATE_FAILED: The specified instance type is not eligible for Free Tier.
```

**Cause:** `t3.medium` was used in `variables.tf` but the AWS account was restricted to Free Tier instance types.

**Solution:** Changed the default instance type to `t3.small` in `variables.tf`.

---

### Problem 4: ArgoCD pods all Pending — no nodes

**Cause:** ArgoCD was installed before the EKS node group finished provisioning. No worker nodes existed to schedule pods.

**Solution:** Waited for `terraform apply` to complete the node group first, then ArgoCD pods self-scheduled.

---

### Problem 5: argocd-applicationset-controller CrashLoopBackOff

**Error:**
```
failed to wait for applicationset caches to sync: timed out waiting for cache to be synced
```

**Cause:** The ApplicationSet CRD was not established when the controller started (race condition during installation).

**Solution:**
```bash
kubectl rollout restart deployment/argocd-applicationset-controller -n argocd
```

---

### Problem 6: ArgoCD web UI inaccessible — ELB instances OutOfService

**Cause:** The Classic ELB was created only in `us-east-1a` but EKS nodes were in `us-east-1b`. All instances showed OutOfService.

**Solution:** Attached both subnets to the ELB:
```bash
aws elb attach-load-balancer-to-subnets \
  --load-balancer-name <name> \
  --subnets subnet-0866... subnet-0b50...
```

Also patched ArgoCD server with `--insecure` flag to serve HTTP.

---

### Problem 7: App returning 500 — relation "conversations" does not exist

**Error:**
```
UndefinedTableError: relation "conversations" does not exist
```

**Cause:** PostgreSQL had no PersistentVolumeClaim. When the pod restarted it started fresh, losing all data including the migrated tables.

**Solution:**
1. Added a 5Gi EBS PVC to `k8s/base/postgres.yaml`
2. Re-ran the Alembic migration job against the now-persistent postgres

---

### Problem 8: PostgreSQL CrashLoopBackOff — lost+found conflict

**Error:**
```
initdb: directory "/var/lib/postgresql/data" exists but is not empty.
It contains a lost+found directory.
```

**Cause:** EBS volumes are formatted with ext4 which creates a `lost+found` directory at the root. PostgreSQL refuses to initialise in a non-empty directory.

**Solution:** Added `subPath: pgdata` to the volumeMount so PostgreSQL writes to a subdirectory instead of the volume root:
```yaml
volumeMounts:
  - name: postgres-data
    mountPath: /var/lib/postgresql/data
    subPath: pgdata
```

---

### Problem 9: PVC stuck in Pending — EBS CSI driver not installed

**Error:**
```
no persistent volumes available for this claim and no storage class is able to provision one
```

**Cause:** EKS does not install the EBS CSI driver by default. Without it, Kubernetes cannot provision EBS volumes for PVCs.

**Solution:** Created an IAM role for IRSA, then installed the EBS CSI driver as a managed EKS add-on:
```bash
aws eks create-addon \
  --cluster-name sentinel-eks-cluster \
  --addon-name aws-ebs-csi-driver \
  --service-account-role-arn arn:aws:iam::502759712845:role/ebs-csi-role
```

---

### Problem 10: Nodes at capacity — Too many pods

**Error:**
```
0/3 nodes are available: 3 Too many pods.
```

**Cause:** t3.small supports maximum 11 pods per node (ENI IP limit). After adding the EBS CSI DaemonSet, all remaining pod slots were filled.

**Solution:** Scaled the node group from 3 to 4 nodes:
```bash
aws eks update-nodegroup-config \
  --cluster-name sentinel-eks-cluster \
  --nodegroup-name sentinel-node-group \
  --scaling-config minSize=1,maxSize=4,desiredSize=4
```

Also cleaned up completed Job pods that were still occupying slots.

---

### Problem 11: Seed job 404 on Groq embeddings

**Error:**
```
httpx.HTTPStatusError: 404 Not Found /openai/v1/embeddings
```

**Cause:** The seed script tried to generate text embeddings via the Groq API, but Groq does not provide an embeddings endpoint.

**Solution:** Removed `LLM_API_KEY` from the seed job environment. Without it, the script detected no embedding provider and fell back to random vectors for initial seeding.

---

### Problem 12: Grafana LoadBalancer — all ELB instances OutOfService

**Cause:** The Classic ELB health check was probing the NodePort (e.g. 32129) but that port was not open in the EKS node security group.

**Solution:** Opened the full NodePort range permanently in the security group:
```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-055ddddd57e8ae017 \
  --protocol tcp \
  --port 30000-32767 \
  --cidr 0.0.0.0/0
```

---

### Problem 13: Grafana reverts to ClusterIP after every Helm upgrade

**Cause:** Every `helm upgrade` on the monitoring stack reset the Grafana Service back to ClusterIP (the chart default), breaking external access.

**Solution:** Created a separate `grafana-external` Service independent of the Helm release. Helm can never overwrite it:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: grafana-external
  namespace: monitoring
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-type: external
spec:
  type: LoadBalancer
  selector:
    app.kubernetes.io/name: grafana
  ports:
    - port: 80
      targetPort: 3000
```

---

### Problem 14: Helm upgrade — server-side apply field manager conflicts

**Error:**
```
conflict with "helm" using v1: .metadata.labels.helm.sh/chart
```

**Cause:** A previously failed Helm install left stale field manager metadata on cluster resources, causing conflicts on subsequent upgrades.

**Solution:**
```bash
# Clear conflicting field managers
kubectl patch svc monitoring-kube-state-metrics -n monitoring --type=json \
  -p='[{"op":"remove","path":"/metadata/managedFields"}]'

# Remove stuck pending-install secret
kubectl delete secret -n monitoring -l status=pending-upgrade,name=monitoring
```

---

### Problem 15: Canary Helm install blocked by existing Service and Ingress

**Error:**
```
Service "ai-platform" exists and cannot be imported into the current release
```

**Cause:** The Service and Ingress already existed (owned by ArgoCD). Helm could not claim ownership of them for the canary release.

**Solution:** Added `enabled` flags to the Service and Ingress Helm templates:
```yaml
# values-canary.yaml
service:
  enabled: false   # canary shares the ArgoCD-owned Service
ingress:
  enabled: false   # no separate ingress for canary
```

---

### Problem 16: NLB created as internal — not reachable from internet

**Cause:** The AWS Load Balancer Controller creates internal NLBs by default when intercepting `Service type: LoadBalancer` without annotations.

**Solution:** Added internet-facing annotation to the Service:
```yaml
annotations:
  service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
  service.beta.kubernetes.io/aws-load-balancer-type: external
```

Note: NLB annotations only apply at creation time. The Service must be deleted and recreated.

---

### Problem 17: Terraform state lost between sessions

**Cause:** Terraform state was stored locally in `terraform.tfstate`. If the file was lost, Terraform would try to recreate all existing resources.

**Solution:** Migrated state to an S3 backend with versioning and encryption:
```hcl
terraform {
  backend "s3" {
    bucket  = "my-terraform-state-bucket"
    key     = "sentinel/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
```
```bash
terraform init -migrate-state
```

---

## API Reference

| Method | Endpoint | Description |
|---|---|---|
| GET | /healthz | Liveness probe |
| GET | /readyz | Readiness probe (checks DB, Redis, Qdrant) |
| POST | /v1/chat | Send message, get AI response |
| GET | /v1/conversations | List all conversations |
| GET | /v1/conversations/{id}/messages | Get conversation history |
| PATCH | /v1/conversations/{id} | Rename conversation |
| DELETE | /v1/conversations/{id} | Delete conversation |
| POST | /v1/rag | Answer from FAQ knowledge base |
| POST | /v1/upload | Upload file for context |

### Chat example

```bash
curl -X POST http://<alb-url>/v1/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "How do I reset my password?"}'
```

```json
{
  "conversation_id": "01KP4PT2KFBXRPGKS6KATT8GYP",
  "message": "To reset your password, click Forgot Password on the login page...",
  "cached": false
}
```

---

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| APP_ENV | Environment (development or production) | development |
| APP_LOG_LEVEL | Log verbosity | info |
| LLM_API_KEY | Groq API key | required |
| LLM_BASE_URL | LLM provider base URL | https://api.groq.com/openai/v1 |
| LLM_MODEL | Model name | llama-3.3-70b-versatile |
| DATABASE_URL | PostgreSQL async connection string | localhost:5432 |
| REDIS_URL | Redis connection string | redis://localhost:6379/0 |
| QDRANT_HOST | Qdrant hostname | localhost |
| QDRANT_PORT | Qdrant port | 6333 |
| QDRANT_COLLECTION | Vector collection name | faq_documents |
| OTEL_EXPORTER_OTLP_ENDPOINT | Tempo gRPC endpoint | unset (tracing disabled) |

---

## Troubleshooting Quick Reference

```bash
# Check all pods
kubectl get pods -A

# App logs
kubectl logs -f deployment/ai-platform -n ai-platform

# ArgoCD sync status
kubectl get application -n argocd

# Force ArgoCD to re-sync
kubectl annotate application ai-platform -n argocd \
  argocd.argoproj.io/refresh=hard --overwrite

# Check HPA
kubectl get hpa -n ai-platform

# Check ELB health
aws elb describe-instance-health --load-balancer-name <name>

# Verify database tables exist
kubectl exec -n ai-platform $(kubectl get pod -n ai-platform -l app=postgres \
  -o jsonpath='{.items[0].metadata.name}') \
  -- psql -U aiplatform -d aiplatform -c "\dt"

# Manual database backup
kubectl create job manual-backup --from=cronjob/postgres-backup -n ai-platform

# Check Prometheus scrape targets
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
# Open: http://localhost:9090/targets
```

---

## License

MIT License

---

<div align="center">
Built with care · AWS EKS · Terraform · ArgoCD · 2026
</div>
