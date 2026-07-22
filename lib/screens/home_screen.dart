import 'package:flutter/material.dart';
import '../models/script.dart';
import '../services/db_service.dart';
import 'editor_screen.dart';
import 'prompter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DBService _db = DBService();
  List<ScriptModel> _scripts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scripts = await _db.getAllScripts();
    setState(() => _scripts = scripts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('আমার Teleprompter'),
      ),
      body: _scripts.isEmpty
          ? const Center(
              child: Text(
                'কোনো স্ক্রিপ্ট নেই।\n+ চেপে নতুন স্ক্রিপ্ট লেখো।',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _scripts.length,
              itemBuilder: (context, i) {
                final s = _scripts[i];
                return Card(
                  color: const Color(0xFF161616),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(s.title, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      s.language == 'bn' ? 'বাংলা' : 'English',
                      style: const TextStyle(color: Colors.white38),
                    ),
                    trailing: PopupMenuButton<String>(
                      color: const Color(0xFF222222),
                      onSelected: (v) async {
                        if (v == 'edit') {
                          await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => EditorScreen(script: s)));
                          _load();
                        } else if (v == 'delete') {
                          await _db.deleteScript(s.id!);
                          _load();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => PrompterScreen(script: s))),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.yellowAccent,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          await Navigator.push(
              context, MaterialPageRoute(builder: (_) => const EditorScreen()));
          _load();
        },
      ),
    );
  }
}
