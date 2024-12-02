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

  Widget buildDescriptionBox(String content) {
    return DescriptionBox(content: content);
  }

  Widget buildHeading(int level, String content, String align) {
    return TextHeadingWidget(level: level, content: content, align: align);
  }

  Widget buildAlignedText(String align, String content) {
    return TextAlignmentWidget(align: align, content: content);
  }

  Widget buildImageWidget(String filename, {double? width, double? height}) {
    return ImageWidget(
      filename: filename,
      width: width,
      height: height,
    );
  }

  Widget buildVideoWidget(String filename) {
    return VideoWidget(filename: filename);
  }

  Widget buildAudioWidget(String filename) {
    return AudioWidget(filename: filename);
  }

  Widget buildTimerWidget(String timeString) {
    final totalSeconds = parseTimeString(timeString);
    if (totalSeconds <= 0) {
      return const Text('Invalid timer duration');
    }

    return TimerWidget(
      totalSeconds: totalSeconds,
    );
  }

  Widget buildSlider(String name) {
    final sliderInfo = state['_sliders'][name]!;
    final min = sliderInfo['min'];
    final max = sliderInfo['max'];
    final step = sliderInfo['step'];

    return SliderWidget(
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
  }

  Widget buildRadioGroup(String name, List<Map<String, String>> options) {
    return RadioGroup(
      name: name,
      options: options,
      selectedValue: state['_radioValues'][name],
      onChanged: (String? newValue) {
        setStateCallback();
        state['_radioValues'][name] = newValue;
      },
    );
  }

  Widget buildCheckboxGroup(String name, List<Map<String, String>> options) {
    return CheckboxGroup(
      name: name,
      options: options,
      selectedValues: state['_checkboxValues'][name]!,
      onChanged: (Set<String> selectedValues) {
        setStateCallback();
        state['_checkboxValues'][name] = selectedValues;
      },
    );
  }

  Widget buildInputField(String name, {bool isMultiLine = false}) {
    if (!state.containsKey('_inputFieldKeys')) {
      state['_inputFieldKeys'] = {};
    }
    if (!state['_inputFieldKeys'].containsKey(name)) {
      state['_inputFieldKeys'][name] = GlobalKey<InputFieldState>();
    }
    return InputField(
      key: state['_inputFieldKeys'][name],
      name: name,
      initialValue: state['_inputValues'][name],
      isMultiLine: isMultiLine,
      onChanged: (value) {
        state['_inputValues'][name] = value;
      },
    );
  }

  Widget buildCalendarField(String name) {
    return CalendarField(
      name: name,
      initialDate: state['_dateValues'][name],
      onDateSelected: (DateTime? selectedDate) {
        setStateCallback();
        state['_dateValues'][name] = selectedDate;
      },
    );
  }

  Widget buildDropdown(String name, List<String> options) {
    return DropdownWidget(
      name: name,
      options: options,
      value: state['_dropdownValues'][name],
      onChanged: (String? newValue) {
        setStateCallback();
        state['_dropdownValues'][name] = newValue;
      },
    );
  }
}
