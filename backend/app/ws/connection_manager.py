import json
from typing import Dict, Any
from fastapi import WebSocket

class ConnectionManager:
    def __init__(self):
        # Menyimpan mapping antara user_id dan list of active WebSocket connections
        self.active_connections: Dict[str, list[WebSocket]] = {}
        self.loop = None

    async def connect(self, websocket: WebSocket, user_id: str):
        import asyncio
        if self.loop is None:
            self.loop = asyncio.get_running_loop()
            
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)

    def disconnect(self, websocket: WebSocket, user_id: str):
        if user_id in self.active_connections:
            if websocket in self.active_connections[user_id]:
                self.active_connections[user_id].remove(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

    async def send_personal_message(self, message: Dict[str, Any], user_id: str):
        if user_id in self.active_connections:
            for connection in self.active_connections[user_id]:
                try:
                    await connection.send_text(json.dumps(message))
                except Exception:
                    pass

    async def broadcast(self, message: Dict[str, Any]):
        for user_connections in self.active_connections.values():
            for connection in user_connections:
                try:
                    await connection.send_text(json.dumps(message))
                except Exception:
                    pass

    def send_personal_message_sync(self, message: Dict[str, Any], user_id: str):
        import asyncio
        if self.loop is not None and self.loop.is_running():
            asyncio.run_coroutine_threadsafe(self.send_personal_message(message, user_id), self.loop)

# Singleton instance
manager = ConnectionManager()
