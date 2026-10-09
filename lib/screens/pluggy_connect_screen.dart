import 'package:flutter/material.dart';
import 'package:flutter_pluggy_connect/flutter_pluggy_connect.dart';

class PluggyConnectScreen extends StatefulWidget {
  const PluggyConnectScreen({super.key, required this.connectToken});

  final String connectToken;

  @override
  State<PluggyConnectScreen> createState() => _PluggyConnectScreenState();
}

class _PluggyConnectScreenState extends State<PluggyConnectScreen> {
  bool _finished = false;

  void _finish([String? itemId]) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pop(itemId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pluggy Bank Sandbox')),
    body: SafeArea(
      child: PluggyConnect(
        connectToken: widget.connectToken,
        includeSandbox: true,
        language: 'pt',
        onSuccess: (data) {
          final item = data is Map ? data['item'] : null;
          final itemId = item is Map ? item['id'] : null;
          if (itemId is String && itemId.isNotEmpty) _finish(itemId);
        },
        onError: (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível concluir a conexão Sandbox.'),
            ),
          );
        },
        onClose: _finish,
      ),
    ),
  );
}
