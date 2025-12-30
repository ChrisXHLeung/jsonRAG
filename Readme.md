# JSON File Manager with Cerbos Authorization & Multi-Model AI RAG Analysis

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-v18+-green.svg)](https://nodejs.org/)

## Project Overview

This open-source project demonstrates a production-ready approach to securing enterprise resources using the **PEP + PDP** pattern with **Cerbos** as the Policy Decision Point.

It implements a hybrid authorization model:
- **RBAC** via user roles from Auth0
- **ABAC** via derived roles, resource attributes, and conditions in Cerbos policies

Two categories of resources are protected:

1. **File resources** – Individual JSON files with per-file actions: `create`, `read`, `update`, `delete`

2. **AI model execution resources** – A multi-model, multi-stage RAG workflow involving several OpenAI models:
   - Dedicated embedding model (configurable via `OPENAI_EMBEDDING_MODEL`)
   - Analysis model used in the RetrievalQA chain (configurable via `OPENAI_MODEL_ANALYSIS`)
   - Summary generation model for final output (configurable via `OPENAI_MODEL_SUMMARY`)
   - The entire workflow is gated by a single `analyze` action, giving administrators full control over who can execute potentially expensive or sensitive multi-model AI operations.

The app starts as a simple JSON file manager and evolves into an **AI orchestration platform** that runs **multi-model Retrieval-Augmented Generation** across all stored files, producing aggregated summary reports.

## Key Features

- Auth0-based authentication
- Fine-grained, policy-as-code authorization via Cerbos PDP
- Per-file permissions + global control over multi-model AI execution
- Hybrid RBAC + ABAC with no application code changes required for new policies
- Dashboard showing only authorized files and actions
- One-click **Multi-Model AI Batch Analysis** (requires `analyze` permission):
  - Embeds file contents using the configured embedding model
  - Builds an in-memory vector store with LangChain
  - Runs RetrievalQA chain with the configured analysis model
  - Generates final summaries using the configured summary model
  - Saves results as a new timestamped `summary_*.json` file
- All RAG behavior tunable via environment variables (chunk size, overlap, top-k)

## Why This Project Matters

Enterprises need to secure both traditional data and modern AI workloads. This project shows how to:
- Treat multi-model AI pipelines as protected resources
- Separate concerns: file access vs. AI execution
- Optimize costs and performance by assigning different models to different stages
- Externalize all authorization logic to Cerbos policies

## Architecture Overview

```
User
  ↓
Auth0 Authentication
  ↓
Express.js (PEP)
  ↓
Cerbos PDP ←────────────────────────────┐
  ↓                                      │ Evaluates roles, attributes, actions
File Operations                          │ (including multi-model AI usage)
  ↓                                      │
Multi-Model RAG Pipeline                 │
  ├─ Embedding Model                     │
  ├─ Analysis Model (RetrievalQA)        │
  └─ Summary Model                       │
  ↓                                      │
Local Storage + LangChain                │
```

## Tech Stack

- Node.js + Express
- EJS templates
- Auth0 (`express-openid-connect`)
- Cerbos PDP (gRPC)
- express-fileupload
- LangChain.js
- OpenAI SDK (multiple configurable models)
- Local filesystem storage

## Getting Started

### Prerequisites

- Node.js ≥ 18
- Auth0 application
- OpenAI API key
- Running Cerbos instance

### Environment Variables

Create a `.env` file based on this template:

```dotenv
# Server
PORT=3000
BASE_URL=http://localhost:3000

# Auth0
AUTH0_DOMAIN=
AUTH0_CLIENT_ID=
AUTH0_CLIENT_SECRET=
AUTH0_AUDIENCE=

# Cerbos
CERBOS_HOST=

# Session
APP_SECRET=

# OpenAI
OPENAI_API_KEY=

# Models
OPENAI_MODEL_ANALYSIS=
OPENAI_MODEL_SUMMARY=
OPENAI_EMBEDDING_MODEL=
# Example values (uncomment to use):
#OPENAI_MODEL_ANALYSIS=gpt-4o-mini
#OPENAI_MODEL_SUMMARY=gpt-4o
#OPENAI_EMBEDDING_MODEL=text-embedding-3-large

# RAG
RAG_CHUNK_SIZE=
RAG_CHUNK_OVERLAP=
RAG_TOP_K=
# Example values (uncomment to use):
#RAG_CHUNK_SIZE=1024
#RAG_CHUNK_OVERLAP=128
#RAG_TOP_K=5
```

### Run Cerbos (Docker)

```bash
docker run --rm --name cerbos \
  -p 3592:3592 -p 3593:3593 \
  -v $(pwd)/policies:/policies \
  ghcr.io/cerbos/cerbos:latest server
```

### Install & Run

```bash
git clone https://github.com/yourusername/json-manager-cerbos-rag.git
cd json-manager-cerbos-rag
npm install
npm start
```

Open http://localhost:3000

## Cerbos Policies

The `policies/` directory contains examples covering:
- Role-based access
- Ownership and derived roles
- Department-based restrictions
- Protection of the `analyze` action for multi-model AI execution

## Contributing

Contributions are welcome, especially:
- Additional Cerbos policy examples
- Persistent vector store integrations
- Enhanced RAG configurations
- Support for other storage backends

Open an issue first for major changes.

## License

MIT License – see the [LICENSE](LICENSE) file for details.

---

**A practical example of securing files and multi-model AI workloads with modern policy-based authorization.**