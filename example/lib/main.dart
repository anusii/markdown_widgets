/// An example of loading a markdown with 4 surveys and rendering them.
///
// Time-stamp: <Sunday 2024-11-17 10:10:59 +1100 Graham Williams>
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:markdown_widget_builder/markdown_widget_builder.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
  late Future<String> _markdownContentFuture;

  @override
  void initState() {
    super.initState();
    _markdownContentFuture = _loadMarkdownContent();
  }

  /// Loads the markdown content from the assets/sample_markdown.md file.

  Future<String> _loadMarkdownContent() async {
    return await rootBundle.loadString('assets/sample_markdown.md');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _markdownContentFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final markdownContent = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Markdown Widgets Example'),
            ),
            body: SingleChildScrollView(
              child: MarkdownWidgetBuilder(
                content: markdownContent,
                title: 'Sample Markdown',
                onMenuItemSelected: (selectedTitle, selectedContent) {
                  // Navigate to a detailed page when a menu item is selected.

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
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Markdown Widgets Example'),
            ),
            body: const Center(
              child: Text('Error loading markdown content'),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Markdown Widgets Example'),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
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
            // Navigate to another detail page if a menu item is selected.

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
