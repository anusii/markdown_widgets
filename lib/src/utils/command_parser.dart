/// Command parser for markdown widgets.
///
// Time-stamp: <Sunday 2024-11-17 21:00:21 +1100 Graham Williams>
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
import 'package:markdown_widget_builder/src/utils/helpers.dart';
import 'package:markdown_widget_builder/src/widgets/button_widget.dart';
import 'package:markdown_widget_builder/src/widgets/markdown_text.dart';
import 'package:markdown_widget_builder/src/widgets/menu_widget.dart';

/// The CommandParser class is responsible for parsing markdown-like content and
/// extracting custom commands that build various Flutter widgets. It supports
/// commands for images, videos, audio, menus, headings, alignment, sliders,
/// input fields, calendars, and more. It also handles hidden content blocks,
/// page breaks, and required widget validation.

class CommandParser {
  final BuildContext context;
  final String content;
  final String fullContent;
  final void Function(String title, String content)? onMenuItemSelected;
  final Map<String, dynamic> state;
  final VoidCallback setStateCallback;
  final String surveyTitle;
  final bool isParsingHiddenContent;

  late final Helpers helpers;

  // These maps hold the state of various widget values (input, slider, etc.)

  late final Map<String, String> _inputValues;
  late final Map<String, double> _sliderValues;
  late final Map<String, Map<String, dynamic>> _sliders;
  late final Map<String, String?> _radioValues;
  late final Map<String, Set<String>> _checkboxValues;
  late final Map<String, DateTime?> _dateValues;
  late final Map<String, String?> _dropdownValues;
  late final Map<String, List<String>> _dropdownOptions;
  late final Map<String, bool> _hiddenContentVisibility;
  late final Map<String, String> _hiddenContentMap;
  late final Set<String> _requiredWidgets;
  late final Map<String, String> _widgetTypeByName;

  // Set of allowed widget types that can be required.

  final Set<String> allowedRequiredTypes = {
    'Calendar',
    'Checkbox',
    'Dropdown',
    'InputSL',
    'InputML',
    'Radio',
    'Slider',
  };

  bool _hasMenu = false;

  /// Constructor for the CommandParser.
  ///
  /// - [context]: The Flutter build context.
  /// - [content]: The markdown content to parse.
  /// - [fullContent]: The full original content, used when menu blocks
  ///   reference the whole.
  /// - [onMenuItemSelected]: A callback when a menu item is selected.
  /// - [state]: A shared state map holding data for all widgets.
  /// - [setStateCallback]: A callback to update the state.
  /// - [surveyTitle]: Title of the survey or form.
  /// - [isParsingHiddenContent]: Whether we are currently parsing hidden
  ///   content sections.

  CommandParser({
    required this.context,
    required this.content,
    required this.fullContent,
    this.onMenuItemSelected,
    required this.state,
    required this.setStateCallback,
    required this.surveyTitle,
    this.isParsingHiddenContent = false,
  }) {
    helpers = Helpers(
      context: context,
      state: state,
      setStateCallback: setStateCallback,
    );

    // Retrieve or initialise various state maps.

    _inputValues = state['_inputValues'] as Map<String, String>;
    _sliderValues = state['_sliderValues'] as Map<String, double>;
    _sliders = state['_sliders'] as Map<String, Map<String, dynamic>>;
    _radioValues = state['_radioValues'] as Map<String, String?>;
    _checkboxValues = state['_checkboxValues'] as Map<String, Set<String>>;
    _dateValues = state['_dateValues'] as Map<String, DateTime?>;
    _dropdownValues = state['_dropdownValues'] as Map<String, String?>;
    _dropdownOptions = state['_dropdownOptions'] as Map<String, List<String>>;
    _hiddenContentVisibility =
        state['_hiddenContentVisibility'] as Map<String, bool>? ?? {};
    _hiddenContentMap =
        state['_hiddenContentMap'] as Map<String, String>? ?? {};
    state['_hiddenContentMap'] = _hiddenContentMap;

    _requiredWidgets = state['_requiredWidgets'] as Set<String>? ?? {};
    state['_requiredWidgets'] = _requiredWidgets;

    _widgetTypeByName = {};
  }

