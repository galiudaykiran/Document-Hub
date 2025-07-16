import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode) setThemeMode;

  const SettingsScreen({super.key, required this.setThemeMode});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.system;
  String _storageInfo = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _calculateStorageInfo();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    setState(() {
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    setState(() {
      _themeMode = mode;
    });
    widget.setThemeMode(mode);
  }

  Future<void> _calculateStorageInfo() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;
      final Directory documentFoldersDir =
          Directory('$appDocPath${Platform.pathSeparator}document_folders');

      if (!await documentFoldersDir.exists()) {
        setState(() {
          _storageInfo = '0 MB used';
        });
        return;
      }

      int totalBytes = 0;
      await for (var entity
          in documentFoldersDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }

      final double totalMB = totalBytes / (1024 * 1024);
      setState(() {
        _storageInfo = '${totalMB.toStringAsFixed(2)} MB used';
      });
    } catch (e) {
      setState(() {
        _storageInfo = 'Error calculating storage: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Theme Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            value: ThemeMode.system,
            groupValue: _themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                _saveThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light Theme'),
            value: ThemeMode.light,
            groupValue: _themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                _saveThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Theme'),
            value: ThemeMode.dark,
            groupValue: _themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                _saveThemeMode(value);
              }
            },
          ),
          const Divider(height: 32),
          Text(
            'Storage Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Total Storage Used'),
            subtitle: Text(_storageInfo),
            leading: const Icon(Icons.storage_outlined),
          ),
        ],
      ),
    );
  }
}