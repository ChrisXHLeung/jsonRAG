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
  },
  session: {
    rolling: true
  }
};

app.use(auth(config));

// Helper to write the manifest file
function saveManifest(tenantId, files) {
  const listPath = path.join(getTenantDir(tenantId), `list_${tenantId}.json`);
  fs.writeFileSync(listPath, JSON.stringify(files));
}

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
      principal: { id: user.sub, roles: roleArray, attr: { tenantId } },
      resource: { kind: 'json_file', id: resourceId, attr: { tenantId } },
      actions: [action]
    });
    return decision.isAllowed(action);
  } catch (e) {
    console.error(e.message);
    return false;
  }
}

// --- Main Route: Read ONLY the manifest file ---
app.get('/', requiresAuth(), async (req, res) => {
  try {
    const tenantId = getTenantId(req.oidc.user);
    const listPath = path.join(getTenantDir(tenantId), `list_${tenantId}.json`);
    
    let allFiles = [];
    // Only read the manifest file to avoid folder cache issues
    if (fs.existsSync(listPath)) {
      allFiles = JSON.parse(fs.readFileSync(listPath, 'utf8'));
    }

    const roleKey = `${process.env.AUTH0_AUDIENCE}roles`;
    const roles = req.oidc.user[roleKey] || ['user'];
    const roleArray = Array.isArray(roles) ? roles : [roles];

    let authorizedFiles = [];
    if (allFiles.length > 0) {
      const checkResult = await cerbos.checkResources({
        principal: { id: req.oidc.user.sub, roles: roleArray, attr: { tenantId } },
        resources: allFiles.map(file => ({
          resource: { kind: 'json_file', id: file, attr: { tenantId } },
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
      principal: { id: req.oidc.user.sub, roles: roleArray, attr: { tenantId } },
      resource: { kind: 'json_file', id: 'system', attr: { tenantId } },
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

app.post('/upload', requiresAuth(), async (req, res) => {
  if (!req.files || !req.files.jsonFile) return res.status(400).send('No file');
  const tenantId = getTenantId(req.oidc.user);
  const file = req.files.jsonFile;
  const filePath = path.join(getTenantDir(tenantId), file.name);
  const action = fs.existsSync(filePath) ? 'update' : 'create';

  if (await checkPerm(req.oidc.user, file.name, action)) {
    file.mv(filePath, err => {
      if (err) return res.status(500).send(err);
      
      // Update list
      const listPath = path.join(getTenantDir(tenantId), `list_${tenantId}.json`);
      let files = fs.existsSync(listPath) ? JSON.parse(fs.readFileSync(listPath, 'utf8')) : [];
      if (!files.includes(file.name)) {
        files.push(file.name);
        saveManifest(tenantId, files);
      }
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
    
    // Update list
    const listPath = path.join(getTenantDir(tenantId), `list_${tenantId}.json`);
    if (fs.existsSync(listPath)) {
      let files = JSON.parse(fs.readFileSync(listPath, 'utf8'));
      files = files.filter(f => f !== req.params.name);
      saveManifest(tenantId, files);
    }
    return res.redirect('/');
  }
  res.status(403).send('Denied');
});

app.listen(3000, () => console.log('Server running on 3000'));
