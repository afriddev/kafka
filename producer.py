from fastapi import FastAPI, Form
from aiokafka import AIOKafkaProducer
from fastapi.responses import HTMLResponse
import json, os
from dotenv import load_dotenv

load_dotenv()
app = FastAPI()
producer = None

@app.on_event("startup")
async def startup():
    global producer
    bootstrap = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092,localhost:9093")
    producer = AIOKafkaProducer(bootstrap_servers=bootstrap)
    await producer.start()

@app.on_event("shutdown")
async def shutdown():
    await producer.stop()

@app.get("/", response_class=HTMLResponse)
async def ui():
    return """
    <html>
    <head>
      <title>Kafka Producer Dashboard</title>
      <style>
        body { font-family: 'Segoe UI', sans-serif; background: #0f111a; color: #e0e0e0; margin: 0; padding: 40px; }
        .container { max-width: 700px; margin: auto; background: #1a1c24; padding: 25px 40px; border-radius: 12px; box-shadow: 0 0 20px #000; }
        h2 { color: #00ff88; margin-bottom: 20px; text-align:center; }
        label { color: #ccc; font-size: 15px; }
        input, textarea { width: 100%; margin: 8px 0 15px 0; padding: 10px; border: none; border-radius: 6px; background: #222; color: #0f0; font-size: 15px; }
        button { background: #00ff88; color: #000; border: none; padding: 10px 20px; border-radius: 8px; cursor: pointer; font-weight: bold; font-size: 16px; }
        button:hover { background: #00cc66; }
        .status { margin-top: 15px; padding: 10px; border-radius: 8px; background: #111; color: #0f0; font-family: monospace; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>Kafka Producer Manager</h2>
        <form id="msgForm">
          <label>Key (optional)</label>
          <input type="text" id="key" placeholder="message-key">
          <label>Message (JSON)</label>
          <textarea id="message" rows="6" placeholder='{"user":"john","action":"login"}'></textarea>
          <button type="submit">Send Message</button>
        </form>
        <div id="status" class="status" style="display:none;"></div>
      </div>
      <script>
        const form = document.getElementById("msgForm");
        form.addEventListener("submit", async (e) => {
          e.preventDefault();
          const key = document.getElementById("key").value;
          const message = document.getElementById("message").value;
          const statusBox = document.getElementById("status");
          try {
            const res = await fetch("/publish", {
              method: "POST",
              headers: { "Content-Type": "application/x-www-form-urlencoded" },
              body: new URLSearchParams({ key, message })
            });
            const data = await res.json();
            statusBox.style.display = "block";
            statusBox.style.color = data.error ? "#f33" : "#0f0";
            statusBox.textContent = data.error ? "❌ " + data.error : "✅ Message sent: " + JSON.stringify(data.message);
          } catch (err) {
            statusBox.style.display = "block";
            statusBox.style.color = "#f33";
            statusBox.textContent = "❌ " + err;
          }
        });
      </script>
    </body>
    </html>
    """

@app.post("/publish")
async def publish(key: str = Form(""), message: str = Form(...)):
    try:
        data = json.dumps(json.loads(message)).encode("utf-8")
        await producer.send("test-topic", value=data, key=key.encode() if key else None)
        return {"status": "sent", "message": json.loads(message)}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
