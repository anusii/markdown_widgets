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

  // 1) If the whole "markdown" or "media" object is missing (null),
  //    we fallback to default path immediately (assets/surveys).
  // 2) If present but 'path' is an empty string, we keep it as "" here,
  //    so that the later logic can detect it and fallback.
  // 3) If present and non-empty but the file doesn't exist, we'll
  //    also do fallback in the code that loads the file.

  factory Config.fromJson(Map<String, dynamic> json) {
    // Attempt to read "markdown" object.

    final rawMarkdown = json['markdown'] as Map<String, dynamic>?;
    String markdownPath = '';
    String markdownType = 'local';

    if (rawMarkdown == null) {
      // If the "markdown" object is completely missing, fallback now.

      markdownPath = 'assets/surveys/surveys.md';
      markdownType = 'local';
    } else {
      // If it's present, read the fields. If "path" is empty string,
      // we keep it as empty, so that the loading function can handle fallback.

      markdownPath = (rawMarkdown['path'] as String?)?.trim() ?? '';
      markdownType = (rawMarkdown['type'] as String?)?.trim() ?? 'local';
    }

    // Attempt to read "media" object.

    final rawMedia = json['media'] as Map<String, dynamic>?;
    String mediaPath = '';
    String mediaType = 'local';

    if (rawMedia == null) {
      // If the "media" object is completely missing, fallback now.

      mediaPath = 'assets/surveys/media';
      mediaType = 'local';
    } else {
      mediaPath = (rawMedia['path'] as String?)?.trim() ?? '';
      mediaType = (rawMedia['type'] as String?)?.trim() ?? 'local';
    }

    return Config(
      markdown: PathType(path: markdownPath, type: markdownType),
      media: PathType(path: mediaPath, type: mediaType),
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
  bool _isLoadingConfig = true;
  Object? _configLoadError;

  StreamSubscription<FileSystemEvent>? _fileWatchSub;
  String _markdownContent = 'Loading...';
  bool _hasLoadedMarkdown = false;

  @override
  void initState() {
    super.initState();

    // Store absolute config.json path.

    _loadConfigFromAssets().then((config) {
      return _initMarkdownLoading(config);
    }).catchError((error) {
      _configLoadError = error;
    }).whenComplete(() {
      setState(() {
        _isLoadingConfig = false; // done loading config
      });
    });
  }

  /// Show error dialog.

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

  /// Loads config.json from 'assets/config.json'.

  Future<Config> _loadConfigFromAssets() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/config.json');
      final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
      return Config.fromJson(jsonMap);
    } catch (e) {
      // If there's any error (e.g. config.json not found or parse error),
      // return a default Config using the fallback paths.

      _showErrorDialog('Error loading config.json: $e');
      return Config(
        markdown: PathType(path: 'assets/surveys/surveys.md', type: 'local'),
        media: PathType(path: 'assets/surveys/media', type: 'local'),
      );
    }
  }

  /// Interprets rawPath.
  ///
  /// 1) absolute => local file.
  /// 2) relative => local file relative to [getAppDirectory()].
  /// 3) If the path is meant to be from Flutter assets, we do not use this
  /// method. Instead, we use rootBundle.loadString() directly.

  Future<String> _interpretPath(String rawPath) async {
    // 1) Absolute path.

    if (p.isAbsolute(rawPath)) {
      return rawPath;
    }

    // 2) Relative path.

    final appDir = await getAppDirectory();
    return p.join(appDir, rawPath);
  }

  /// Loads media files.
  ///
  /// If user provides a local/relative path for "media" that exists,
  /// then we set that as the media path. Otherwise, we fallback
  /// to the Flutter asset path "assets/surveys/media" (no file watch).

  Future<void> _loadMediaFiles(String rawMediaPath) async {
    // 1) If rawMediaPath is empty => fallback to assets.

    if (rawMediaPath.trim().isEmpty) {
      debugPrint(
          'Media path in config is empty. Fallback to "assets/surveys/media"');
      setMarkdownMediaPath('assets/surveys/media');
      return;
    }

    // 2) Otherwise, interpret the path as local.

    final interpretedMediaPath = await _interpretPath(rawMediaPath);
    final dir = Directory(interpretedMediaPath);

    if (await dir.exists()) {
      _showErrorDialog('Using local media directory: $interpretedMediaPath');
      setMarkdownMediaPath(interpretedMediaPath);
    } else {
      // Fallback to assets.

      _showErrorDialog(
          'Local media directory "$interpretedMediaPath" does not exist. '
          'Fallback to assets/surveys/media');
      setMarkdownMediaPath('assets/surveys/media');
    }
  }

  /// Loads markdown file.

  Future<void> _loadMarkdown(String rawPath) async {
    // 1) If config.json path is empty => fallback to assets.

    if (rawPath.trim().isEmpty) {
      debugPrint('Markdown path in config is empty. Fallback to '
          '"assets/surveys/surveys.md" from assets.');
      final assetContent =
          await rootBundle.loadString('assets/surveys/surveys.md');
      setState(() => _markdownContent = assetContent);
      return;
    }

    // 2) Check if user-provided path (absolute or relative) is valid.

    final interpretedPath = await _interpretPath(rawPath);
    final file = File(interpretedPath);

    if (!await file.exists()) {
      // If the file doesn't actually exist => fallback to assets.

      _showErrorDialog('Markdown file not found at "$interpretedPath". '
          'Fallback to assets/surveys/surveys.md');
      try {
        final assetContent =
            await rootBundle.loadString('assets/surveys/surveys.md');
        setState(() => _markdownContent = assetContent);
      } catch (e) {
        // If fallback also fails for some reason, show an error message.

        setState(() {
          _markdownContent = 'Error: Could not load fallback asset. $e';
        });
      }
      return;
    }

    // If we get here, it means the local file exists.

    final content = await file.readAsString();
    setState(() => _markdownContent = content);

    // Watch for changes in local file.
    // (We cannot watch changes in Flutter assets.)

    _fileWatchSub?.cancel();
    _fileWatchSub = _watchFileChanges(interpretedPath);
  }

  StreamSubscription<FileSystemEvent> _watchFileChanges(String path) {
    final parentDir = Directory(p.dirname(path));
    return parentDir.watch().listen((event) async {
      if (event.type == FileSystemEvent.modify && event.path == path) {
        final f = File(path);
        if (await f.exists()) {
          final updated = await f.readAsString();
          setState(() => _markdownContent = updated);
        }
      }
    });
  }

  /// Initialises the markdown loading process.

  void _initMarkdownLoading(Config config) async {
    if (_hasLoadedMarkdown) return;
    _hasLoadedMarkdown = true;

    // Loads media path with fallback.

    await _loadMediaFiles(config.media.path);

    // Loads markdown with fallback.

    await _loadMarkdown(config.markdown.path);
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
          child: Text('Error loading config.json: $_configLoadError'),
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
