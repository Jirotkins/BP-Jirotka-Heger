import asyncio
import json

class SSEManager:
    """
    Jednoduchý in-memory Pub/Sub manager pro SSE (Server-Sent Events).
    V budoucnu (při více Docker kontejnerech) lze nahradit za Redis Pub/Sub.
    """
    def __init__(self):
        self.listeners = {} # dict mapující channel_id na seznam asyncio.Queue
        self.loop = None

    def _get_loop(self):
        if self.loop is None:
            self.loop = asyncio.get_running_loop()
        return self.loop

    async def subscribe(self, channel_id: str):
        queue = asyncio.Queue()
        if channel_id not in self.listeners:
            self.listeners[channel_id] = []
        self.listeners[channel_id].append(queue)
        
        try:
            while True:
                data = await queue.get()
                # sse-starlette očekává yield dictionary s klíčem "data" a volitelně "event"
                yield {"data": json.dumps(data)}
        except asyncio.CancelledError:
            pass
        finally:
            if channel_id in self.listeners and queue in self.listeners[channel_id]:
                self.listeners[channel_id].remove(queue)
                if not self.listeners[channel_id]:
                    del self.listeners[channel_id]

    async def publish(self, channel_id: str, data: dict):
        if channel_id in self.listeners:
            for queue in self.listeners[channel_id]:
                await queue.put(data)

    def sync_publish(self, channel_id: str, data: dict):
        """
        Pomocná metoda pro publikování ze synchronních funkcí (def), 
        ve kterých běžně probíhají databázové transakce.
        """
        loop = self._get_loop()
        asyncio.run_coroutine_threadsafe(self.publish(channel_id, data), loop)

# Globální instance
sse_manager = SSEManager()
