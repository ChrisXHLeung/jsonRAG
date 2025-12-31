import 'dotenv/config';
import express from 'express';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import fileUpload from 'express-fileupload';
import pkg from 'express-openid-connect';
const { auth, requiresAuth } = pkg;
import { GRPC as Cerbos } from '@cerbos/grpc';

import { ChatOpenAI, OpenAIEmbeddings } from "@langchain/openai";
import { MemoryVectorStore } from "langchain/vectorstores/memory";
import { RetrievalQAChain } from "langchain/chains";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.json());
app.use(fileUpload());

const cerbos = new Cerbos(process.env.CERBOS_HOST, { tls: false });
const STORAGE_ROOT = path.join(__dirname, 'storage');
if (!fs.existsSync(STORAGE_ROOT)) fs.mkdirSync(STORAGE_ROOT);

const config = {
  authRequired: false,
  auth0Logout: true,
  idpLogout: true,
  secret: process.env.APP_SECRET,
  baseURL: process.env.AUTH0_AUDIENCE, 
  clientID: process.env.AUTH0_CLIENT_ID,
  clientSecret: process.env.AUTH0_CLIENT_SECRET,
  issuerBaseURL: `https://${process.env.AUTH0_DOMAIN}`,
  authorizationParams: {
    response_type: 'code',
    audience: process.env.AUTH0_AUDIENCE,
    scope: 'openid profile email'
  }
};

app.use(auth(config));

function getTenantId(user) {
  return user.email.split('@')[1];
}

function getTenantDir(tenantId) {
  const dir = path.join(STORAGE_ROOT, tenantId);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

async function checkPerm(user, resourceId, action) {
  const tenantId = getTenantId(user);
  const roleKey = `${process.env.AUTH0_AUDIENCE}roles`;
  const roles = user[roleKey] || user.roles || ['user'];
  const roleArray = Array.isArray(roles) ? roles : [roles];
  
  try {
    const decision = await cerbos.checkResource({
      principal: { 
        id: user.sub, 
        roles: roleArray,
        attr: { tenantId } 
      },
      resource: { 
        kind: 'json_file', 
        id: resourceId,
        attr: { tenantId }
      },
      actions: [action]
    });
    return decision.isAllowed(action);
  } catch (e) {
    console.error(e.message);
    return false;
  }
}

async function runRAG(tenantId, jsonFiles) {
  const tenantDir = getTenantDir(tenantId);
  const embeddings = new OpenAIEmbeddings({ openAIApiKey: process.env.OPENAI_API_KEY });
  const vectorStore = new MemoryVectorStore(embeddings);

  for (const file of jsonFiles) {
    const content = fs.readFileSync(path.join(tenantDir, file), 'utf-8');
    await vectorStore.addDocuments([{ pageContent: content, metadata: { file } }]);
  }

  const model = new ChatOpenAI({ modelName: 'gpt-4o', temperature: 0 });
  const chain = RetrievalQAChain.fromLLM(model, vectorStore.asRetriever());

  const summaries = [];
  for (const file of jsonFiles) {
    const res = await chain.invoke({ query: "Summarize this data concisely." });
    summaries.push({ file, summary: res.text || res.answer });
  }

  const summaryFile = `summary_${Date.now()}.json`;
  fs.writeFileSync(path.join(tenantDir, summaryFile), JSON.stringify(summaries, null, 2));
  return summaryFile;
}

app.get('/', requiresAuth(), async (req, res) => {
  try {
    const tenantId = getTenantId(req.oidc.user);
    const tenantDir = getTenantDir(tenantId);
    const allFiles = fs.readdirSync(tenantDir).filter(f => f.endsWith('.json'));
    
    const roleKey = `${process.env.AUTH0_AUDIENCE}roles`;
    const roles = req.oidc.user[roleKey] || ['user'];
    const roleArray = Array.isArray(roles) ? roles : [roles];

    let authorizedFiles = [];
    if (allFiles.length > 0) {
      const checkResult = await cerbos.checkResources({
        principal: { 
          id: req.oidc.user.sub, 
          roles: roleArray,
          attr: { tenantId }
        },
        resources: allFiles.map(file => ({
          resource: { 
            kind: 'json_file', 
            id: file,
            attr: { tenantId }
          },
          actions: ['read', 'update', 'delete']
        }))
      });

      authorizedFiles = allFiles.map(file => {
        const decision = checkResult.results.find(r => r.resource.id === file);
        return {
          name: file,
          canRead: decision?.actions.read === 'EFFECT_ALLOW',
          canUpdate: decision?.actions.update === 'EFFECT_ALLOW',
          canDelete: decision?.actions.delete === 'EFFECT_ALLOW'
        };
      }).filter(f => f.canRead);
    }

    const batchCheck = await cerbos.checkResource({
      principal: { 
        id: req.oidc.user.sub, 
        roles: roleArray,
        attr: { tenantId }
      },
      resource: { 
        kind: 'json_file', 
        id: 'system',
        attr: { tenantId }
      },
      actions: ['create', 'analyze']
    });

    res.render('index', {
      files: authorizedFiles,
      user: req.oidc.user,
      roles: roleArray,
      canCreate: batchCheck.isAllowed('create'),
      canAnalyze: batchCheck.isAllowed('analyze')
    });
  } catch (err) {
    res.status(500).send(err.message);
  }
});

app.post('/analyze', requiresAuth(), async (req, res) => {
  const tenantId = getTenantId(req.oidc.user);
  const isAllowed = await checkPerm(req.oidc.user, 'all_files', 'analyze');
  
  if (!isAllowed) {
    return res.status(403).send('Forbidden');
  }

  const tenantDir = getTenantDir(tenantId);
  const files = fs.readdirSync(tenantDir).filter(f => f.endsWith('.json') && !f.includes('summary'));
  try {
    await runRAG(tenantId, files);
    res.redirect('/');
  } catch (err) {
    res.status(500).send(err.message);
  }
});

app.get('/download/:name', requiresAuth(), async (req, res) => {
  const tenantId = getTenantId(req.oidc.user);
  const ok = await checkPerm(req.oidc.user, req.params.name, 'read');
  if (ok) {
    const filePath = path.join(getTenantDir(tenantId), req.params.name);
    if (fs.existsSync(filePath)) return res.download(filePath);
    return res.status(404).send('File missing');
  }
  res.status(403).send('Forbidden');
});

app.post('/upload', requiresAuth(), async (req, res) => {
  if (!req.files || !req.files.jsonFile) return res.status(400).send('No file');
  
  const tenantId = getTenantId(req.oidc.user);
  const tenantDir = getTenantDir(tenantId);
  const file = req.files.jsonFile;
  const filePath = path.join(tenantDir, file.name);
  const action = fs.existsSync(filePath) ? 'update' : 'create';

  if (await checkPerm(req.oidc.user, file.name, action)) {
    file.mv(filePath, err => {
      if (err) return res.status(500).send(err);
      res.redirect('/');
    });
  } else {
    res.status(403).send('Denied');
  }
});

app.get('/delete/:name', requiresAuth(), async (req, res) => {
  const tenantId = getTenantId(req.oidc.user);
  if (await checkPerm(req.oidc.user, req.params.name, 'delete')) {
    const filePath = path.join(getTenantDir(tenantId), req.params.name);
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    return res.redirect('/');
  }
  res.status(403).send('Denied');
});

app.listen(3000, () => console.log('Server running on 3000'));
