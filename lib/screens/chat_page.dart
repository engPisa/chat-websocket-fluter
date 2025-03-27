import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:web_socket_client/web_socket_client.dart';
import 'package:image_picker/image_picker.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.name, required this.id})
      : super(key: key);

  final String name;
  final String id;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final socket = WebSocket(Uri.parse('ws://172.17.0.1:8765'));
  final List<types.Message> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  late types.User otherUser;
  late types.User me;

  @override
  void initState() {
    super.initState();
    me = types.User(id: widget.id, firstName: widget.name);

    socket.messages.listen((incomingMessage) {
      Map<String, dynamic> data = jsonDecode(incomingMessage);
      String id = data['id'];
      String type = data['type'];
      String nick = data['nick'] ?? id;

      if (id != me.id) {
        otherUser = types.User(id: id, firstName: nick);

        if (type == "text") {
          _addMessage(types.TextMessage(
            author: otherUser,
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: data['msg'],
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ));
        } else if (type == "image") {
          _addMessage(types.ImageMessage(
            author: otherUser,
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            uri: data['image'], // Base64 da imagem recebida
            name: "Imagem",
            size: 0, // Tamanho pode ser opcional
          ));
        }
      }
    }, onError: (error) {
      print("WebSocket error: $error");
    });
  }

  String randomString() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(255));
    return base64UrlEncode(values);
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _sendMessageCommon(String text) {
    final textMessage = types.TextMessage(
      author: me,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: randomString(),
      text: text,
    );

    var payload = {
      'id': me.id,
      'type': 'text',
      'msg': text,
      'nick': me.firstName,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    socket.send(json.encode(payload));
    _addMessage(textMessage);
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final imageMessage = types.ImageMessage(
        author: me,
        id: randomString(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        uri: base64Image,
        name: "Imagem",
        size: bytes.length,
      );

      var payload = {
        'id': me.id,
        'type': 'image',
        'image': base64Image,
        'nick': me.firstName,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      socket.send(json.encode(payload));
      _addMessage(imageMessage);
    }
  }

  void _handleSendPressed(types.PartialText message) {
    _sendMessageCommon(message.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Chat: ${widget.name}', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.image),
            onPressed: _sendImage, // Chama o método para enviar imagem
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Chat(
              messages: _messages,
              user: me,
              showUserAvatars: true,
              showUserNames: true,
              onSendPressed: _handleSendPressed,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    socket.close();
    super.dispose();
  }
}
