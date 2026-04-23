# AI Customer Support Platform — Production-Grade DevOps

<div align="center">

![CI Pipeline](https://github.com/glare247/AI-Customer-Support-Platform/actions/workflows/ci.yml/badge.svg)
![CD Pipeline](https://github.com/glare247/AI-Customer-Support-Platform/actions/workflows/cd.yml/badge.svg)
![Python](https://img.shields.io/badge/python-3.11+-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-green)
![Kubernetes](https://img.shields.io/badge/kubernetes-1.35-blue)
![Helm](https://img.shields.io/badge/helm-4.x-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**A production-ready AI customer support chatbot with full DevOps infrastructure**

[Overview](#overview) · [Architecture](#architecture) · [Tech Stack](#tech-stack) · [Quick Start](#quick-start) · [Kubernetes Deploy](#kubernetes-deployment) · [CI/CD](#cicd-pipeline) · [Monitoring](#monitoring) · [Team](#team)

</div>

---

## Overview

This project demonstrates how real companies operate AI systems in production. Instead of just building an AI model, the focus is on the **infrastructure around it** — deploying, scaling, monitoring, and continuously delivering an AI-powered customer support assistant.

The platform enables a SaaS company to:
- Answer customer questions using AI (Groq LLaMA 3.3 70B)
- Persist conversation history across sessions
- Cache repeated questions to reduce API costs
- Search a FAQ knowledge base using RAG (Retrieval Augmented Generation)
- Deploy reliably with zero downtime
- Monitor performance and catch failures in real time

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Layer                            │
│                    Browser / API Client                         │
└─────────────────────────┬───────────────────────────────────────┘
                          │ HTTPS
┌─────────────────────────▼───────────────────────────────────────┐
│                      Ingress Layer                              │
│                  NGINX Ingress Controller                       │
└──────────────┬──────────────────────────┬───────────────────────┘
               │ 90% stable               │ 10% canary
┌──────────────▼──────────┐  ┌────────────▼──────────────────────┐
│   Application Layer     │  │      Observability Layer          │
│   FastAPI (API v1)      │  │  Prometheus → Grafana             │
│   HPA Auto-scaling      │  │  Loki + Promtail (logs)           │
│   Helm managed          │  │  OpenTelemetry (traces)           │
└──────────────┬──────────┘  └───────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────────────┐
│                        Data Layer                               │
│  PostgreSQL          Redis              Qdrant                  │
│  (conversations)     (response cache)   (FAQ embeddings)        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     CI/CD + GitOps Layer                        │
│  GitHub Actions → ghcr.io → ArgoCD → Kubernetes                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                       Security Layer                            │
│  Kubernetes Secrets · RBAC · Image Pull Secrets · Non-root      │
└─────────────────────────────────────────────────────────────────┘
```

<img width="1280" height="714" alt="architecture sample" src="https://github.com/user-attachments/assets/f334beb4-b795-4de4-b9d0-c27391ae6d3d" />





---

## Tech Stack

### Application Layer
| Component | Technology | Purpose |
|---|---|---|
| API Gateway | FastAPI 0.115+ | REST API + WebSocket |
| AI Model | Groq (LLaMA 3.3 70B) | Chat completions |
| Database | PostgreSQL 16 | Conversation history |
| Cache | Redis 7 | Response caching |
| Vector Store | Qdrant | FAQ embeddings (RAG) |

### Infrastructure
| Component | Technology | Purpose |
|---|---|---|
| Containerization | Docker | App packaging |
| Orchestration | Kubernetes (kind/GKE) | Pod management |
| Package Manager | Helm 4 | K8s deployments |
| Local Cluster | kind | Development cluster |

### CI/CD & GitOps
| Component | Technology | Purpose |
|---|---|---|
| CI Pipeline | GitHub Actions | Lint, test, build, push |
| Container Registry | ghcr.io | Docker image storage |
| GitOps | ArgoCD | Auto-deploy on Git change |
| Pod Management | k9s | Terminal K8s dashboard |

### Observability
| Component | Technology | Purpose |
|---|---|---|
| Metrics | Prometheus | CPU, memory, latency |
| Dashboards | Grafana | Visual monitoring |
| Logs | Loki + Promtail | Centralized logging |
| Tracing | OpenTelemetry | Distributed traces |

---

## Project Structure

```
AI-Customer-Support-Platform/
│
├── src/
│   ├── ai_platform/              # FastAPI application
│   │   ├── api/
│   │   │   ├── chat.py           # POST /v1/chat
│   │   │   ├── conversations.py  # GET/PATCH/DELETE /v1/conversations
│   │   │   ├── health.py         # GET /healthz  GET /readyz
│   │   │   ├── rag.py            # POST /v1/rag
│   │   │   └── files.py          # POST /v1/files
│   │   ├── services/
│   │   │   ├── llm_client.py     # Groq API wrapper
│   │   │   ├── cache_service.py  # Redis caching
│   │   │   ├── conversation_service.py  # PostgreSQL ops
│   │   │   └── rag_service.py    # RAG pipeline
│   │   ├── db/
│   │   │   ├── alembic.ini       # Migration config
│   │   │   └── versions/         # Migration files
│   │   ├── models/               # SQLAlchemy models
│   │   ├── schemas/              # Pydantic schemas
│   │   ├── config.py             # App configuration
│   │   └── main.py               # App factory
│   │
│   ├── tests/                    # pytest test suite
│   │   ├── conftest.py           # Shared fixtures
│   │   ├── test_health.py
│   │   ├── test_chat_endpoint.py
│   │   ├── test_cache_service.py
│   │   └── test_llm_client.py
│   │
│   └── scripts/
│       └── seed_qdrant.py        # Load FAQ data
│
├── docker/
│   └── Dockerfile                # Multi-stage production build
│
├── helm/
│   └── ai-platform/              # Helm chart
│       ├── Chart.yaml
│       ├── values.yaml           # Configurable values
│       └── templates/
│           ├── deployment.yaml   # Rolling update config
│           ├── service.yaml
│           └── ingress.yaml
│
├── k8s/
│   ├── kind-config.yaml          # Local cluster config
│   ├── argocd-app.yaml           # ArgoCD Application
│   └── secret.yaml.example       # Secret template
│
├── .github/
│   └── workflows/
│       ├── ci.yml                # Lint → Test → Build → Push
│       └── cd.yml                # Update Helm values
│
├── docker-compose.yml            # Local dev services
├── pyproject.toml                # Python deps + tool config
└── README.md
```

---

## Quick Start

### Prerequisites

| Tool | Version | Install |
|---|---|---|
| Python | 3.11+ | [python.org](https://python.org) |
| Docker Desktop | Latest | [docker.com](https://docker.com) |
| Git | Any | [git-scm.com](https://git-scm.com) |

### Step 1 — Clone and configure

```bash
git clone https://github.com/glare247/AI-Customer-Support-Platform.git
cd AI-Customer-Support-Platform
```

```bash
cp .env.example .env
```

Open `.env` and set your Groq API key (free at [console.groq.com](https://console.groq.com/keys)):

```env
LLM_API_KEY=gsk_your_actual_key_here
```

### Step 2 — Start database services

```bash
docker compose up -d
```

Verify all 3 are running:

```bash
docker compose ps
# postgres, redis, qdrant all showing: running
```

### Step 3 — Set up Python environment

```bash
python3 -m venv .venv
source .venv/bin/activate    # macOS/Linux
# .venv\Scripts\activate     # Windows

pip install -e .
pip install -e ".[dev]"
pip install aiosqlite
```

### Step 4 — Run migrations and seed data

```bash
export PYTHONPATH=$PWD/src
alembic -c src/ai_platform/db/alembic.ini upgrade head
```

```bash
export $(cat .env | grep -v '#' | xargs)
python src/scripts/seed_qdrant.py
```

### Step 5 — Start the app

```bash
uvicorn ai_platform.main:app --host 0.0.0.0 --port 8000 --reload
```

### Step 6 — Verify everything works

```bash
# Is the app alive?
curl http://localhost:8000/healthz
# {"status":"ok"}

# Are all dependencies connected?
curl http://localhost:8000/readyz
# {"status":"ok","checks":{"database":"ok","redis":"ok","qdrant":"ok"}}

# Test the chat
curl -X POST http://localhost:8000/v1/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is your return policy?"}'
```

Open the chat UI at **http://localhost:8000**

### Step 7 — Run the tests

```bash
pytest src/tests/ -v
# 15 passed
```

---

## API Reference

### Health Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/healthz` | GET | Liveness probe — is the process alive? |
| `/readyz` | GET | Readiness probe — are all deps connected? |

### Chat Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/v1/chat` | POST | Send a message, get an AI response |
| `/v1/rag` | POST | Ask a question using FAQ knowledge base |
| `/v1/conversations` | GET | List all conversations |
| `/v1/conversations/{id}/messages` | GET | Get messages in a conversation |
| `/v1/conversations/{id}` | PATCH | Rename a conversation |
| `/v1/conversations/{id}` | DELETE | Delete a conversation |
| `/v1/files` | POST | Upload a file for context |

### Example: Chat request

```bash
curl -X POST http://localhost:8000/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "How do I reset my password?",
    "conversation_id": null
  }'
```

```json
{
  "conversation_id": "01KP4PT2KFBXRPGKS6KATT8GYP",
  "message": "To reset your password, click Forgot Password on the login page...",
  "cached": false
}
```

### Example: RAG request

```bash
curl -X POST http://localhost:8000/v1/rag \
  -H "Content-Type: application/json" \
  -d '{"question": "What is your return policy?", "top_k": 3}'
```

```json
{
  "answer": "Our return policy allows returns within 30 days...",
  "sources": ["faq/returns"],
  "cached": false
}
```

---

## Kubernetes Deployment

### Install required tools

```bash
# macOS
brew install kind kubectl helm k9s

# Verify
kind version && kubectl version --client && helm version && k9s version
```

### Create the cluster

```bash
kind create cluster --name ai-platform --config k8s/kind-config.yaml
```

### Install NGINX Ingress

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### Create namespace and secrets

```bash
kubectl create namespace ai-platform
```

```bash
kubectl create secret docker-registry ghcr-pull-secret \
  --namespace ai-platform \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_TOKEN
```

```bash
kubectl create secret generic ai-platform-secrets \
  --namespace ai-platform \
  --from-literal=LLM_API_KEY=your-groq-key \
  --from-literal=DATABASE_URL="postgresql+asyncpg://aiplatform:aiplatform@postgres:5432/aiplatform" \
  --from-literal=REDIS_URL="redis://redis:6379/0" \
  --from-literal=QDRANT_HOST="qdrant" \
  --from-literal=QDRANT_PORT="6333"
```

### Deploy services

```bash
# Deploy PostgreSQL, Redis, Qdrant inside the cluster
kubectl apply -f k8s/services.yaml
```

### Deploy the app

```bash
helm upgrade --install ai-platform helm/ai-platform/ \
  --namespace ai-platform \
  --wait
```

### Verify deployment

```bash
kubectl get pods -n ai-platform
# All pods showing: Running

kubectl port-forward svc/ai-platform -n ai-platform 9000:80 &
curl http://localhost:9000/healthz
# {"status":"ok"}
```

### Manage with k9s

```bash
k9s -n ai-platform
```

| Key | Action |
|---|---|
| `:pods` | View all pods |
| `:deployments` | View deployments |
| `:services` | View services |
| `l` | Stream pod logs |
| `d` | Describe resource |
| `ctrl+c` | Exit |

---

## CI/CD Pipeline

### How it works

```
git push origin main
        │
        ▼
┌───────────────────────────────────────┐
│          GitHub Actions CI            │
│  1. Lint (ruff) ──────── 8s           │
│  2. Test (pytest) ─────── 30s         │
│  3. Build Docker image ── 1m 12s      │
│  4. Push to ghcr.io                   │
│     Tags: sha-abc1234, main, latest   │
└─────────────────┬─────────────────────┘
                  │
                  ▼
┌───────────────────────────────────────┐
│          GitHub Actions CD            │
│  Updates values.yaml:                 │
│    image.tag: sha-abc1234             │
│  Commits to GitHub                    │
└─────────────────┬─────────────────────┘
                  │
                  ▼
┌───────────────────────────────────────┐
│              ArgoCD                   │
│  Detects values.yaml changed          │
│  Pulls new image from ghcr.io         │
│  Rolling update in Kubernetes         │
│  Zero downtime deployment             │
└───────────────────────────────────────┘
```

### Image tags

Every build produces 3 tags:

| Tag | Example | When |
|---|---|---|
| SHA | `sha-abc1234` | Every push — immutable |
| Branch | `main` | Every push to main |
| Latest | `latest` | Only on main branch |

### Rolling update strategy

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1        # spin up 1 extra pod during update
    maxUnavailable: 0  # never remove a pod until replacement is ready
```

Zero downtime — users never see an interruption during deployments.

---

## ArgoCD GitOps

### Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl wait --for=condition=Ready pods --all -n argocd --timeout=180s
```

### Access the UI

```bash
# Get admin password
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Port-forward
kubectl port-forward svc/argocd-server -n argocd 9090:443 &

# Open: https://localhost:9090
# Username: admin
```

### Register the application

```bash
kubectl apply -f k8s/argocd-app.yaml
```

### GitOps principles enforced

- **Auto-sync** — ArgoCD deploys automatically when Git changes
- **Self-heal** — any manual `kubectl` change is reverted within 3 minutes
- **Prune** — resources removed from Git are removed from the cluster
- **Git is truth** — the cluster always matches what is in GitHub

---

## Monitoring

### Install the stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

```bash
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword=admin123 \
  --wait --timeout=5m
```

```bash
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set promtail.enabled=true
```

### Access Grafana

```bash
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring &
# Open: http://localhost:3000
# Username: admin  Password: admin123
```

### Metrics tracked

| Metric | Description |
|---|---|
| API latency (p95) | 95th percentile response time |
| Error rate | Percentage of 4xx/5xx responses |
| CPU usage | Per pod CPU consumption |
| Memory usage | Per pod memory consumption |
| AI response time | Time for Groq to respond |
| Cache hit rate | Redis cache effectiveness |

### Prometheus auto-discovery

The app pods are automatically discovered by Prometheus because of these annotations in the Helm chart:

```yaml
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8000"
  prometheus.io/path: "/metrics"
```

---

## Rollback Procedures

### Option 1 — Helm rollback (fastest, 30 seconds)

```bash
helm history ai-platform -n ai-platform
helm rollback ai-platform -n ai-platform
```

### Option 2 — Git revert (GitOps way)

```bash
git revert HEAD
git push origin main
# ArgoCD detects the revert and rolls back automatically
```

### Option 3 — Force specific image tag

```bash
sed -i 's/  tag: .*/  tag: sha-previous/' helm/ai-platform/values.yaml
git add . && git commit -m "hotfix: revert to previous image"
git push origin main
```

---

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `APP_ENV` | Environment (development/production) | development |
| `APP_LOG_LEVEL` | Log level (debug/info/warning) | info |
| `LLM_API_KEY` | Groq API key | required |
| `LLM_BASE_URL` | LLM provider URL | https://api.groq.com/openai/v1 |
| `LLM_MODEL` | Model name | llama-3.3-70b-versatile |
| `DATABASE_URL` | PostgreSQL connection string | localhost:5432 |
| `REDIS_URL` | Redis connection string | redis://localhost:6379/0 |
| `QDRANT_HOST` | Qdrant host | localhost |
| `QDRANT_PORT` | Qdrant port | 6333 |
| `QDRANT_COLLECTION` | Vector collection name | faq_documents |

---

## Troubleshooting

### App not starting

```bash
# Check pod logs
kubectl logs -n ai-platform $(kubectl get pods -n ai-platform --no-headers | grep Running | awk '{print $1}')

# Check pod events
kubectl describe pod -n ai-platform $(kubectl get pods -n ai-platform --no-headers | awk '{print $1}')
```

### Database connection failed

```bash
# Verify postgres pod is running
kubectl get pods -n ai-platform | grep postgres

# Test connection from inside the cluster
kubectl exec -n ai-platform postgres-xxx -- psql -U aiplatform -d aiplatform -c "\dt"
```

### Image pull error

```bash
# Check if pull secret exists
kubectl get secret ghcr-pull-secret -n ai-platform

# Recreate if missing
kubectl create secret docker-registry ghcr-pull-secret \
  --namespace ai-platform \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_TOKEN
```

### ArgoCD showing degraded

```bash
# Force a fresh sync
kubectl rollout restart deployment/ai-platform -n ai-platform

# Check ArgoCD app status
kubectl get application ai-platform -n argocd
```

### Port already in use

```bash
# Find what is using the port
sudo lsof -i :8000

# Kill it
lsof -ti:8000 | xargs kill -9
```

---

## Team

| Member | Role | Responsibilities |
|---|---|---|
| **Umaru** | Infrastructure | Cloud architecture, IaC, platform setup |
| **Kabir** | CI/CD | GitHub Actions pipelines, image builds, versioning |
| **Abdul** | Monitoring | Prometheus, Grafana, Loki, alerting |
| **Kunle** | Application | App deployment, Helm charts, service config |

**Organization:** expandox-lab

---

## What is next — GCP + Terraform

The local setup using kind mirrors exactly what will run on GCP:

| Local (now) | GCP (next) |
|---|---|
| kind cluster | GKE cluster |
| Docker Compose postgres | Cloud SQL |
| Local Redis | Memorystore |
| Manual secret creation | Vault + External Secrets Operator |
| localhost | Real domain with TLS |

Terraform will provision all GCP resources as code — the same Helm charts and ArgoCD setup will deploy to GKE without any changes.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">
Built with expandox-lab · 2026
</div>
