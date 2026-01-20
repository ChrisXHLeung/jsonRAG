import subprocess
import logging
import os
from fastapi import FastAPI, HTTPException, Header, Depends
from typing import Optional

# Logger Configuration
LOG_FILE = "/var/log/webhook_api.log"
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)

app = FastAPI()

# Security Token
API_KEY_CREDIT = " "#"your_api_key_here"

# Mapping IDs to script paths
SCRIPT_MAP = {
    "1": "/opt/init/jsonRAGReBuild1.sh",
    "2": "/opt/init/jsonRAGReBuild2.sh"
}

def verify_api_key(x_api_key: Optional[str] = Header(None)):
    if x_api_key != API_KEY_CREDIT:
        logging.warning(f"Unauthorized access attempt. Key provided: {x_api_key}")
        raise HTTPException(status_code=403, detail="Invalid API Key")
    return x_api_key

@app.post("/api/jsonRAGReBuild/{script_id}")
async def rebuild_rag(script_id: str, api_key: str = Depends(verify_api_key)):
    # Validate if the requested script ID exists
    if script_id not in SCRIPT_MAP:
        logging.error(f"Invalid script ID requested: {script_id}")
        raise HTTPException(status_code=404, detail=f"Script ID {script_id} not found. Valid IDs: {list(SCRIPT_MAP.keys())}")

    script_path = SCRIPT_MAP[script_id]
    output_lines = []

    logging.info(f"API Request received for Node {script_id}. Executing: {script_path}")

    try:
        # Check if file exists before running
        if not os.path.exists(script_path):
            raise FileNotFoundError(f"Script file not found at {script_path}")

        process = subprocess.Popen(
            ["/bin/bash", script_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            universal_newlines=True
        )

        # Read output line by line
        if process.stdout:
            for line in iter(process.stdout.readline, ""):
                clean_line = line.strip()
                if clean_line:
                    logging.info(f"[SCRIPT {script_id}]: {clean_line}")
                    output_lines.append(clean_line)
            process.stdout.close()

        return_code = process.wait()

        status = "success" if return_code == 0 else "error"
        if return_code == 0:
            logging.info(f"Task {script_id} finished successfully")
        else:
            logging.error(f"Task {script_id} failed with code {return_code}")

        return {
            "node": script_id,
            "status": status,
            "exit_code": return_code,
            "detail": output_lines
        }

    except Exception as e:
        logging.error(f"Internal System Error executing script {script_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)