/// An example of loading a markdown with 4 surveys and rendering them.
///
// Time-stamp: <Tuesday 2025-01-14 10:00:31 +1100 Tony Chen>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the MIT License (the "License").
///
/// License: https://choosealicense.com/licenses/mit/.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
///
/// Authors: Tony Chen

library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:markdown_widget_builder/markdown_widget_builder.dart'
    show MarkdownWidgetBuilder, setMarkdownMediaPath;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;

/// A simple class to represent the structure:
/// { "path": "file path", "type": "local/http, pod" }

class PathType {
  final String path;
  final String type;

  PathType({required this.path, required this.type});

  factory PathType.fromJson(Map<String, dynamic> json) {
    return PathType(
      path: json['path'] as String,
      type: json['type'] as String,
    );
  }
}

/// The Config class.

class Config {
  final PathType markdown;
  final PathType media;

  Config({required this.markdown, required this.media});

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      markdown: PathType.fromJson(json['markdown']),
      media: PathType.fromJson(json['media']),
    );
  }
}

void main() {
  runApp(const MyApp());
}

/// A simple Flutter application demonstrating how to use the
/// MarkdownWidgetBuilder from the markdown_widget_builder package.

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

/// Returns the directory where the app is running.

Future<String> getAppDirectory() async {
  final os = Platform.operatingSystem;
  final exePath = Platform.resolvedExecutable;

  if (os == 'macos') {
    final exeDir = p.dirname(exePath);
    final contentsDir = p.dirname(exeDir);
    final appDir = p.dirname(contentsDir);
    final outerDir = p.dirname(appDir);
    return outerDir;
  } else if (os == 'windows' || os == 'linux') {
    return p.dirname(exePath);
  } else if (os == 'android' || os == 'ios') {
    final docDir = await getApplicationDocumentsDirectory();
    return docDir.path;
  } else {
    return p.dirname(exePath);
  }
}

/// A StatefulWidget that loads markdown content from an asset
/// and displays it using the MarkdownWidgetBuilder.

class MarkdownExamplePage extends StatefulWidget {
  const MarkdownExamplePage({super.key});

  @override
  State<MarkdownExamplePage> createState() => _MarkdownExamplePageState();
}

class _MarkdownExamplePageState extends State<MarkdownExamplePage> {
  late Future<Config> _configFuture;
  StreamSubscription<FileSystemEvent>? _fileWatchSub;
  String _markdownContent = 'Loading...';

  // Guard to avoid re-loading markdown multiple times in build().

  bool _hasLoadedMarkdown = false;

  @override
  void initState() {
    super.initState();

    // Store absolute config.json path.

    _configFuture = _loadConfigFromAssets();
  }

  /// Loads config.json from 'assets/config.json'.

  Future<Config> _loadConfigFromAssets() async {
    final jsonStr = await rootBundle.loadString('assets/config.json');
    final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
    return Config.fromJson(jsonMap);
  }

  /// Interprets rawPath as:
  /// 1) absolute => local file.
  /// 2) relative => local file relative to [getAppDirectory()].

  Future<String> _interpretPath(String rawPath) async {
    // 1) Absolute path.

    if (p.isAbsolute(rawPath)) {
      return rawPath;
    }

    // 2) Relative path.

    final appDir = await getAppDirectory();
    return p.join(appDir, rawPath);
  }

  /// Loads the markdown from a local path.

  Future<void> _loadMarkdown(String rawPath) async {
    final interpretedPath = await _interpretPath(rawPath);

    // Cancel any old watcher.

    _fileWatchSub?.cancel();
    _fileWatchSub = null;

    final file = File(interpretedPath);
    if (await file.exists()) {
      final content = await file.readAsString();
      setState(() => _markdownContent = content);

      // Watch for changes.

      final parentDirectory = Directory(p.dirname(interpretedPath));
      _fileWatchSub = parentDirectory.watch().listen((event) async {
        if (event.type == FileSystemEvent.modify &&
            event.path == interpretedPath) {
          if (await file.exists()) {
            final updated = await file.readAsString();
            setState(() => _markdownContent = updated);
          }
        }
      });
    } else {
      setState(() {
        _markdownContent = 'Error: Markdown file not found at $interpretedPath';
      });
    }
  }

  /// Handle config after it's loaded, ensuring it is loaded only once.

  void _initMarkdownLoading(Config config) async {
    if (_hasLoadedMarkdown) return;
    _hasLoadedMarkdown = true;

    // Interpret & set media path.

    final resolvedMediaPath = await _interpretPath(config.media.path);
    setMarkdownMediaPath(resolvedMediaPath);

    // Load the markdown.

    await _loadMarkdown(config.markdown.path);
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
        // Still loading config.json...

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Error reading or parsing config.json...

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Markdown Widgets Example')),
            body: Center(
              child: Text('Error loading config.json: ${snapshot.error}'),
            ),
          );
        }

        // Config.json loaded successfully...

        final config = snapshot.data!;
        _initMarkdownLoading(config);

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

/// A StatelessWidget that displays detailed markdown content.
///
/// This page is navigated to when a menu item is selected in the
/// MarkdownWidgetBuilder.

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
