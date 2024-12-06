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
import 'package:markdown_widget_builder/src/widgets/radio_group.dart';
import 'package:markdown_widget_builder/src/widgets/slider_widget.dart';
import 'package:markdown_widget_builder/src/widgets/text_alignment_widget.dart';
import 'package:markdown_widget_builder/src/widgets/text_heading_widget.dart';
import 'package:markdown_widget_builder/src/widgets/timer_widget.dart';
import 'package:markdown_widget_builder/src/widgets/video_widget.dart';

class Helpers {
  final BuildContext context;
  final Map<String, dynamic> state;
  final VoidCallback setStateCallback;

  Helpers({
    required this.context,
    required this.state,
    required this.setStateCallback,
  });

  Widget buildDescriptionBox(String content, {bool isRequired = false}) {
    Widget description = DescriptionBox(content: content);
    if (isRequired) {
      return _wrapWithRequired(description);
    } else {
      return description;
    }
  }

  Widget buildHeading(int level, String content, String align,
      {bool isRequired = false}) {
    Widget heading = TextHeadingWidget(level: level, content: content, align: align);
    if (isRequired) {
      return _wrapWithRequired(heading);
    } else {
      return heading;
    }
  }

  Widget buildAlignedText(String align, String content,
      {bool isRequired = false}) {
    Widget alignedText = TextAlignmentWidget(align: align, content: content);
    if (isRequired) {
      return _wrapWithRequired(alignedText);
    } else {
      return alignedText;
    }
  }

  Widget buildImageWidget(String filename,
      {double? width, double? height, bool isRequired = false}) {
    Widget image = ImageWidget(
      filename: filename,
      width: width,
      height: height,
    );
    if (isRequired) {
      return _wrapWithRequired(image);
    } else {
      return image;
    }
  }

  Widget buildVideoWidget(String filename, {bool isRequired = false}) {
    Widget video = VideoWidget(filename: filename);
    if (isRequired) {
      return _wrapWithRequired(video);
    } else {
      return video;
    }
  }

  Widget buildAudioWidget(String filename, {bool isRequired = false}) {
    Widget audio = AudioWidget(filename: filename);
    if (isRequired) {
      return _wrapWithRequired(audio);
    } else {
      return audio;
    }
  }

  Widget buildTimerWidget(String timeString, {bool isRequired = false}) {
    final totalSeconds = parseTimeString(timeString);
    if (totalSeconds <= 0) {
      return const Text('Invalid timer duration');
    }

    Widget timer = TimerWidget(
      totalSeconds: totalSeconds,
    );

    if (isRequired) {
      // For timer, place the label below the widget
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
        setStateCallback();
        state['_sliderValues'][name] = newValue;
      },
    );

    if (isRequired) {
      // For slider, place the label below the widget
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          slider,
          const SizedBox(height: 4.0),
          const Text(
            '(Required)',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else {
      return slider;
    }
  }

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
        setStateCallback();
        state['_radioValues'][name] = newValue;

        // Update hidden content visibility.
        for (var option in options) {
          if (option['hiddenContentId'] != null) {
            final id = option['hiddenContentId']!.trim();
            state['_hiddenContentVisibility'][id] = false;
          }
        }

        if (hiddenContentId != null) {
          final id = hiddenContentId.trim();
          state['_hiddenContentVisibility'][id] = true;
        }
      },
      isRequired: isRequired,
    );
  }

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
        setStateCallback();
        state['_checkboxValues'][name] = selectedValues;

        // Update hidden content visibility.
        for (var option in options) {
          if (option['hiddenContentId'] != null) {
            final id = option['hiddenContentId']!.trim();
            if (selectedValues.contains(option['value'])) {
              state['_hiddenContentVisibility'][id] = true;
            } else {
              state['_hiddenContentVisibility'][id] = false;
            }
          }
        }
      },
      isRequired: isRequired,
    );
  }

  Widget buildInputField(String name,
      {bool isMultiLine = false, bool isRequired = false}) {
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
      },
    );

    if (isRequired) {
      return _wrapWithRequired(inputField);
    } else {
      return inputField;
    }
  }

  Widget buildCalendarField(String name, {bool isRequired = false}) {
    Widget calendarField = CalendarField(
      name: name,
      initialDate: state['_dateValues'][name],
      onDateSelected: (DateTime? selectedDate) {
        setStateCallback();
        state['_dateValues'][name] = selectedDate;
      },
    );

    if (isRequired) {
      return _wrapWithRequired(calendarField);
    } else {
      return calendarField;
    }
  }

  Widget buildDropdown(String name, List<String> options,
      {bool isRequired = false}) {
    Widget dropdownWidget = DropdownWidget(
      name: name,
      options: options,
      value: state['_dropdownValues'][name],
      onChanged: (String? newValue) {
        setStateCallback();
        state['_dropdownValues'][name] = newValue;
      },
    );

    if (isRequired) {
      return _wrapWithRequired(dropdownWidget);
    } else {
      return dropdownWidget;
    }
  }

  // Helper method to wrap a widget with a (Required) label within central content area.
  Widget _wrapWithRequired(Widget widget) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '(Required)',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4.0),
            widget,
          ],
        ),
      ),
    );
  }
}
