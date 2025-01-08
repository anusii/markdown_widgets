import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:markdown_widget_builder/markdown_widget_builder.dart';

/// A simple Config class to parse "config.json".
class Config {
  final String path;
  final String type;

  Config({required this.path, required this.type});

  factory Config.fromJson(Map<String, dynamic> json) {
    final mdPath = json['md_path'] as Map<String, dynamic>;
    return Config(
      path: mdPath['path'] as String,
      type: mdPath['type'] as String,
    );
  }
}

/// Returns the path to config.json placed in the same directory as the .app file.
String getConfigPathInSameDirAsApp() {
  final exePath = Platform.resolvedExecutable;
  final exeDir = p.dirname(exePath);
  final contentsDir = p.dirname(exeDir);
  final appDir = p.dirname(contentsDir);
  final outerDir = p.dirname(appDir);
  // "config.json" is in the same directory as MyApp.app
  return p.join(outerDir, 'config.json');
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Markdown Widgets Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MarkdownExamplePage(),
    );
  }
}

class MarkdownExamplePage extends StatefulWidget {
  const MarkdownExamplePage({super.key});

  @override
  State<MarkdownExamplePage> createState() => _MarkdownExamplePageState();
}

class _MarkdownExamplePageState extends State<MarkdownExamplePage> {
  late Future<Config> _configFuture;
  StreamSubscription<FileSystemEvent>? _fileWatchSub;
  String _markdownContent = 'Loading...';

  @override
  void initState() {
    super.initState();
    // [CHANGED] Use our function to get config.json path.
    final configPath = getConfigPathInSameDirAsApp();
    _configFuture = _loadConfig(configPath);
  }

  Future<Config> _loadConfig(String configPath) async {
    final file = File(configPath);
    if (!await file.exists()) {
      throw Exception('config.json not found at $configPath');
    }
    final content = await file.readAsString();
    final jsonMap = json.decode(content) as Map<String, dynamic>;
    return Config.fromJson(jsonMap);
  }

  Future<void> _loadMarkdown(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final mdContent = await file.readAsString();
      setState(() {
        _markdownContent = mdContent;
      });
    } else {
      setState(() {
        _markdownContent = 'Error: Markdown file not found at $filePath';
      });
    }
  }

  void _setupFileWatcher(String filePath) async {
    final file = File(filePath);
    if (!(await file.exists())) return;
    _fileWatchSub = file.watch().listen((event) async {
      if (event.type == FileSystemEvent.modify) {
        final updatedContent = await file.readAsString();
        setState(() {
          _markdownContent = updatedContent;
        });
      }
    });
  }

  @override
  void dispose() {
    _fileWatchSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Config>(
      future: _configFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Markdown Widgets Example')),
            body: Center(
              child: Text('Error loading config.json: ${snapshot.error}'),
            ),
          );
        }

        final config = snapshot.data!;
        // Load and watch the markdown file
        _loadMarkdown(config.path).then((_) => _setupFileWatcher(config.path));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Markdown Widgets Example'),
          ),
          body: SingleChildScrollView(
            child: MarkdownWidgetBuilder(
              content: _markdownContent,
              title: 'Sample Markdown',
              onMenuItemSelected: (selectedTitle, selectedContent) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MarkdownDetailPage(
                      title: selectedTitle,
                      content: selectedContent,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class MarkdownDetailPage extends StatelessWidget {
  final String title;
  final String content;

  const MarkdownDetailPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: MarkdownWidgetBuilder(
          content: content,
          title: title,
          onMenuItemSelected: (selectedTitle, selectedContent) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarkdownDetailPage(
                  title: selectedTitle,
                  content: selectedContent,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
