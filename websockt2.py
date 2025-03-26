import asyncio
import websockets

clientes = set()

async def chat(websocket, path):
    clientes.add(websocket)
    try:
        async for message in websocket:
            mensagem_formatada = f"{message} from {id(websocket)}"
            for cliente in clientes:
                # Envia a mensagem formatada para todos os clientes conectados
                await cliente.send(mensagem_formatada)
    finally:
        clientes.remove(websocket)

start_server = websockets.serve(chat, "10.200.75.42", 8765)

asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