  /// Parse the markdown content and extract all widgets and commands into
  /// pages of widgets.
  ///
  /// Returns a list of pages, where each page is a List<Widget>.

  List<List<Widget>> parse() {
    List<List<Widget>> pages = [];
    List<Widget> currentPageWidgets = [];

    // Regular expressions to identify various custom blocks and commands.

    final RegExp descriptionBlockExp = RegExp(
        r'%% Description-Begin([\s\S]*?)%% Description-End',
        caseSensitive: false);

    final RegExp headingAlignBlockExp = RegExp(
        r'%% H([1-6])(Left|Right|Center|Justify)?'
        r'-Begin([\s\S]*?)%% H\1(?:\2)?-End',
        caseSensitive: false);

    final RegExp alignBlockExp = RegExp(
        r'%% Align(Left|Right|Center|Justify)-Begin([\s\S]*?)%% Align\1-End',
        caseSensitive: false);

    final RegExp imageExp = RegExp(
        r'%% Image'
        r'\(\s*([^,\)]+)\s*(?:,\s*([\d\.]+)\s*)?(?:,\s*([\d\.]+)\s*)?\)',
        caseSensitive: false);

    final RegExp videoExp =
        RegExp(r'%% Video\(([^)]+)\)', caseSensitive: false);

    final RegExp audioExp =
        RegExp(r'%% Audio\(([^)]+)\)', caseSensitive: false);

    final RegExp menuBlockExp =
        RegExp(r'%% Menu-Begin([\s\S]*?)%% Menu-End', caseSensitive: false);

    final RegExp buttonBlockExp = RegExp(
        r'%% Button-Begin\((.*?)\)([\s\S]*?)%% Button-End',
        caseSensitive: false);

    final RegExp hiddenBlockExp = RegExp(
      r'%% Hidden-Begin\(([^)]+)\)([\s\S]*?)%% Hidden-End',
      caseSensitive: false,
    );

    final RegExp hiddenPlaceholderExp = RegExp(
      r'%% Hidden\(([^)]+)\)',
      caseSensitive: false,
    );

    final RegExp pageBreakExp = RegExp(r'%% PageBreak', caseSensitive: false);

    String modifiedContent = content;

    // Handle hidden blocks by extracting their content and replacing them with
    // placeholders.

    modifiedContent = modifiedContent.replaceAllMapped(hiddenBlockExp, (match) {
      String id = match.group(1)!.trim();
      String c = match.group(2)!;
      _hiddenContentMap[id] = c;
      state['_hiddenContentMap'] = _hiddenContentMap;
      return '%%HiddenPlaceholder($id)%%';
    });

    modifiedContent =
        modifiedContent.replaceAllMapped(hiddenPlaceholderExp, (match) {
      String id = match.group(1)!.trim();
      return '%%HiddenPlaceholder($id)%%';
    });

    // Extract menu blocks, replace them with placeholders, and possibly limit
    // content if a menu is present.

    int menuIndex = 0;
    final Map<String, String> menuPlaceholders = {};
    modifiedContent = modifiedContent.replaceAllMapped(menuBlockExp, (match) {
      String placeholder = '%%MenuPlaceholder$menuIndex%%';
      menuPlaceholders[placeholder] = match.group(1)!;
      menuIndex++;
      return placeholder;
    });

    int buttonIndex = 0;
    final Map<String, Map<String, String>> buttonPlaceholders = {};
    modifiedContent = modifiedContent.replaceAllMapped(buttonBlockExp, (match) {
      String placeholder = '%%ButtonPlaceholder$buttonIndex%%';
      buttonPlaceholders[placeholder] = {
        'command': match.group(1)!,
        'requiredWidgets': match.group(2)!,
      };

      List<String> requiredWidgets = _parseRequiredWidgets(match.group(2)!);
      _requiredWidgets.addAll(requiredWidgets);
      state['_requiredWidgets'] = _requiredWidgets;
      buttonIndex++;
      return placeholder;
    });

    _hasMenu = menuIndex > 0;

    // If a menu is present and we are not parsing hidden content, truncate
    // content after the first menu.

    if (_hasMenu && !isParsingHiddenContent) {
      final menuPlaceholderPattern = RegExp(r'%%MenuPlaceholder\d+%%');
      final menuMatch = menuPlaceholderPattern.firstMatch(modifiedContent);
      if (menuMatch != null) {
        final menuEndIndex = menuMatch.end;
        modifiedContent = modifiedContent.substring(0, menuEndIndex);
      }
    }

    int descriptionIndex = 0;
    final Map<String, String> descriptionPlaceholders = {};
    modifiedContent =
        modifiedContent.replaceAllMapped(descriptionBlockExp, (match) {
      String placeholder = '%%DescriptionPlaceholder$descriptionIndex%%';
      descriptionPlaceholders[placeholder] = match.group(1)!;
      descriptionIndex++;
      return placeholder;
    });

    int headingIndex = 0;
    final Map<String, Map<String, String>> headingPlaceholders = {};
    modifiedContent =
        modifiedContent.replaceAllMapped(headingAlignBlockExp, (match) {
      String placeholder = '%%HeadingPlaceholder$headingIndex%%';
      headingPlaceholders[placeholder] = {
        'level': match.group(1)!,
        'align': match.group(2) ?? 'Left',
        'content': match.group(3)!,
      };
      headingIndex++;
      return placeholder;
    });

    int alignIndex = 0;
    final Map<String, Map<String, String>> alignPlaceholders = {};
    modifiedContent = modifiedContent.replaceAllMapped(alignBlockExp, (match) {
      String placeholder = '%%AlignPlaceholder$alignIndex%%';
      alignPlaceholders[placeholder] = {
        'align': match.group(1)!,
        'content': match.group(2)!
      };
      alignIndex++;
      return placeholder;
    });

    // Regex for identifying all custom commands and placeholders.

    final RegExp customCommandExp = RegExp(
        r'(%% Slider\([^\)]+\)|%% Submit|'
        r'%% (Radio|Checkbox)\((?:[^\\()]|\\.)+\)|'
        r'%% InputSL\([^\)]+\)|%% InputML\([^\)]+\)|'
        r'%% Calendar\([^\)]+\)|%% Dropdown\([^\)]+\)|'
        r'%% Image\([^\)]+\)|%% Video\([^\)]+\)|%% Audio\([^\)]+\)|'
        r'%% Timer\([^\)]+\)|%% Button\([^\)]+\)|%% EmptyLine|'
        r'%%DescriptionPlaceholder\d+%%|'
        r'%%HeadingPlaceholder\d+%%|'
        r'%%AlignPlaceholder\d+%%|'
        r'%%MenuPlaceholder\d+%%|'
        r'%%ButtonPlaceholder\d+%%|'
        r'%%HiddenPlaceholder\([^\)]+\)%%|'
        r'%% PageBreak)',
        caseSensitive: false);

    final matches = customCommandExp.allMatches(modifiedContent).toList();
    int lastIndex = 0;

    String? currentRadioGroupName;
    List<Map<String, String?>> currentRadioOptions = [];

    String? currentCheckboxGroupName;
    List<Map<String, String?>> currentCheckboxOptions = [];

    /// Flush the current radio group into the widget list.

    void flushCurrentRadioGroup() {
      if (currentRadioGroupName != null) {
        bool isRequired = _isWidgetRequired('Radio', currentRadioGroupName!);
        currentPageWidgets.add(helpers.buildRadioGroup(
            currentRadioGroupName!, currentRadioOptions,
            isRequired: isRequired));
        currentRadioGroupName = null;
        currentRadioOptions = [];
      }
    }

    /// Flush the current checkbox group into the widget list.

    void flushCurrentCheckboxGroup() {
      if (currentCheckboxGroupName != null) {
        bool isRequired =
            _isWidgetRequired('Checkbox', currentCheckboxGroupName!);
        currentPageWidgets.add(helpers.buildCheckboxGroup(
            currentCheckboxGroupName!, currentCheckboxOptions,
            isRequired: isRequired));
        currentCheckboxGroupName = null;
        currentCheckboxOptions = [];
      }
    }

    /// Start a new page in the returned pages list.

    void startNewPage() {
      if (currentPageWidgets.isNotEmpty) {
        pages.add(currentPageWidgets);
      }
      currentPageWidgets = [];
    }

    currentPageWidgets = [];

    // Iterate through all matches of custom commands and content.

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      if (match.start > lastIndex) {
        // Extract any Markdown text between the previous and current command.

        String markdownContent =
            modifiedContent.substring(lastIndex, match.start);
        if (markdownContent.trim().isNotEmpty) {
          flushCurrentRadioGroup();
          flushCurrentCheckboxGroup();
          currentPageWidgets.add(MarkdownText(data: markdownContent));
        }
      }

      String command = match.group(0)!;

      // Handle menu placeholders.

      if (command
          .startsWith(RegExp(r'%%MenuPlaceholder', caseSensitive: false))) {
        String menuContent = menuPlaceholders[command]!;
        currentPageWidgets.add(
          MenuWidget(
            menuContent: menuContent,
            fullContent: fullContent,
            onMenuItemSelected: (title, surveyContent) {
              if (onMenuItemSelected != null) {
                onMenuItemSelected!(title, surveyContent);
              }
            },
          ),
        );
      } else if (command.startsWith(
          RegExp(r'%%DescriptionPlaceholder', caseSensitive: false))) {
        // Handle description placeholders.

        String descriptionContent = descriptionPlaceholders[command]!;
        bool isRequired = false;
        currentPageWidgets.add(helpers.buildDescriptionBox(descriptionContent,
            isRequired: isRequired));
      } else if (command
          .startsWith(RegExp(r'%%HeadingPlaceholder', caseSensitive: false))) {
        // Handle heading placeholders.

        final headingInfo = headingPlaceholders[command]!;
        final level = int.parse(headingInfo['level']!);
        final align = headingInfo['align']!;
        final headingContent = headingInfo['content']!;
        bool isRequired = false;
        currentPageWidgets.add(helpers.buildHeading(
            level, headingContent, align,
            isRequired: isRequired));
      } else if (command
          .startsWith(RegExp(r'%%AlignPlaceholder', caseSensitive: false))) {
        // Handle alignment placeholders.

        final alignInfo = alignPlaceholders[command]!;
        final align = alignInfo['align']!;
        final alignContent = alignInfo['content']!;
        bool isRequired = false;
        currentPageWidgets.add(helpers.buildAlignedText(align, alignContent,
            isRequired: isRequired));
      } else if (command
          .startsWith(RegExp(r'%% Image', caseSensitive: false))) {
        // Handle images.

        final imageMatch = imageExp.firstMatch(command);
        if (imageMatch != null) {
          final filename = imageMatch.group(1)!.trim();
          double? width;
          double? height;

          if (imageMatch.group(2) != null) {
            width = double.tryParse(imageMatch.group(2)!.trim());
          }
          if (imageMatch.group(3) != null) {
            height = double.tryParse(imageMatch.group(3)!.trim());
          }
          currentPageWidgets.add(
              helpers.buildImageWidget(filename, width: width, height: height));
        }
      } else if (command
          .startsWith(RegExp(r'%% Video', caseSensitive: false))) {
        // Handle videos.

        final videoMatch = videoExp.firstMatch(command);
        if (videoMatch != null) {
          final filename = videoMatch.group(1)!.trim();
          currentPageWidgets.add(helpers.buildVideoWidget(filename));
        }
      } else if (command
          .startsWith(RegExp(r'%% Audio', caseSensitive: false))) {
        // Handle audio.

        final audioMatch = audioExp.firstMatch(command);
        if (audioMatch != null) {
          final filename = audioMatch.group(1)!.trim();
          currentPageWidgets.add(helpers.buildAudioWidget(filename));
        }
      } else if (command
          .startsWith(RegExp(r'%% Timer', caseSensitive: false))) {
        // Handle timer.

        flushCurrentRadioGroup();
        flushCurrentCheckboxGroup();
        final timerExp = RegExp(r'%% Timer\(([^)]+)\)', caseSensitive: false);
        final timerMatch = timerExp.firstMatch(command);
        if (timerMatch != null) {
          final timeString = timerMatch.group(1)!.trim();
          bool isRequired = false;
          currentPageWidgets.add(
              helpers.buildTimerWidget(timeString, isRequired: isRequired));
        }
      } else if (command
          .startsWith(RegExp(r'%% EmptyLine', caseSensitive: false))) {
        // Handle empty line.

        flushCurrentRadioGroup();
        flushCurrentCheckboxGroup();
        final lineHeight = DefaultTextStyle.of(context).style.fontSize ?? 16.0;
        currentPageWidgets.add(SizedBox(height: lineHeight));
      } else if (command
          .startsWith(RegExp(r'%% Slider', caseSensitive: false))) {
        // Handle slider.

        final sliderExp = RegExp(
            r'%% Slider\(([^,]+),\s*([\d\.]+),'
            r'\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)',
            caseSensitive: false);
        final sliderMatch = sliderExp.firstMatch(command);
        if (sliderMatch != null) {
          final name = sliderMatch.group(1)!.trim();
          final min = double.parse(sliderMatch.group(2)!);
          final max = double.parse(sliderMatch.group(3)!);
          final defaultValue = double.parse(sliderMatch.group(4)!);
          final step = double.parse(sliderMatch.group(5)!);

          _sliders[name] = {
            'min': min,
            'max': max,
            'defaultValue': defaultValue,
            'step': step,
          };

          if (!_sliderValues.containsKey(name)) {
            _sliderValues[name] = defaultValue;
          }

          bool isRequired = _isWidgetRequired('Slider', name);
          _widgetTypeByName[name] = 'Slider';
          currentPageWidgets
              .add(helpers.buildSlider(name, isRequired: isRequired));
        }
      } else if (command.startsWith('%% Button')) {
        // Handle a simple button (%% Button(...)).
        flushCurrentRadioGroup();
        flushCurrentCheckboxGroup();
        currentPageWidgets.add(
          ButtonWidget(
            command: command,
            requiredWidgets: [],
            state: state,
            surveyTitle: surveyTitle,
          ),
        );
      } else if (command
          .startsWith(RegExp(r'%%ButtonPlaceholder', caseSensitive: false))) {
        // Handle button placeholders (%%ButtonPlaceholderX%%).

        flushCurrentRadioGroup();
        flushCurrentCheckboxGroup();
        final buttonInfo = buttonPlaceholders[command]!;
        final commandStr = buttonInfo['command']!;
        final requiredWidgetsStr = buttonInfo['requiredWidgets']!;
        List<String> requiredWidgets =
            _parseRequiredWidgets(requiredWidgetsStr);

        // Filter out widgets not in the allowed required types.

        requiredWidgets = requiredWidgets
            .where((name) =>
                allowedRequiredTypes.contains(getWidgetTypeByName(name)))
            .toList();
        currentPageWidgets.add(
          ButtonWidget(
            command: '%% Button($commandStr)',
            requiredWidgets: requiredWidgets,
            state: state,
            surveyTitle: surveyTitle,
          ),
        );
      } else if (command
          .startsWith(RegExp(r'%%HiddenPlaceholder', caseSensitive: false))) {
        // Handle hidden placeholders (%%HiddenPlaceholder(...)%%).

        final hiddenPlaceholderExp =
            RegExp(r'%%HiddenPlaceholder\(([^)]+)\)%%', caseSensitive: false);
        final placeholderMatch = hiddenPlaceholderExp.firstMatch(command);
        if (placeholderMatch != null) {
          final id = placeholderMatch.group(1)!.trim();
          final hiddenContent = _hiddenContentMap[id] ?? '';

          if (!_hiddenContentVisibility.containsKey(id)) {
            _hiddenContentVisibility[id] = false;
          }

          // Parse the hidden content recursively.

          final hiddenWidgets = CommandParser(
            context: context,
            content: hiddenContent,
            fullContent: fullContent,
            onMenuItemSelected: onMenuItemSelected,
            state: state,
            setStateCallback: setStateCallback,
            surveyTitle: surveyTitle,
            isParsingHiddenContent: true,
          ).parse();

          // Flatten hidden widget pages.

          List<Widget> flattenedHidden = [];
          for (var p in hiddenWidgets) {
            flattenedHidden.addAll(p);
          }

          currentPageWidgets.add(
            Visibility(
              visible: _hiddenContentVisibility[id] ?? false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: flattenedHidden,
              ),
            ),
          );
        }
      } else if (command
          .startsWith(RegExp(r'%% Radio', caseSensitive: false))) {
        // Handle radio commands.

        flushCurrentCheckboxGroup();
        final radioExp = RegExp(
          r'%% Radio'
          r'\(([^,]+),\s*([^,]+),\s*"((?:[^"\\]|\\.)*)"(?:,\s*([^)]+))?\)',
          caseSensitive: false,
        );
        final radioMatch = radioExp.firstMatch(command);
        if (radioMatch != null) {
          final name = radioMatch.group(1)!.trim();
          final value = radioMatch.group(2)!.trim();
          String label = radioMatch.group(3)!;

          // Define escape characters for the label.

          label = label.replaceAll(r'\"', '"');
          label = label.replaceAll(r'\(', '(');
          label = label.replaceAll(r'\)', ')');
          label = label.replaceAll('\n', ' ');
          label = label.trim();
          String? hiddenContentId = radioMatch.group(4)?.trim();

          // Start a new radio group if needed.

          if (currentRadioGroupName == null || currentRadioGroupName != name) {
            flushCurrentRadioGroup();
            currentRadioGroupName = name;
            if (!_radioValues.containsKey(name)) {
              _radioValues[name] = null;
            }
            _widgetTypeByName[name] = 'Radio';
          }

          currentRadioOptions.add({
            'value': value,
            'label': label,
            'hiddenContentId': hiddenContentId,
          });

          // Determine if this is the last radio option for the group.

          bool isLastOption = true;
          if (i + 1 < matches.length) {
            final nextMatch = matches[i + 1];
            final nextCommand = nextMatch.group(0)!;
            final nextRadioMatch = radioExp.firstMatch(nextCommand);
            if (nextRadioMatch != null) {
              final nextName = nextRadioMatch.group(1)!.trim();
              if (nextName.toLowerCase() ==
                  currentRadioGroupName!.toLowerCase()) {
                isLastOption = false;
              }
            }
          }

          if (isLastOption) {
            flushCurrentRadioGroup();
          }
        }
      } else if (command
          .startsWith(RegExp(r'%% Checkbox', caseSensitive: false))) {
        // Handle checkbox commands.

        flushCurrentRadioGroup();
        final checkboxExp = RegExp(
          r'%% Checkbox'
          r'\(([^,]+),\s*([^,]+),\s*"((?:[^"\\]|\\.)*)"(?:,\s*([^)]+))?\)',
          caseSensitive: false,
        );
        final checkboxMatch = checkboxExp.firstMatch(command);
        if (checkboxMatch != null) {
          final name = checkboxMatch.group(1)!.trim();
          final value = checkboxMatch.group(2)!.trim();
          String label = checkboxMatch.group(3)!;
          label = label.replaceAll(r'\"', '"');
          label = label.replaceAll(r'\(', '(');
          label = label.replaceAll(r'\)', ')');
          label = label.replaceAll('\n', ' ');
          label = label.trim();
          String? hiddenContentId = checkboxMatch.group(4)?.trim();

          // Start a new checkbox group if needed.

          if (currentCheckboxGroupName == null ||
              currentCheckboxGroupName != name) {
            flushCurrentCheckboxGroup();
            currentCheckboxGroupName = name;
            if (!_checkboxValues.containsKey(name)) {
              _checkboxValues[name] = {};
            }
            _widgetTypeByName[name] = 'Checkbox';
          }

          currentCheckboxOptions.add({
            'value': value,
            'label': label,
            'hiddenContentId': hiddenContentId,
          });

          // Determine if this is the last checkbox option for the group.

          bool isLastOption = true;
          if (i + 1 < matches.length) {
            final nextMatch = matches[i + 1];
            final nextCommand = nextMatch.group(0)!;
            final nextCheckboxMatch = checkboxExp.firstMatch(nextCommand);
            if (nextCheckboxMatch != null) {
              final nextName = nextCheckboxMatch.group(1)!.trim();
              if (nextName.toLowerCase() ==
                  currentCheckboxGroupName!.toLowerCase()) {
                isLastOption = false;
              }
            }
          }

          if (isLastOption) {
            flushCurrentCheckboxGroup();
          }
        }
      } else if (command
          .startsWith(RegExp(r'%% Calendar', caseSensitive: false))) {
        // Handle calendar commands.

        flushCurrentRadioGroup();
        flushCurrentCheckboxGroup();
        final calendarExp =
            RegExp(r'%% Calendar\(([^)]+)\)', caseSensitive: false);
        final calendarMatch = calendarExp.firstMatch(command);
        if (calendarMatch != null) {
          final name = calendarMatch.group(1)!.trim();
          if (!_dateValues.containsKey(name)) {
            _dateValues[name] = null;
          }
          bool isRequired = _isWidgetRequired('Calendar', name);
          _widgetTypeByName[name] = 'Calendar';
          currentPageWidgets
              .add(helpers.buildCalendarField(name, isRequired: isRequired));
        }
      } else if (command
          .startsWith(RegExp(r'%% Dropdown', caseSensitive: false))) {
        // Handle dropdown commands.

        flushCurrentRadioGroup();
        flushCurrentCheckboxGroup();
        final dropdownExp =
            RegExp(r'%% Dropdown\(([^)]+)\)', caseSensitive: false);
        final dropdownMatch = dropdownExp.firstMatch(command);
        if (dropdownMatch != null) {
          final name = dropdownMatch.group(1)!.trim();
          if (!_dropdownValues.containsKey(name)) {
            _dropdownValues[name] = null;
          }
          if (!_dropdownOptions.containsKey(name)) {
            _dropdownOptions[name] = [];
          }

          // Extract the dropdown options from subsequent lines starting with
          // '- '.

          int optionsStartIndex = match.end;
          int optionsEndIndex = modifiedContent.length;

          final lines =
              modifiedContent.substring(optionsStartIndex).split('\n');
          final List<String> options = [];
          int lineOffset = 0;

          for (var line in lines) {
            final trimmedLine = line.trim();
            if (trimmedLine.startsWith('- ')) {
              options.add(trimmedLine.substring(2).trim());
              lineOffset += line.length + 1;
            } else if (trimmedLine.isEmpty) {
              lineOffset += line.length + 1;
            } else {
              break;
            }
          }

          optionsEndIndex = optionsStartIndex + lineOffset;
          _dropdownOptions[name] = options;
          bool isRequired = _isWidgetRequired('Dropdown', name);
          _widgetTypeByName[name] = 'Dropdown';
          currentPageWidgets.add(
              helpers.buildDropdown(name, options, isRequired: isRequired));
          lastIndex = optionsEndIndex;
          continue;
        }
      } else if (command
          .startsWith(RegExp(r'%% InputSL', caseSensitive: false))) {
        // Handle single-line input commands.

        flushCurrentRadioGroup();
        flushCurrentCheckboxGroup();
        final inputSLExp =
            RegExp(r'%% InputSL\(([^)]+)\)', caseSensitive: false);
        final inputSLMatch = inputSLExp.firstMatch(command);
        if (inputSLMatch != null) {
          final name = inputSLMatch.group(1)!.trim();
          if (!_inputValues.containsKey(name)) {
            _inputValues[name] = '';
          }
          bool isRequired = _isWidgetRequired('InputSL', name);
          _widgetTypeByName[name] = 'InputSL';
          currentPageWidgets.add(helpers.buildInputField(name,
              isMultiLine: false, isRequired: isRequired));
        }
      } else if (command
          .startsWith(RegExp(r'%% InputML', caseSensitive: false))) {
        // Handle multi-line input commands.

        flushCurrentRadioGroup();
        flushCurrentCheckboxGroup();
        final inputMLExp =
            RegExp(r'%% InputML\(([^)]+)\)', caseSensitive: false);
        final inputMLMatch = inputMLExp.firstMatch(command);
        if (inputMLMatch != null) {
          final name = inputMLMatch.group(1)!.trim();
          if (!_inputValues.containsKey(name)) {
            _inputValues[name] = '';
          }
          bool isRequired = _isWidgetRequired('InputML', name);
          _widgetTypeByName[name] = 'InputML';
          currentPageWidgets.add(helpers.buildInputField(name,
              isMultiLine: true, isRequired: isRequired));
        }
      } else if (pageBreakExp.hasMatch(command)) {
        // Handle page breaks.

        flushCurrentRadioGroup();
        flushCurrentCheckboxGroup();
        startNewPage();
      }

