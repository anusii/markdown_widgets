/// Helper methods for markdown widgets.
///
// Time-stamp: <Thursday 2024-11-14 21:33:15 +1100 Graham Williams>
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

import 'package:markdown_widget_builder/src/constants/pkg.dart'
    show contentWidthFactor;
import 'package:markdown_widget_builder/src/utils/parse_time_string.dart';
import 'package:markdown_widget_builder/src/widgets/audio_widget.dart';
import 'package:markdown_widget_builder/src/widgets/calendar_field.dart';
import 'package:markdown_widget_builder/src/widgets/checkbox_group.dart';
import 'package:markdown_widget_builder/src/widgets/description_box.dart';
import 'package:markdown_widget_builder/src/widgets/dropdown_widget.dart';
import 'package:markdown_widget_builder/src/widgets/image_widget.dart';
import 'package:markdown_widget_builder/src/widgets/input_field.dart';
import 'package:markdown_widget_builder/src/widgets/page_break_widget.dart';
import 'package:markdown_widget_builder/src/widgets/radio_group.dart';
import 'package:markdown_widget_builder/src/widgets/slider_widget.dart';
import 'package:markdown_widget_builder/src/widgets/text_alignment_widget.dart';
import 'package:markdown_widget_builder/src/widgets/text_heading_widget.dart';
import 'package:markdown_widget_builder/src/widgets/timer_widget.dart';
import 'package:markdown_widget_builder/src/widgets/video_widget.dart';

/// The Helpers class provides methods for building and wrapping various widgets
/// used in markdown parsing. It encapsulates the logic to handle state changes,
/// add "Required" labels to fields, and integrate user interactions.

class Helpers {
  final BuildContext context;
  final Map<String, dynamic> state;
  final VoidCallback setStateCallback;

  /// Constructor for Helpers.
  ///
  /// - [context]: The Flutter build context.
  /// - [state]: The shared state holding widget values.
  /// - [setStateCallback]: A callback function that triggers a widget rebuild.

  Helpers({
    required this.context,
    required this.state,
    required this.setStateCallback,
  });

  /// Builds a description box widget, optionally marking it as required.

  Widget buildDescriptionBox(String content, {bool isRequired = false}) {
    Widget description = DescriptionBox(content: content);
    if (isRequired) {
      return _wrapWithRequiredLabel(description);
    } else {
      return description;
    }
  }

  /// Builds a heading widget with the specified [level] and [align], optionally
  /// required.

  Widget buildHeading(int level, String content, String align,
      {bool isRequired = false}) {
    Widget heading =
        TextHeadingWidget(level: level, content: content, align: align);
    if (isRequired) {
      return _wrapWithRequiredLabel(heading);
    } else {
      return heading;
    }
  }

  /// Builds a text widget with specified alignment, optionally required.

  Widget buildAlignedText(String align, String content,
      {bool isRequired = false}) {
    Widget alignedText = TextAlignmentWidget(align: align, content: content);
    if (isRequired) {
      return _wrapWithRequiredLabel(alignedText);
    } else {
      return alignedText;
    }
  }

  /// Builds an image widget with optional dimensions and optional required
  /// label.

  Widget buildImageWidget(String filename,
      {double? width, double? height, bool isRequired = false}) {
    Widget image = ImageWidget(
      filename: filename,
      width: width,
      height: height,
    );
    if (isRequired) {
      return _wrapWithRequiredLabel(image);
    } else {
      return image;
    }
  }

  /// Builds a video widget from a specified filename, optionally required.

  Widget buildVideoWidget(String filename, {bool isRequired = false}) {
    Widget video = VideoWidget(filename: filename);
    if (isRequired) {
      return _wrapWithRequiredLabel(video);
    } else {
      return video;
    }
  }

  /// Builds an audio widget from a specified filename, optionally required.

  Widget buildAudioWidget(String filename, {bool isRequired = false}) {
    Widget audio = AudioWidget(filename: filename);
    if (isRequired) {
      return _wrapWithRequiredLabel(audio);
    } else {
      return audio;
    }
  }

  /// Builds a timer widget with the specified time string.
  /// If required, it will add a "(Required)" label.

