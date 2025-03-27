import asyncio
import websockets
import json
import base64

clientes = set()

async def chat(websocket, path):
    # Log quando um cliente se conecta
    cliente_id = id(websocket)
    print(f"Cliente conectado: {cliente_id}")
    clientes.add(websocket)
    
    try:
        async for message in websocket:
            # Verifica se é mensagem de texto ou imagem
            message_formatada = json.loads(message)

            tipo = {
                "text": lambda d: json.dumps({
                    "type": "text",
                    "message": d["message"]
                }),
                "image": lambda d: json.dumps({
                    "type": "image",
                    "image": d["image"]
                }),
            }

            # Obtém a função correta e executa, ou retorna erro
            mensagem_formatada = tipo.get(
                message_formatada["type"],
                lambda _: json.dumps({
                    "type": "error",
                    "message": "Tipo inválido"
                })
            )(message_formatada)

            print(f"Mensagem recebida: {mensagem_formatada}")

            # Envia a mensagem para todos os clientes conectados
            await asyncio.wait(*[cliente
                                   .send(mensagem_formatada) for cliente in clientes])

    except websockets.ConnectionClosed:
        print(f"Conexão perdida com o cliente: {cliente_id}")
    
    finally:
        clientes.remove(websocket)
        print(f"Cliente desconectado: {cliente_id}")

async def main():
    async with websockets.serve(chat, "172.17.0.1", 8765):
        print("🚀🚀 Servidor WebSocket iniciado em ws://172.17.0.1:8765")
        await asyncio.Future()  # Mantém o servidor rodando

asyncio.run(main())
