/// Widgets for survey questionnaires defined using markdown-like syntax.
///
// Time-stamp: <Saturday 2024-11-16 16:41:53 +1100 Graham Williams>
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

library markdown_widget_builder;

export 'src/widgets/markdown_widget_builder.dart'
    show MarkdownWidgetBuilder, setMarkdownMediaPath;

export 'src/utils/file_ops.dart'
    show
        PathType,
        Config,
        loadConfigFromAssets,
        loadMediaFiles,
        loadMarkdownContent,
        watchFileChanges,
        interpretPath,
        getAppDirectory;

export 'src/constants/pkg.dart'
    show
        applicationName,
        applicationVersion,
        applicationRepo,
        siiUrl,
        defaultConfigFile,
        assetsPath,
        mediaPath,
        mdPath,
        setAssetsPath,
        setMediaPath,
        setMdPath;
