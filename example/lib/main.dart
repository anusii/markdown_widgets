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
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:markdown_widget_builder/markdown_widget_builder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: applicationName,
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
  bool _isLoadingConfig = true;
  Object? _configLoadError;

  StreamSubscription<FileSystemEvent>? _fileWatchSub;
  String _markdownContent = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // Load the config from assets.

      final config = await loadConfigFromAssets(
        onError: (msg) => _showErrorDialog(msg),
      );

      // Set the media path (if present) or fallback to assets.

      await loadMediaFiles(
        config.media.path,
        onError: (msg) => _showErrorDialog(msg),
      );

      // Load the markdown content (or fallback).

      final content = await loadMarkdownContent(
        config.markdown.path,
        onError: (msg) => _showErrorDialog(msg),
      );
      setState(() => _markdownContent = content);

      // Watch file changes (if local path is valid).

      final interpretedPath = await interpretPath(config.markdown.path);
      final file = File(interpretedPath);
      if (await file.exists()) {
        _fileWatchSub?.cancel();
        _fileWatchSub = watchFileChanges(
          interpretedPath,
          onFileContentChanged: (newContent) {
            setState(() => _markdownContent = newContent);
          },
        );
      }
    } catch (e) {
      setState(() => _configLoadError = e);
    } finally {
      setState(() => _isLoadingConfig = false);
    }
  }

  /// Show error dialogue.

  void _showErrorDialog(String message) {
    if (!mounted) return;
    debugPrint(message);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error Occurred'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _fileWatchSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If still loading config, show a loading indicator.

    if (_isLoadingConfig) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If loading config had an error, show an error message.

    if (_configLoadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Markdown Widgets Example')),
        body: Center(
          child: Text('Error: $_configLoadError'),
        ),
      );
    }

    // If config is successfully loaded, show main UI.

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