      lastIndex = match.end;
    }

    // Add any trailing markdown text after the last command.

    if (lastIndex < modifiedContent.length) {
      String markdownContent = modifiedContent.substring(lastIndex);
      if (markdownContent.trim().isNotEmpty) {
        flushCurrentRadioGroup();
        flushCurrentCheckboxGroup();

        // If we have a menu and are not parsing hidden content, do not add
        // trailing content.

        if (!_hasMenu || isParsingHiddenContent) {
          currentPageWidgets.add(MarkdownText(data: markdownContent));
        }
      }
    }

    flushCurrentRadioGroup();
    flushCurrentCheckboxGroup();

    // Add the final page if any widgets remain.

    if (currentPageWidgets.isNotEmpty) {
      pages.add(currentPageWidgets);
    }

    return pages;
  }

  /// Check if a widget is required, given the widget type and name.

  bool _isWidgetRequired(String type, String name) {
    return allowedRequiredTypes.contains(type) &&
        _requiredWidgets.contains(name);
  }

  /// Parse the required widgets listed in a block and return their names.

  List<String> _parseRequiredWidgets(String content) {
    final lines = content.split('\n');
    final widgetNames = <String>[];
    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('- ')) {
        widgetNames.add(trimmedLine.substring(2).trim());
      } else if (trimmedLine.isNotEmpty) {
        widgetNames.add(trimmedLine);
      }
    }
    return widgetNames;
  }

  /// Retrieve the widget type name by its identifier.

  String getWidgetTypeByName(String name) {
    return _widgetTypeByName[name] ?? '';
  }
}
