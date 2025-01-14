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

import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:markdown_widget_builder/markdown_widget_builder.dart';
import 'package:markdown_widget_builder/src/constants/pkg.dart' as pkg;

/// A simple class to represent the structure:
/// { "path": "some/path", "type": "local/pod" }

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

/// Returns the path to 'config.json' placed in the same directory as the app
/// file.

String getConfigPathInSameDirAsApp() {
  final exePath = Platform.resolvedExecutable;
  final exeDir = p.dirname(exePath);
  final contentsDir = p.dirname(exeDir);
  final appDir = p.dirname(contentsDir);
  final outerDir = p.dirname(appDir);
  return p.join(outerDir, 'config.json');
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

/// A StatefulWidget that loads markdown content from an asset
/// and displays it using the MarkdownWidgetBuilder.

class MarkdownExamplePage extends StatefulWidget {
  const MarkdownExamplePage({super.key});

  @override
  State<MarkdownExamplePage> createState() => _MarkdownExamplePageState();
}

class _MarkdownExamplePageState extends State<MarkdownExamplePage> {
  late Future<Config> _configFuture;
  late String _absoluteConfigPath;
  StreamSubscription<FileSystemEvent>? _fileWatchSub;
  String _markdownContent = 'Loading...';

  @override
  void initState() {
    super.initState();

    // Store absolute config.json path.

    _absoluteConfigPath = getConfigPathInSameDirAsApp();
    _configFuture = _loadConfig(_absoluteConfigPath);
  }

  /// Loads config.json from the given absolute path.

  Future<Config> _loadConfig(String configPath) async {
    final file = File(configPath);
    if (!await file.exists()) {
      throw Exception('config.json not found at $configPath');
    }
    final content = await file.readAsString();
    final jsonMap = json.decode(content) as Map<String, dynamic>;
    return Config.fromJson(jsonMap);
  }

  /// A generic function to resolve any relative path.
  /// If 'filePath' is already absolute, return it directly.
  /// Otherwise, interpret it relative to config.json's parent directory.

  String _resolvePath(String filePath) {
    if (p.isAbsolute(filePath)) {
      return filePath;
    } else {
      final configDir = p.dirname(_absoluteConfigPath);
      return p.join(configDir, filePath);
    }
  }

  /// Loads the markdown from the file at [filePath], updates _markdownContent.

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

  /// Sets up a file watcher on the specified path, reloading the markdown
  /// content whenever the file is modified.

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

        // Resolve final absolute path for markdown file.

        final mdFilePath = _resolvePath(config.markdown.path);

        // Resolve final absolute path for media folder (or file).

        final mediaFilePath = _resolvePath(config.media.path);

        // Update the global mediaPath in pkg.dart with the resolved media path.

        pkg.setMediaPath(mediaFilePath);

        // Load markdown and set up watcher.

        _loadMarkdown(mdFilePath).then((_) => _setupFileWatcher(mdFilePath));

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
