import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:sonamobi/util/log_store.dart';

class LogDisplayPage extends ConsumerStatefulWidget {
  const LogDisplayPage({super.key});

  @override
  ConsumerState<LogDisplayPage> createState() => _LogDisplayPageState();
}

class _LogDisplayPageState extends ConsumerState<LogDisplayPage> {
  bool sentMessage = false;
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.jumpTo(_controller.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('System Log')),
      body: SingleChildScrollView(
        controller: _controller,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SelectableText(logStore.last(100).join('\n')),
        ),
      ),
    );
  }
}
