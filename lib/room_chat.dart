import 'package:flutter/material.dart';

class RoomChat extends StatelessWidget {
  final String userName;
  final String avatar;

  RoomChat({required this.userName, required this.avatar});

  final List<Map<String, String>> messages = [
    {'message': 'Hello! Mila How are you?', 'time': '09:25 AM', 'type': 'received'},
    {'message': 'You did your job well!', 'time': '09:25 AM', 'type': 'sent'},
    {'message': 'Have a great working week!!\nHope you like it', 'time': '09:26 AM', 'type': 'received'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(avatar),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Active now', style: TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: Container(
              color: Colors.pink.shade50,
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isSent = message['type'] == 'sent';
                  return Align(
                    alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSent ? Colors.green.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['message']!,
                            style: TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message['time']!,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.attach_file, color: Colors.grey),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Make a message',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Icon(Icons.send, color: Colors.pink),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
