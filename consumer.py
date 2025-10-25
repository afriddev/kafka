from fastapi import FastAPI
from aiokafka import AIOKafkaConsumer
import asyncio, json, os
from fastapi.responses import HTMLResponse
from dotenv import load_dotenv

load_dotenv()
app = FastAPI()
messages = []

@app.on_event("startup")
async def startup():
    bootstrap = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092,localhost:9093")
    consumer = AIOKafkaConsumer("test-topic", bootstrap_servers=bootstrap, group_id="test-group")
    await consumer.start()
    asyncio.create_task(consume(consumer))

async def consume(consumer):
    async for msg in consumer:
        try:
            data = json.loads(msg.value.decode("utf-8"))
            messages.append(json.dumps(data, indent=2))
        except:
            messages.append(msg.value.decode("utf-8"))

@app.get("/", response_class=HTMLResponse)
async def ui():
    html = f"""
    <html>
    <head>
      <title>Kafka Consumer Dashboard</title>
      <style>
        body {{
          font-family: 'Segoe UI', sans-serif;
          background: #0e0e0e;
          color: #f5f5f5;
          padding: 20px;
        }}
        h1 {{ color: #00ff88; }}
        .msg-box {{
          background: #1e1e1e;
          border: 1px solid #333;
          padding: 10px;
          margin: 10px 0;
          border-radius: 8px;
          white-space: pre-wrap;
          font-family: monospace;
        }}
        .refresh {{
          position: fixed;
          top: 10px;
          right: 10px;
          color: #999;
          font-size: 12px;
        }}
      </style>
      <script>setTimeout(()=>location.reload(),5000)</script>
    </head>
    <body>
      <div class="refresh">Auto-refresh every 5s</div>
      <h1>Kafka Messages (Latest 10)</h1>
      {"".join(f"<div class='msg-box'>{m}</div>" for m in messages[-10:])}
    </body>
    </html>
    """
    return HTMLResponse(content=html)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)