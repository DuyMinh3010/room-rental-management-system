import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import 'room_page.dart';

class VerifyPage extends StatefulWidget {
  final Map<String, String> account;
  const VerifyPage({super.key, required this.account});
  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final code = TextEditingController();
  Timer? timer;
  int seconds = 59;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds == 0) {
        t.cancel();
        return;
      }
      setState(() => seconds--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    code.dispose();
    super.dispose();
  }

  void _verify() {
    if (code.text.trim() != '123456') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mã thử nghiệm là 123456')));
      return;
    }
    profile.addAll(widget.account);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoomPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.mark_email_read_outlined, size: 64, color: blue),
          const SizedBox(height: 24),
          Text(
            'Nhập mã xác thực cho ${widget.account['phone'] ?? widget.account['email']}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: code,
            maxLength: 6,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 26, letterSpacing: 12),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '000000',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _verify, child: const Text('Xác thực')),
          TextButton(
            onPressed: seconds > 0
                ? null
                : () {
                    setState(() => seconds = 59);
                    _startTimer();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mã mẫu: 123456')),
                    );
                  },
            child: Text(
              seconds > 0
                  ? 'Gửi lại mã sau: 0:${seconds.toString().padLeft(2, '0')}'
                  : 'Gửi lại mã',
            ),
          ),
          const Text(
            'Chế độ học giao diện: nhập 123456. Chưa gửi SMS/email thật.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
