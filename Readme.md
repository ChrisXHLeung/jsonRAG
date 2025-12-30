# JSON File Manager with Cerbos Authorization & Multi-Model AI RAG Analysis

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-v18+-green.svg)](https://nodejs.org/)

## Project Overview

This open-source project demonstrates a production-ready **PEP + PDP** authorization pattern using **Cerbos** as the external Policy Decision Point.
![](https://raw.githubusercontent.com/ChrisXHLeung/jsonRAG/refs/heads/main/Diagram/totalDiagram.png)

It implements:
- **RBAC** via user roles from Auth0
- **ABAC** via derived roles, resource attributes, and conditions in Cerbos policies

Protected resources:
1. **File resources** – Individual JSON files with per-file actions (`create`, `read`, `update`, `delete`)
2. **AI model execution resources** – A configurable multi-model RAG workflow gated by a single `analyze` action, allowing control over expensive OpenAI calls across multiple models

![](https://raw.githubusercontent.com/ChrisXHLeung/jsonRAG/refs/heads/main/Diagram/workFlow.png)
The application is a secure JSON file manager with an integrated **multi-model Retrieval-Augmented Generation** pipeline that analyzes all accessible files and generates summary reports.

## Project Structure
![](https://raw.githubusercontent.com/ChrisXHLeung/jsonRAG/refs/heads/main/Diagram/sequenceDiagram.png)
```
/
├── PEP/                  # Main Node.js application (Policy Enforcement Point)
│   ├── package.json
│   ├── index.js          # Express server
│   ├── views/
│   ├── storage/          # Runtime directory for uploaded JSON files
│   ├── .env.example
│   └── ...
├── PDP/                  # Cerbos policy repository (Policy Decision Point)
│   ├── policies/
│   │   ├── resource_json_file.yaml
│   │   └── json_file_derived_roles.yaml
│   └── ...
└── README.md
```

The system requires both directories to function:
- **PEP** runs the web application
- **PDP** contains the Cerbos policies loaded by the Cerbos server

## Key Features

- Auth0 authentication
- Fine-grained authorization via Cerbos PDP
- Per-file permissions + protection of multi-model AI execution
- Hybrid RBAC + ABAC
- Dashboard with policy-filtered file list and actions
- One-click **Multi-Model AI Batch Analysis** (requires `analyze` permission):
  - Configurable embedding, analysis, and summary models
  - Tunable RAG parameters (chunk size, overlap, top-k)
  - Generates and saves a timestamped summary report

## Prerequisites

- Node.js ≥ 18
- Docker (recommended for running Cerbos)
- Auth0 tenant and application
- OpenAI API key with access to your chosen models

## Auth0 Configuration (Required for Roles)

To pass user roles to the application, configure a **Post-Login Action** in Auth0:

1. Go to **Actions > Library > Build Custom**
2. Create a new Action with the following code:

```javascript
exports.onExecutePostLogin = async (event, api) => {
  const namespace = 'https://your-app.example.com';  // Must match AUTH0_AUDIENCE or a custom namespace
  if (event.authorization?.roles) {
    api.idToken.setCustomClaim(`${namespace}/roles`, event.authorization.roles);
    api.accessToken.setCustomClaim(`${namespace}/roles`, event.authorization.roles);
  }
};
```

3. Deploy the Action and add it to the **Login** flow.

This ensures roles are included in the ID token and accessible to the application.

## Environment Variables

Copy `.env.example` to `.env` in the **PEP** directory and fill in values:

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
CERBOS_HOST=localhost:3593  # or your Cerbos endpoint

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

## Setup & Running

1. **Start Cerbos server** (loads policies from PDP directory):

```bash
cd PDP
docker run --rm --name cerbos \
  -p 3592:3592 -p 3593:3593 \
  -v $(pwd)/policies:/policies \
  ghcr.io/cerbos/cerbos:latest server --config=$(pwd)/conf.yaml
```


1. **Run the application**:

```bash
cd PEP
npm install
node index.js
```

3. Open http://localhost:3000 and log in via Auth0.

## Cerbos Policies

Policies in `PDP/policies/` demonstrate:
- Role-based access
- Ownership and derived roles
- Department restrictions
- Control of the `analyze` action for AI execution

## Contributing

Contributions welcome:
- Enhanced Cerbos policies
- Persistent vector stores
- Additional RAG features
- Storage backends

Open an issue for major changes.

## License

MIT License – see [LICENSE](LICENSE)

---

**A complete reference for PEP/PDP authorization protecting files and multi-model AI workloads.**