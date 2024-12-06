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

import 'package:markdown_widget_builder/src/constants/pkg.dart';
import 'package:markdown_widget_builder/src/utils/helpers.dart';
import 'package:markdown_widget_builder/src/widgets/button_widget.dart';
import 'package:markdown_widget_builder/src/widgets/markdown_text.dart';
import 'package:markdown_widget_builder/src/widgets/menu_widget.dart';

class CommandParser {
  final BuildContext context;
  final String content;
  final String fullContent;
  final void Function(String title, String content)? onMenuItemSelected;
  final Map<String, dynamic> state;
  final VoidCallback setStateCallback;
  final String surveyTitle;

  late final Helpers helpers;

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

  // Add a set to keep track of required widget names
  late final Set<String> _requiredWidgets;

  bool _hasMenu = false;
  final bool isParsingHiddenContent;

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
    // Initialise Helpers.
    helpers = Helpers(
      context: context,
      state: state,
      setStateCallback: setStateCallback,
    );

    // Initialise state variables.
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

    // Access or initialise the hidden content map.
    _hiddenContentMap =
        state['_hiddenContentMap'] as Map<String, String>? ?? {};
    state['_hiddenContentMap'] = _hiddenContentMap;

    // Initialize required widgets set
    _requiredWidgets = state['_requiredWidgets'] as Set<String>? ?? {};
    state['_requiredWidgets'] = _requiredWidgets;
  }

  List<Widget> parse() {
    List<Widget> widgets = [];

    // Regular expression to match description blocks.
    final RegExp descriptionBlockExp = RegExp(
        r'%% Description-Begin([\s\S]*?)%% Description-End',
        caseSensitive: false);

    // Regular expression to match heading blocks with alignment.
    final RegExp headingAlignBlockExp = RegExp(
        r'%% H([1-6])(Left|Right|Center|Justify)?'
        r'-Begin([\s\S]*?)%% H\1(?:\2)?-End',
        caseSensitive: false);

    // Regular expression to match alignment blocks.
    final RegExp alignBlockExp = RegExp(
        r'%% Align(Left|Right|Center|Justify)-Begin([\s\S]*?)%% Align\1-End',
        caseSensitive: false);

    // Regular expression to match image commands.
    final RegExp imageExp = RegExp(
        r'%% Image'
        r'\(\s*([^,\)]+)\s*(?:,\s*([\d\.]+)\s*)?(?:,\s*([\d\.]+)\s*)?\)',
        caseSensitive: false);

    // Regular expression to match video commands.
    final RegExp videoExp =
    RegExp(r'%% Video\(([^)]+)\)', caseSensitive: false);

    // Regular expression to match audio commands.
    final RegExp audioExp =
    RegExp(r'%% Audio\(([^)]+)\)', caseSensitive: false);

    // Regular expression to match %% Menu blocks.
    final RegExp menuBlockExp =
    RegExp(r'%% Menu-Begin([\s\S]*?)%% Menu-End', caseSensitive: false);

    // Regular expression to match %% Button-Begin blocks.
    final RegExp buttonBlockExp = RegExp(
        r'%% Button-Begin\((.*?)\)([\s\S]*?)%% Button-End',
        caseSensitive: false);

    // Regular expression to match hidden content blocks.
    final RegExp hiddenBlockExp = RegExp(
      r'%% Hidden-Begin\(([^)]+)\)([\s\S]*?)%% Hidden-End',
      caseSensitive: false,
    );

    // Regular expression to match hidden content placeholders.
    final RegExp hiddenPlaceholderExp = RegExp(
      r'%% Hidden\(([^)]+)\)',
      caseSensitive: false,
    );

    String modifiedContent = content;

    // Parse the hidden content blocks and store in _hiddenContentMap.
    modifiedContent = modifiedContent.replaceAllMapped(hiddenBlockExp, (match) {
      String id = match.group(1)!.trim();
      String content = match.group(2)!;

      _hiddenContentMap[id] = content;
      state['_hiddenContentMap'] = _hiddenContentMap;

      // Replace the hidden block with a placeholder.
      return '%%HiddenPlaceholder($id)%%';
    });

    // Parse the hidden content placeholders and replace with placeholders.
    modifiedContent =
        modifiedContent.replaceAllMapped(hiddenPlaceholderExp, (match) {
          String id = match.group(1)!.trim();
          String placeholder = '%%HiddenPlaceholder($id)%%';
          return placeholder;
        });

    // Parse the menu blocks and replace with placeholders.
    int menuIndex = 0;
    final Map<String, String> menuPlaceholders = {};
    modifiedContent = modifiedContent.replaceAllMapped(menuBlockExp, (match) {
      String placeholder = '%%MenuPlaceholder$menuIndex%%';
      menuPlaceholders[placeholder] = match.group(1)!;
      menuIndex++;
      return placeholder;
    });

    // Parse the button blocks and replace with placeholders.
    int buttonIndex = 0;
    final Map<String, Map<String, String>> buttonPlaceholders = {};
    modifiedContent = modifiedContent.replaceAllMapped(buttonBlockExp, (match) {
      String placeholder = '%%ButtonPlaceholder$buttonIndex%%';
      buttonPlaceholders[placeholder] = {
        'command': match.group(1)!,
        'requiredWidgets': match.group(2)!,
      };
      // Parse requiredWidgets from match.group(2)
      List<String> requiredWidgets = _parseRequiredWidgets(match.group(2)!);
      // Add to _requiredWidgets set
      _requiredWidgets.addAll(requiredWidgets);
      // Update state
      state['_requiredWidgets'] = _requiredWidgets;
      buttonIndex++;
      return placeholder;
    });

    // Check if the content has a menu.
    _hasMenu = menuIndex > 0;

    // If there is a menu, trim the content to only process the menu part.
    if (_hasMenu && !isParsingHiddenContent) {
      // If there is a menu, only process the menu part and ignore the rest.
      final menuPlaceholderPattern = RegExp(r'%%MenuPlaceholder\d+%%');
      final menuMatch = menuPlaceholderPattern.firstMatch(modifiedContent);

      if (menuMatch != null) {
        // Keep only the content before the menu placeholder (including the menu itself).
        final menuEndIndex = menuMatch.end;
        modifiedContent = modifiedContent.substring(0, menuEndIndex);
      }
    }

    // Parse the description blocks and replace with placeholders.
    int descriptionIndex = 0;
    final Map<String, String> descriptionPlaceholders = {};
    modifiedContent =
        modifiedContent.replaceAllMapped(descriptionBlockExp, (match) {
          String placeholder = '%%DescriptionPlaceholder$descriptionIndex%%';
          descriptionPlaceholders[placeholder] = match.group(1)!;
          descriptionIndex++;
          return placeholder;
        });

    // Parse heading blocks with alignment and replace with placeholders.
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

    // Parse alignment blocks and replace with placeholders.
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

    // Regular expression to match custom commands, including placeholders.
    final RegExp customCommandExp = RegExp(
        r'(%% Slider\([^\)]+\)|%% Submit|'
        r'%% Radio\([^\)]+\)|%% Checkbox\([^\)]+\)|'
        r'%% InputSL\([^\)]+\)|%% InputML\([^\)]+\)|'
        r'%% Calendar\([^\)]+\)|%% Dropdown\([^\)]+\)|'
        r'%% Image\([^\)]+\)|%% Video\([^\)]+\)|%% Audio\([^\)]+\)|'
        r'%% Timer\([^\)]+\)|%% Button\([^\)]+\)|%% EmptyLine|'
        r'%%DescriptionPlaceholder\d+%%|'
        r'%%HeadingPlaceholder\d+%%|'
        r'%%AlignPlaceholder\d+%%|'
        r'%%MenuPlaceholder\d+%%|'
        r'%%ButtonPlaceholder\d+%%|'
        r'%%HiddenPlaceholder\([^\)]+\)%%)',
        caseSensitive: false);

    final matches = customCommandExp.allMatches(modifiedContent).toList();

    int lastIndex = 0;

    // Parse the radio group variables.
    String? currentRadioGroupName;
    List<Map<String, String?>> currentRadioOptions = [];

    // Parse the checkbox group variables.
    String? currentCheckboxGroupName;
    List<Map<String, String?>> currentCheckboxOptions = [];

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      if (match.start > lastIndex) {
        // Extract the markdown content between custom commands.
        String markdownContent =
        modifiedContent.substring(lastIndex, match.start);
        if (markdownContent.trim().isNotEmpty) {
          // Build any unfinished radio or checkbox groups.
          if (currentRadioGroupName != null) {
            widgets.add(helpers.buildRadioGroup(
                currentRadioGroupName, currentRadioOptions,
                isRequired: _requiredWidgets.contains(currentRadioGroupName)));
            currentRadioGroupName = null;
            currentRadioOptions = [];
          }

          if (currentCheckboxGroupName != null) {
            widgets.add(helpers.buildCheckboxGroup(
                currentCheckboxGroupName, currentCheckboxOptions,
                isRequired: _requiredWidgets.contains(currentCheckboxGroupName)));
            currentCheckboxGroupName = null;
            currentCheckboxOptions = [];
          }

          widgets.add(MarkdownText(data: markdownContent));
        }
      }

      // Parse the command.
      String command = match.group(0)!;

      if (command
          .startsWith(RegExp(r'%%MenuPlaceholder', caseSensitive: false))) {
        // Get the actual menu content.
        String menuContent = menuPlaceholders[command]!;

        // Use the MenuWidget to build the menu.
        widgets.add(
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
        // Description block placeholder to get the actual content.
        String descriptionContent = descriptionPlaceholders[command]!;

        widgets.add(helpers.buildDescriptionBox(descriptionContent));
      } else if (command
          .startsWith(RegExp(r'%%HeadingPlaceholder', caseSensitive: false))) {
        // Heading block placeholder with alignment.
        final headingInfo = headingPlaceholders[command]!;
        final level = int.parse(headingInfo['level']!);
        final align = headingInfo['align']!;
        final headingContent = headingInfo['content']!;

        // Check if heading is required (unlikely, but for consistency)
        bool isRequired = false; // Headings are not in requiredWidgets.

        // Build the heading widget.
        widgets.add(helpers.buildHeading(level, headingContent, align,
            isRequired: isRequired));
      } else if (command
          .startsWith(RegExp(r'%%AlignPlaceholder', caseSensitive: false))) {
        // Alignment block placeholder.
        final alignInfo = alignPlaceholders[command]!;
        final align = alignInfo['align']!;
        final alignContent = alignInfo['content']!;

        // Check if alignment is required (unlikely)
        bool isRequired = false;

        // Build the aligned text widget.
        widgets.add(helpers.buildAlignedText(align, alignContent,
            isRequired: isRequired));
      } else if (command
          .startsWith(RegExp(r'%% Image', caseSensitive: false))) {
        // Handle image command.
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

          // Image widgets typically don't have names, so cannot be required
          // Thus, isRequired is false
          widgets.add(
              helpers.buildImageWidget(filename, width: width, height: height));
        }
      } else if (command
          .startsWith(RegExp(r'%% Video', caseSensitive: false))) {
        // Handle video command.
        final videoMatch = videoExp.firstMatch(command);
        if (videoMatch != null) {
          final filename = videoMatch.group(1)!.trim();
          // Video widgets typically don't have names, so cannot be required
          // Thus, isRequired is false
          widgets.add(helpers.buildVideoWidget(filename));
        }
      } else if (command
          .startsWith(RegExp(r'%% Audio', caseSensitive: false))) {
        // Handle audio command.
        final audioMatch = audioExp.firstMatch(command);
        if (audioMatch != null) {
          final filename = audioMatch.group(1)!.trim();
          // Audio widgets typically don't have names, so cannot be required
          // Thus, isRequired is false
          widgets.add(helpers.buildAudioWidget(filename));
        }
      } else if (command
          .startsWith(RegExp(r'%% Timer', caseSensitive: false))) {
        // Handle timer command.
        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions,
              isRequired: _requiredWidgets.contains(currentRadioGroupName)));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions,
              isRequired: _requiredWidgets.contains(currentCheckboxGroupName)));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final timerExp = RegExp(r'%% Timer\(([^)]+)\)', caseSensitive: false);
        final timerMatch = timerExp.firstMatch(command);

        if (timerMatch != null) {
          final timeString = timerMatch.group(1)!.trim();

          // Build the timer widget.
          widgets.add(helpers.buildTimerWidget(timeString));
        }
      } else if (command
          .startsWith(RegExp(r'%% EmptyLine', caseSensitive: false))) {
        // Handle empty line command.
        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions,
              isRequired: _requiredWidgets.contains(currentRadioGroupName)));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions,
              isRequired: _requiredWidgets.contains(currentCheckboxGroupName)));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        // Add an empty line.
        final lineHeight = DefaultTextStyle.of(context).style.fontSize ?? 16.0;
        widgets.add(SizedBox(height: lineHeight));
      } else if (command
          .startsWith(RegExp(r'%% Slider', caseSensitive: false))) {
        // Handle slider command.
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

          // Store the slider parameters.
          _sliders[name] = {
            'min': min,
            'max': max,
            'defaultValue': defaultValue,
            'step': step,
          };

          // Initialise the slider value.
          if (!_sliderValues.containsKey(name)) {
            _sliderValues[name] = defaultValue;
          }

          // Check if the slider is required.
          bool isRequired = _requiredWidgets.contains(name);

          // Build the slider widget.
          widgets.add(helpers.buildSlider(name, isRequired: isRequired));
        }
      } else if (command.startsWith('%% Button')) {
        // Handle button command.
        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions,
              isRequired: _requiredWidgets.contains(currentRadioGroupName)));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions,
              isRequired: _requiredWidgets.contains(currentCheckboxGroupName)));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        // Create the ButtonWidget, passing the command and state variables.
        widgets.add(
          ButtonWidget(
            command: command,
            requiredWidgets: [],
            state: state,
            surveyTitle: surveyTitle,
          ),
        );
      } else if (command
          .startsWith(RegExp(r'%%ButtonPlaceholder', caseSensitive: false))) {
        // Handle button placeholder.
        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions,
              isRequired: _requiredWidgets.contains(currentRadioGroupName)));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }
        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions,
              isRequired: _requiredWidgets.contains(currentCheckboxGroupName)));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        // Get the actual button command and required widgets.
        final buttonInfo = buttonPlaceholders[command]!;
        final commandStr = buttonInfo['command']!;
        final requiredWidgetsStr = buttonInfo['requiredWidgets']!;

        // Parse the required widgets list.
        List<String> requiredWidgets =
        _parseRequiredWidgets(requiredWidgetsStr);

        // Create the ButtonWidget.
        widgets.add(
          ButtonWidget(
            command: '%% Button($commandStr)',
            requiredWidgets: requiredWidgets,
            state: state,
            surveyTitle: surveyTitle,
          ),
        );
      } else if (command
          .startsWith(RegExp(r'%%HiddenPlaceholder', caseSensitive: false))) {
        // Handle hidden content placeholder.
        final hiddenPlaceholderExp =
        RegExp(r'%%HiddenPlaceholder\(([^)]+)\)%%', caseSensitive: false);
        final placeholderMatch = hiddenPlaceholderExp.firstMatch(command);

        if (placeholderMatch != null) {
          final id = placeholderMatch.group(1)!.trim();
          final hiddenContent = _hiddenContentMap[id] ?? '';

          if (!_hiddenContentVisibility.containsKey(id)) {
            _hiddenContentVisibility[id] = false;
          }

          // Parse the hidden content.
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

          widgets.add(
            Visibility(
              visible: _hiddenContentVisibility[id] ?? false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: hiddenWidgets,
              ),
            ),
          );
        }
      } else if (command
          .startsWith(RegExp(r'%% Radio', caseSensitive: false))) {
        // Handle radio command.
        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions,
              isRequired: _requiredWidgets.contains(currentCheckboxGroupName)));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final radioExp = RegExp(
          r'%% Radio\(([^,]+),\s*([^,]+),\s*"((?:[^"\\]|\\.)*)"(?:,\s*([^)]+))?\)',
          caseSensitive: false,
        );

        final radioMatch = radioExp.firstMatch(command);

        if (radioMatch != null) {
          final name = radioMatch.group(1)!.trim();
          final value = radioMatch.group(2)!.trim();

          // Process the label parameter.
          String label = radioMatch.group(3)!;
          label = label.replaceAll(r'\"', '"');
          label = label.replaceAll('\n', ' ');
          label = label.trim();

          // Get the optional hidden content ID.
          String? hiddenContentId = radioMatch.group(4)?.trim();

          if (currentRadioGroupName == null || currentRadioGroupName != name) {
            // Build previous radio group.
            if (currentRadioGroupName != null) {
              widgets.add(helpers.buildRadioGroup(
                  currentRadioGroupName, currentRadioOptions,
                  isRequired: _requiredWidgets.contains(currentRadioGroupName)));
              currentRadioGroupName = null;
              currentRadioOptions = [];
            }

            currentRadioGroupName = name;

            // Initialise the selected value of the group.
            if (!_radioValues.containsKey(name)) {
              _radioValues[name] = null;
            }
          }

          // Add options to the current group.
          currentRadioOptions.add({
            'value': value,
            'label': label,
            'hiddenContentId': hiddenContentId,
          });

          // Check if the next command belongs to the same group.
          bool isLastOption = true;

          if (i + 1 < matches.length) {
            final nextMatch = matches[i + 1];
            final nextCommand = nextMatch.group(0)!;
            final nextRadioMatch = radioExp.firstMatch(nextCommand);
            if (nextRadioMatch != null) {
              final nextName = nextRadioMatch.group(1)!.trim();
              if (nextName.toLowerCase() ==
                  currentRadioGroupName.toLowerCase()) {
                isLastOption = false;
              }
            }
          }

          // If there are no more options, build the radio group.
          if (isLastOption) {
            widgets.add(helpers.buildRadioGroup(
                currentRadioGroupName, currentRadioOptions,
                isRequired: _requiredWidgets.contains(currentRadioGroupName)));
            currentRadioGroupName = null;
            currentRadioOptions = [];
          }
        }
      } else if (command
          .startsWith(RegExp(r'%% Checkbox', caseSensitive: false))) {
        // Handle checkbox command.
        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions,
              isRequired: _requiredWidgets.contains(currentRadioGroupName)));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        final checkboxExp = RegExp(
          r'%% Checkbox\(([^,]+),\s*([^,]+),\s*"((?:[^"\\]|\\.)*)"(?:,\s*([^)]+))?\)',
          caseSensitive: false,
        );

        final checkboxMatch = checkboxExp.firstMatch(command);

        if (checkboxMatch != null) {
          final name = checkboxMatch.group(1)!.trim();
          final value = checkboxMatch.group(2)!.trim();

          // Process the label parameter.
          String label = checkboxMatch.group(3)!;
          label = label.replaceAll(r'\"', '"');
          label = label.replaceAll('\n', ' ');
          label = label.trim();

          // Get the optional hidden content ID.
          String? hiddenContentId = checkboxMatch.group(4)?.trim();

          if (currentCheckboxGroupName == null ||
              currentCheckboxGroupName != name) {
            // Build previous checkbox group.
            if (currentCheckboxGroupName != null) {
              widgets.add(helpers.buildCheckboxGroup(
                  currentCheckboxGroupName, currentCheckboxOptions,
                  isRequired: _requiredWidgets.contains(currentCheckboxGroupName)));
              currentCheckboxOptions = [];
            }

            currentCheckboxGroupName = name;

            // Initialise the selected values of the group.
            if (!_checkboxValues.containsKey(name)) {
              _checkboxValues[name] = {};
            }
          }

          // Add options to the current group.
          currentCheckboxOptions.add({
            'value': value,
            'label': label,
            'hiddenContentId': hiddenContentId,
          });

          // Check if the next command belongs to the same group.
          bool isLastOption = true;
          if (i + 1 < matches.length) {
            final nextMatch = matches[i + 1];
            final nextCommand = nextMatch.group(0)!;
            final nextCheckboxMatch = checkboxExp.firstMatch(nextCommand);
            if (nextCheckboxMatch != null) {
              final nextName = nextCheckboxMatch.group(1)!.trim();
              if (nextName.toLowerCase() ==
                  currentCheckboxGroupName.toLowerCase()) {
                isLastOption = false;
              }
            }
          }

          // If there are no more options, build the checkbox group.
          if (isLastOption) {
            widgets.add(helpers.buildCheckboxGroup(
                currentCheckboxGroupName, currentCheckboxOptions,
                isRequired: _requiredWidgets.contains(currentCheckboxGroupName)));
            currentCheckboxGroupName = null;
            currentCheckboxOptions = [];
          }
        }
      } else if (command
          .startsWith(RegExp(r'%% Calendar', caseSensitive: false))) {
        // Handle calendar command.
        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions,
              isRequired: _requiredWidgets.contains(currentRadioGroupName)));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions,
              isRequired: _requiredWidgets.contains(currentCheckboxGroupName)));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final calendarExp =
        RegExp(r'%% Calendar\(([^)]+)\)', caseSensitive: false);
        final calendarMatch = calendarExp.firstMatch(command);

        if (calendarMatch != null) {
          final name = calendarMatch.group(1)!.trim();

          // Initialise date value.
          if (!_dateValues.containsKey(name)) {
            _dateValues[name] = null;
          }

          // Check if calendar is required.
          bool isRequired = _requiredWidgets.contains(name);

          // Build the calendar field.
          widgets.add(helpers.buildCalendarField(name, isRequired: isRequired));
        }
      } else if (command
          .startsWith(RegExp(r'%% Dropdown', caseSensitive: false))) {
        // Handle dropdown command.
        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions,
              isRequired: _requiredWidgets.contains(currentRadioGroupName)));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions,
              isRequired: _requiredWidgets.contains(currentCheckboxGroupName)));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final dropdownExp =
        RegExp(r'%% Dropdown\(([^)]+)\)', caseSensitive: false);
        final dropdownMatch = dropdownExp.firstMatch(command);

        if (dropdownMatch != null) {
          final name = dropdownMatch.group(1)!.trim();

          // Initialise dropdown options and selected value.
          if (!_dropdownValues.containsKey(name)) {
            _dropdownValues[name] = null;
          }

          if (!_dropdownOptions.containsKey(name)) {
            _dropdownOptions[name] = [];
          }

          // Parse the options from the following markdown list.
          int optionsStartIndex = match.end;
          int optionsEndIndex = modifiedContent.length;

          // Look ahead to find where the options list ends. It ends when a line
          // does not start with '-' or the next command starts.
          final lines =
          modifiedContent.substring(optionsStartIndex).split('\n');
          final List<String> options = [];
          int lineOffset = 0;

          for (var line in lines) {
            final trimmedLine = line.trim();
            if (trimmedLine.startsWith('- ')) {
              options.add(trimmedLine.substring(2).trim());
              lineOffset += line.length + 1; // +1 for the newline character
            } else if (trimmedLine.isEmpty) {
              lineOffset += line.length + 1;
            } else {
              // Non-list item or next command
              break;
            }
          }

          optionsEndIndex = optionsStartIndex + lineOffset;

          _dropdownOptions[name] = options;

          // Check if dropdown is required.
          bool isRequired = _requiredWidgets.contains(name);

          // Build the dropdown widget.
          widgets.add(helpers.buildDropdown(name, options,
              isRequired: isRequired));

          // Update the lastIndex to the end of the options list.
          lastIndex = optionsEndIndex;

          // Skip updating lastIndex again at the end of loop.
          continue;
        }
      } else if (command
          .startsWith(RegExp(r'%% InputSL', caseSensitive: false))) {
        // Handle single-line input field.
        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions,
              isRequired: _requiredWidgets.contains(currentRadioGroupName)));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions,
              isRequired: _requiredWidgets.contains(currentCheckboxGroupName)));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final inputSLExp =
        RegExp(r'%% InputSL\(([^)]+)\)', caseSensitive: false);
        final inputSLMatch = inputSLExp.firstMatch(command);

        if (inputSLMatch != null) {
          final name = inputSLMatch.group(1)!.trim();

          // Initialise the input value.
          if (!_inputValues.containsKey(name)) {
            _inputValues[name] = '';
          }

          // Check if input field is required.
          bool isRequired = _requiredWidgets.contains(name);

          widgets.add(
              helpers.buildInputField(name, isMultiLine: false, isRequired: isRequired));
        }
      } else if (command
          .startsWith(RegExp(r'%% InputML', caseSensitive: false))) {
        // Handle multi-line input field.
        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions,
              isRequired: _requiredWidgets.contains(currentRadioGroupName)));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions,
              isRequired: _requiredWidgets.contains(currentCheckboxGroupName)));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        final inputMLExp =
        RegExp(r'%% InputML\(([^)]+)\)', caseSensitive: false);
        final inputMLMatch = inputMLExp.firstMatch(command);

        if (inputMLMatch != null) {
          final name = inputMLMatch.group(1)!.trim();

          // Initialise the input value.
          if (!_inputValues.containsKey(name)) {
            _inputValues[name] = '';
          }

          // Check if input field is required.
          bool isRequired = _requiredWidgets.contains(name);

          widgets.add(
              helpers.buildInputField(name, isMultiLine: true, isRequired: isRequired));
        }
      }

      lastIndex = match.end;
    }

    // Parse the markdown content after the last custom command.
    if (lastIndex < modifiedContent.length) {
      String markdownContent = modifiedContent.substring(lastIndex);
      if (markdownContent.trim().isNotEmpty) {
        if (currentRadioGroupName != null) {
          widgets.add(helpers.buildRadioGroup(
              currentRadioGroupName, currentRadioOptions,
              isRequired: _requiredWidgets.contains(currentRadioGroupName)));
          currentRadioGroupName = null;
          currentRadioOptions = [];
        }

        if (currentCheckboxGroupName != null) {
          widgets.add(helpers.buildCheckboxGroup(
              currentCheckboxGroupName, currentCheckboxOptions,
              isRequired: _requiredWidgets.contains(currentCheckboxGroupName)));
          currentCheckboxGroupName = null;
          currentCheckboxOptions = [];
        }

        // If there is no menu, the content after the menu will need to be
        // shown.
        if (!_hasMenu || isParsingHiddenContent) {
          widgets.add(MarkdownText(data: markdownContent));
        }
      }
    }

    // Build any unfinished radio or checkbox groups (if any).
    if (currentRadioGroupName != null) {
      widgets.add(
          helpers.buildRadioGroup(currentRadioGroupName, currentRadioOptions,
              isRequired: _requiredWidgets.contains(currentRadioGroupName)));
    }

    if (currentCheckboxGroupName != null) {
      widgets.add(helpers.buildCheckboxGroup(
          currentCheckboxGroupName, currentCheckboxOptions,
          isRequired: _requiredWidgets.contains(currentCheckboxGroupName)));
    }

    // Add some space at the end.
    final lineHeight = DefaultTextStyle.of(context).style.fontSize ?? 16.0;
    // Define the number of ending lines, assuming 1 for now
    const int endingLines = 1;
    widgets.add(SizedBox(height: lineHeight * endingLines));

    return widgets;
  }

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
}