  Widget buildTimerWidget(String timeString, {bool isRequired = false}) {
    final totalSeconds = parseTimeString(timeString);
    if (totalSeconds <= 0) {
      return const Text('Invalid timer duration');
    }
    Widget timer = TimerWidget(
      totalSeconds: totalSeconds,
    );
    if (isRequired) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          timer,
          const SizedBox(height: 4.0),
          const Text(
            '(Required)',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else {
      return timer;
    }
  }

  /// Builds a slider widget tied to the specified [name], optionally required.

  Widget buildSlider(String name, {bool isRequired = false}) {
    final sliderInfo = state['_sliders'][name]!;
    final min = sliderInfo['min'];
    final max = sliderInfo['max'];
    final step = sliderInfo['step'];

    Widget slider = SliderWidget(
      name: name,
      value: state['_sliderValues'][name]!,
      min: min,
      max: max,
      step: step,
      onChanged: (newValue) {
        state['_sliderValues'][name] = newValue;
        setStateCallback();
      },
    );

    if (isRequired) {
      return _wrapWithRequiredLabel(slider, labelAbove: true);
    } else {
      return slider;
    }
  }

  /// Builds a radio group widget with given [options]. The state of selected
  /// value and hidden content visibility is handled here.

  Widget buildRadioGroup(
    String name,
    List<Map<String, String?>> options, {
    bool isRequired = false,
  }) {
    return RadioGroup(
      name: name,
      options: options,
      selectedValue: state['_radioValues'][name],
      onChanged: (String? newValue, String? hiddenContentId) {
        state['_radioValues'][name] = newValue;

        // Hide all hidden content first.

        for (var option in options) {
          if (option['hiddenContentId'] != null) {
            final id = option['hiddenContentId']!.trim();
            state['_hiddenContentVisibility'][id] = false;
          }
        }

        // Show the hidden content related to the newly selected option.

        if (hiddenContentId != null) {
          final id = hiddenContentId.trim();
          state['_hiddenContentVisibility'][id] = true;
        }

        setStateCallback();
      },
      isRequired: isRequired,
    );
  }

  /// Builds a checkbox group widget with given [options]. Selected values and
  /// visibility of hidden content is managed here.

  Widget buildCheckboxGroup(
    String name,
    List<Map<String, String?>> options, {
    bool isRequired = false,
  }) {
    return CheckboxGroup(
      name: name,
      options: options,
      selectedValues: state['_checkboxValues'][name]!,
      onChanged: (Set<String> selectedValues, Set<String> hiddenContentIds) {
        state['_checkboxValues'][name] = selectedValues;

        // Update visibility for hidden content based on selected checkboxes.

        for (var option in options) {
          if (option['hiddenContentId'] != null) {
            final id = option['hiddenContentId']!.trim();
            state['_hiddenContentVisibility'][id] =
                selectedValues.contains(option['value']);
          }
        }

        setStateCallback();
      },
      isRequired: isRequired,
    );
  }

  /// Builds an input field (single or multi-line) and updates state on changes.

  Widget buildInputField(String name,
      {bool isMultiLine = false, bool isRequired = false}) {
    // Initialise a global key for the input field if not present.

    if (!state.containsKey('_inputFieldKeys')) {
      state['_inputFieldKeys'] = {};
    }
    if (!state['_inputFieldKeys'].containsKey(name)) {
      state['_inputFieldKeys'][name] = GlobalKey<InputFieldState>();
    }

    Widget inputField = InputField(
      key: state['_inputFieldKeys'][name],
      name: name,
      initialValue: state['_inputValues'][name],
      isMultiLine: isMultiLine,
      onChanged: (value) {
        state['_inputValues'][name] = value;
        setStateCallback();
      },
    );

    if (isRequired) {
      return _wrapWithRequiredLabel(inputField);
    } else {
      return inputField;
    }
  }

  /// Builds a calendar field, allowing users to select a date. The selection
  /// updates state accordingly.

  Widget buildCalendarField(String name, {bool isRequired = false}) {
    Widget calendarField = CalendarField(
      name: name,
      initialDate: state['_dateValues'][name],
      onDateSelected: (DateTime? selectedDate) {
        state['_dateValues'][name] = selectedDate;
        setStateCallback();
      },
    );

    if (isRequired) {
      return _wrapWithRequiredLabel(calendarField);
    } else {
      return calendarField;
    }
  }

  /// Builds a dropdown widget with given [options]. Updates state on selection
  /// changes.

  Widget buildDropdown(String name, List<String> options,
      {bool isRequired = false}) {
    Widget dropdownWidget = DropdownWidget(
      name: name,
      options: options,
      value: state['_dropdownValues'][name],
      onChanged: (String? newValue) {
        state['_dropdownValues'][name] = newValue;
        setStateCallback();
      },
    );

    if (isRequired) {
      return _wrapWithRequiredLabel(dropdownWidget);
    } else {
      return dropdownWidget;
    }
  }

  /// Builds a page break widget with navigation callbacks, useful for
  /// multi-page forms.

  Widget buildPageBreakWidget({
    required int currentPage,
    required int totalPages,
    required VoidCallback onNext,
    required VoidCallback onPrev,
  }) {
    return PageBreakWidget(
      currentPage: currentPage,
      totalPages: totalPages,
      onNext: onNext,
      onPrev: onPrev,
    );
  }

  /// Private helper method to wrap a widget with a "(Required)" label.
  /// If [labelAbove] is true, the label is placed above the widget;
  /// otherwise, below the widget.

  Widget _wrapWithRequiredLabel(Widget widget, {bool labelAbove = true}) {
    List<Widget> children = [];

    if (labelAbove) {
      children.add(
        const Center(
          child: FractionallySizedBox(
            widthFactor: contentWidthFactor,
            child: Text(
              '(Required)',
              textAlign: TextAlign.left,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
      children.add(const SizedBox(height: 4.0));
      children.add(widget);
    } else {
      children.add(widget);
      children.add(const SizedBox(height: 4.0));
      children.add(
        const Center(
          child: FractionallySizedBox(
            widthFactor: contentWidthFactor,
            child: Text(
              '(Required)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
