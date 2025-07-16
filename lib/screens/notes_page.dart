import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gallery_app/models/notes.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesPage extends StatefulWidget {
  final String folderPath;

  const NotesPage({super.key, required this.folderPath});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late TextEditingController _notesController;
  FolderNotes? _folderNotes;
  bool _isEditing = true;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadNotes();
  }

  @override
  void dispose() {
    _saveNotes(); // Auto-save when the page is disposed
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString('folder_notes_${widget.folderPath}');
    if (notesJson != null) {
      _folderNotes = FolderNotes.fromMap(jsonDecode(notesJson));
      _notesController.text = _folderNotes!.notesContent;
    } else {
      _folderNotes = FolderNotes(folderPath: widget.folderPath);
    }
    setState(() {});
  }

  Future<void> _saveNotes({bool showSnackBar = false}) async {
    final prefs = await SharedPreferences.getInstance();
    _folderNotes!.notesContent = _notesController.text;
    _folderNotes!.lastEdited = DateTime.now(); // Update last edited timestamp
    await prefs.setString(
        'folder_notes_${widget.folderPath}', jsonEncode(_folderNotes!.toMap()));
    if (showSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes saved!')),
      );
    }
  }

  Future<void> _clearNotes() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Notes'),
        content: const Text(
            'Are you sure you want to clear all notes? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _notesController.clear();
        _folderNotes!.notesContent = '';
        _folderNotes!.lastEdited = null; // Clear timestamp when notes are cleared
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('folder_notes_${widget.folderPath}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes cleared!')),
      );
    }
  }

  Future<void> _shareNotes() async {
    if (_notesController.text.isNotEmpty) {
      await Share.share(_notesController.text,
          subject: 'Notes for ${widget.folderPath.split('/').last}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No notes to share!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Notes' : 'View Notes'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save_outlined),
              onPressed: () {
                _saveNotes(showSnackBar: true); // Explicitly save with SnackBar
              },
              tooltip: 'Save Notes',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.clear_all_outlined),
              onPressed: _clearNotes,
              tooltip: 'Clear Notes',
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareNotes,
          ),
          IconButton(
            icon: Icon(_isEditing ? Icons.visibility_outlined : Icons.edit_outlined),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _saveNotes(); // Auto-save when switching to view mode
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _isEditing
                  ? TextField(
                      controller: _notesController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: '''Write your notes here...''',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: MarkdownBody(
                            data: _notesController.text.isEmpty
                                ? 'No notes yet. Tap the edit icon to add some!'
                                : _notesController.text,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                          ),
                        ),
                        if (_folderNotes?.lastEdited != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Last edited: ${_folderNotes!.lastEdited!.toLocal().toString().split('.').first}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}