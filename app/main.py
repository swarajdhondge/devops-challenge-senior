from datetime import datetime, timezone
from fastapi import FastAPI, Request
from mangum import Mangum

app = FastAPI(
    title="SimpleTimeService",
    description="Returns current timestamp and visitor IP",
    version="1.0.0"
)

@app.get("/", response_model=dict)
async def get_time_and_ip(request: Request) -> dict:
    forwarded_for = request.headers.get("x-forwarded-for", "")
    if forwarded_for:
        client_ip = forwarded_for.split(",")[0].strip()
    else:
        client_ip = request.client.host if request.client else "unknown"
    
    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "ip": client_ip
    }

handler = Mangum(app, lifespan="off")
