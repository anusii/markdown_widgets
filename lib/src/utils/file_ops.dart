library file_ops;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;

import 'package:markdown_widget_builder/markdown_widget_builder.dart'
    show setMarkdownMediaPath;
import 'package:markdown_widget_builder/src/constants/pkg.dart'
    show defaultConfigFile, mdPath, mediaPath;

/// Structure of config.json.

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

/// Parse the data from config.json.

class Config {
  final PathType markdown;
  final PathType media;

  Config({required this.markdown, required this.media});

  factory Config.fromJson(Map<String, dynamic> json) {
    // Read the markdown configuration.

    final rawMarkdown = json['markdown'] as Map<String, dynamic>?;
    String markdownPath = '';
    String markdownType = 'local';

    if (rawMarkdown == null) {
      // If "markdown" is missing, use the default.

      markdownPath = mdPath;
      markdownType = 'local';
    } else {
      markdownPath = (rawMarkdown['path'] as String?)?.trim() ?? '';
      markdownType = (rawMarkdown['type'] as String?)?.trim() ?? 'local';
    }

    // Read the media configuration.

    final rawMedia = json['media'] as Map<String, dynamic>?;
    String mediaPathLocal = '';
    String mediaType = 'local';

    if (rawMedia == null) {
      mediaPathLocal = mediaPath;
      mediaType = 'local';
    } else {
      mediaPathLocal = (rawMedia['path'] as String?)?.trim() ?? '';
      mediaType = (rawMedia['type'] as String?)?.trim() ?? 'local';
    }

    return Config(
      markdown: PathType(path: markdownPath, type: markdownType),
      media: PathType(path: mediaPathLocal, type: mediaType),
    );
  }
}

/// Returns the executable directory (or application directory) on different
/// platforms.

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

/// If the path is relative, concatenate it with the app directory; if it's
/// absolute, return it as is.

Future<String> interpretPath(String rawPath) async {
  String trimmed = rawPath;
  while (trimmed.endsWith('/') || trimmed.endsWith('\\')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }

  if (p.isAbsolute(trimmed)) {
    return p.normalize(trimmed);
  }
  final appDir = await getAppDirectory();
  return p.normalize(p.join(appDir, trimmed));
}

/// Returns a Config object; if an error occurs, returns a Config with default.

Future<Config> loadConfigFromAssets({
  String configAssetPath = defaultConfigFile,
  Function(String)? onError,
}) async {
  try {
    final jsonStr = await rootBundle.loadString(configAssetPath);
    final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
    return Config.fromJson(jsonMap);
  } catch (e) {
    onError?.call('Error loading $configAssetPath: $e');

    // Construct a Config with default paths when an error occurs.

    return Config(
      markdown: PathType(path: mdPath, type: 'local'),
      media: PathType(path: mediaPath, type: 'local'),
    );
  }
}

/// Load media files from the local directory; if the directory does not exist,
/// fallback to the default media path.

Future<void> loadMediaFiles(
  String rawMediaPath, {
  Function(String)? onError,
}) async {
  if (rawMediaPath.trim().isEmpty) {
    // If the path is empty, fallback to assets.

    // onError?.call(
    //     'Media path is empty, fallback to $mdPath from assets.'
    // );

    setMarkdownMediaPath(mediaPath);
    return;
  }

  final interpretedMediaPath = await interpretPath(rawMediaPath);
  Directory dir = Directory(interpretedMediaPath);

  if (!await dir.exists()) {
    // If the media directory does not exist, fallback to the default.

    onError?.call('Media directory not found: $interpretedMediaPath. '
        'Fallback to default: $mediaPath');
    setMarkdownMediaPath(mediaPath);
  } else {
    // Otherwise, use this local path.

    setMarkdownMediaPath(interpretedMediaPath);
  }
}

/// Load a local markdown file; if it does not exist, fallback to assets.

Future<String> loadMarkdownContent(
  String rawPath, {
  Function(String)? onError,
}) async {
  if (rawPath.trim().isEmpty) {
    // If the path is empty, fallback to assets.

    // onError?.call(
    //     'Markdown path is empty, fallback to $mdPath from assets.'
    // );
    return rootBundle.loadString(mdPath);
  }
  final interpretedPath = await interpretPath(rawPath);
  File file = File(interpretedPath);

  if (!await file.exists()) {
    // If the file does not exist, fallback to assets.

    onError?.call('Markdown file not found at $interpretedPath. '
        'Fallback to $mdPath from assets.');
    try {
      return await rootBundle.loadString(mdPath);
    } catch (e) {
      onError?.call('Error loading fallback asset: $e');
      return 'Error: Could not load fallback asset.';
    }
  } else {
    return file.readAsString();
  }
}

/// File watcher. Returns a subscription object that the caller can cancel at
/// an appropriate time.

StreamSubscription<FileSystemEvent> watchFileChanges(
  String filePath, {
  required void Function(String newContent) onFileContentChanged,
}) {
  final parentDir = Directory(p.dirname(filePath));
  return parentDir.watch().listen((event) async {
    if (event.type == FileSystemEvent.modify && event.path == filePath) {
      final f = File(filePath);
      if (await f.exists()) {
        final updated = await f.readAsString();
        onFileContentChanged(updated);
      }
    }
  });
}
