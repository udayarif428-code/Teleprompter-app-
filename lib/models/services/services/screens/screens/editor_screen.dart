import 'package:flutter/material.dart';
import '../models/script.dart';
import '../services/db_service.dart';

class EditorScreen extends StatefulWidget {
  final ScriptModel? script; // null = creating new
  const EditorScreen({super.key, this.script});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _language = 'bn';
  final DBService _db = DBService();

  @override
  void initState() {
    super.initState();
    if (widget.script != null) {
      _titleController.text = widget.script!.title;
      _contentController.text = widget.script!.content;
      _language = widget.script!.language;
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title আর script দুটোই দরকার')));
      return;
    }
    final model = ScriptModel(
      id: widget.script?.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      language: _language,
      updatedAt: DateTime.now(),
    );
    if (widget.script == null) {
      await _db.insertScript(model);
    } else {
      await _db.updateScript(model);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('স্ক্রিপ্ট এডিটর'),
        actions: [
          IconButton(icon: const Icon(Icons.check, color: Colors.yellowAccent), onPressed: _save),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'শিরোনাম / Title',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('প্রধান ভাষা:', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('বাংলা'),
                  selected: _language == 'bn',
                  onSelected: (_) => setState(() => _language = 'bn'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('English'),
                  selected: _language == 'en',
                  onSelected: (_) => setState(() => _language = 'en'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _contentController,
                style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'এখানে তোমার script লেখো বা paste করো...',
                  hintStyle: TextStyle(color: Colors.white30),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
