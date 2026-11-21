import os
import time
import redis

redis_host = os.getenv("REDIS_HOST", "redis")
redis_port = int(os.getenv("REDIS_PORT", "6379"))
queue_name = os.getenv("QUEUE_NAME", "jobs")
processing_time = float(os.getenv("PROCESSING_TIME_SECONDS", "2"))

print(f"Worker started; Redis={redis_host}:{redis_port}; queue={queue_name}", flush=True)

while True:
    client = redis.Redis(host=redis_host, port=redis_port, decode_responses=True)
    try:
        job = client.brpop(queue_name, timeout=5)
        if job:
            print(f"Processing: {job[1]}", flush=True)
            time.sleep(processing_time)
            print(f"Completed: {job[1]}", flush=True)
    except redis.RedisError as error:
        print(f"Redis unavailable: {error}", flush=True)
        time.sleep(2)
