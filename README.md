[![Flutter](https://img.shields.io/badge/Made%20with-Flutter-blue.svg)](https://flutter.dev/)
[![Pub Package](https://img.shields.io/pub/v/markdown_widget_builder)](https://pub.dev/packages/markdown_widget_builder)
[![GitHub Issues](https://img.shields.io/github/issues/anusii/markdown_widget_builder)](https://github.com/anusii/markdown_widget_builder/issues)
[![GitHub License](https://img.shields.io/github/license/anusii/markdown_widget_builder)](https://raw.githubusercontent.com/anusii/markdown_widget_builder/main/LICENSE)

# Markdown Widget Builder

This package is designed to define human-computer interaction widgets
to build a Flutter widget as a markdown page using a markdown-like
syntax, making it suitable for use in surveys and similar scenarios.

The following is the syntax to generate interactive surveys in
markdown pages.

## Survey Menu

`%% Menu-Begin` and `%% Menu-End` will be recognised as the beginning and
end of the menu. The content between this group of tags must be a list, and
each item in the list will be recognised as a separate survey. The content of
each survey needs to be defined in the subsequent sections of the markdown
file, with the same name used as the title.

For example, the following snippet from the markdown file:

```markdown
%% Menu-Begin
- GAD-7 Survey
- PHQ-9 Survey
- Symptom Checker
%% Menu-End

## GAD-7 Survey
Description: The Generalized Anxiety Disorder 7 (GAD-7) is a self-report
questionnaire used to assess the severity of generalized anxiety disorder (GAD).

## PHQ-9 Survey
Description: The Patient Health Questionnaire 9 (PHQ-9) is a self-report
questionnaire used to assess the severity of depression.

## Symptom Checker
Description: The Symptom Checker is a self-report questionnaire used to assess
the severity of symptoms.
```

will generate a list of surveys with the titles `GAD-7 Survey`, `PHQ-9 Survey`,
and `Symptom Checker`. If users click on any of these surveys, they will be
redirected to the `Survey Details` page with the corresponding survey details.

## Slider Bar

`%% Slider(name,min,max,defaultValue,step)` will be recognised as a slider bar
with the given `name`, `min`, `max`, `defaultValue`, and `step` values. The
slider bar will be displayed on the `Survey Details` page.

For example, the following snippet from the markdown file:

```markdown
%% Slider(Question 1,1,4,1,1)
```

## Button

`%% Button-Begin(label,type,path)` and `%% Button-End` will be recognised as a 
button. The parameter `label` is the text displayed on the button, `type` is 
the type of the button (0 - Save to JSON file (default), 1 - Submit to URL),
and `path` is the path to redirect to or save to when the button is clicked. The
default file name is `result.json`. The button will be displayed on the
`Survey Details` page.

Between the `Button-Begin` and `Button-End` tags is a list of widget IDs 
containing all required fields. When the button is clicked, the widget will 
check if all required fields are filled in. If all required fields are filled
in, the widget will save the data to the specified path or submit it to the
specified URL. If any required fields are not filled in, the widget will display
an error message and prevent the data from being saved or submitted.

For example, the following snippet from the markdown file:

```markdown
%% Button-Begin(Save,0)
- Question 1
- Question 4
%% Button-End
```

## Radio Button

`%% Radio(name,value,label,hidden)` will be recognised as a radio button with
the given `name`, `value`, `label` and `hidden_content`. Users can use escape 
characters `\(`, `\)`, and `\"` to display parentheses and quotation marks 
in the label. The radio button will be displayed on the `Survey Details` page.

For example, the following snippet from the markdown file:

```markdown
%% Radio(Radio1,1,"Option 1")
%% Radio(Radio1,2,"Option 2 \(Recommended\)",Hidden 1)
```

## Checkbox

`%% Checkbox(name,value,label,hidden)` will be recognised as a checkbox with
the given `name`, `value`, `label` and `hidden_content`. Users can use escape
characters `\(`, `\)`, and `\"` to display parentheses and quotation marks
in the label. The checkbox will be displayed on the `Survey Details` page.

For example, the following snippet from the markdown file:

```markdown
%% Checkbox(Checkbox1,A,"Option 1")
%% Checkbox(Checkbox1,B,"Option 2 \(Recommended\)")
%% Checkbox(Checkbox1,C,"Option 3",Hidden 1)
```

## Hidden

If the user needs to answer the next question after selecting a specific radio
button or checkbox, you can use the `%% Hidden` command. The `Hidden` command
consists of two parts: `Hidden-Begin` and `Hidden-End`. The content to be
hidden is placed between these two parts.

For example, the following snippet from the markdown file:

```markdown
%% Hidden-Begin(Hidden 1)
Please answer the following question after selecting Option 1.
InputML(HiddenQuestion)
%% Hidden-End
```

In this example, `Hidden 1` is the ID of the hidden content. We can add
arguments to the `%% Radio` or `%% Checkbox` command to bind this hidden
content. The specific approach is as follows:

```markdown
%% Radio(Radio1,1,"Option 1",Hidden 1)
%% Checkbox(Checkbox1,A,"Option 1",Hidden 1)
```

## Input Box

`%% InputSL(name)` will be recognised as a single-line input box with the
given `name`, and `%% InputML(name)` will be recognised as a multi-line input
box with the given `name`. The input box will be displayed on the `Survey 
Details` page.

For example, the following snippet from the markdown file:

```markdown
Your name:
%% InputSL(Name)
Your feedback:
%% InputML(Feedback)
```

## Description Box

`%% Description-Begin` and `%% Description-End` will be recognised as the
beginning and end of the description box. The content between these tags will
be displayed on the `Survey Details` page.

For example, the following snippet from the markdown file:

```markdown
%% Description-Begin

Over the **last 2 weeks**, how often have you been bothered by the following
problems? Tap your answers.

%% Description-End
```

## Calendar

`%% Calendar(name)` will be recognised as a calendar with the name `name` and
will be displayed on the `Survey Details` page.

For example, the following snippet from the markdown file:

```markdown
%% Calendar(Date)
```

## Dropdown

`%% Dropdown(name)` will be recognised as a dropdown with the name `name` and
will be displayed on the `Survey Details` page. The content of the dropdown
needs to be defined in the subsequent sections of the markdown file as a list.

For example, the following snippet from the markdown file:

```markdown

%% Dropdown(Dropdown1)
- Option 1
- Option 2
- Option 3
```

## Font Size

`%% H1-Begin` and `%% H1-End` will be recognised as the beginning and end of
the H1 font size. The content between these tags will be displayed in H1 font
size on the `Survey Details` page. Similarly, H2 to H6 font sizes are also
supported here.

For example, the following snippet from the markdown file:

```markdown
%% H1-Begin
Text in H1 font size
%% H1-End
```

## Text Alignment

`%% AlignRight-Begin` and `%% AlignRight-End` will be recognised as the
beginning and end of the right-aligned text. The content between these tags
will be displayed as right-aligned text on the `Survey Details` page. Similarly,
left-aligned, center-aligned and justified text alignments are also supported
here. The syntax for these are `%% AlignLeft-Begin`, `%% AlignCenter-Begin`, and
`%% AlignJust-Begin` respectively.

For example, the following snippet from the markdown file:

```markdown
%% AlignRight-Begin
Text aligned to the right
%% AlignRight-End
```

## Adjust Font Size and Text Alignment at the Same Time

`%% H1Right-Begin` and `%% H1Right-End` will be recognised as the beginning and
end of the H1 font size and right-aligned text. The content between these tags
will be displayed in H1 font size and right-aligned on the `Survey Details`
page. Similarly, H2 to H6 font sizes and left/right/center/justify-aligned text
are also supported here. The syntax for these are `% H1Left-Begin`,
`%% H1Center-Begin`, and `%% H1Just-Begin` respectively.

For example, the following snippet from the markdown file:

```markdown
%% H1Right-Begin
Text in H1 font size and right-aligned
%% H1Right-End
```

## Image

`%% Image(filename.jpg)` will be recognised as an image with the given
filename in `assets/media` folder. The image will be displayed on the `Survey
Details` page.

For example, the following snippet from the markdown file:

```markdown
%% Image(image.jpg)
```

## Video

`%% Video(filename.mp4)` will be recognised as a video with the given
filename in `assets/media` folder. The video will be displayed on the `Survey
Details` page.

For example, the following snippet from the markdown file:

```markdown
%% Video(video.mp4)
```

## Audio

`%% Audio(filename.mp3)` will be recognised as an audio file with the given
filename in `assets/media` folder. The audio file will be displayed on the
`Survey Details` page.

For example, the following snippet from the markdown file:

```markdown
%% Audio(audio.mp3)
```

## Countdown Timer

`%% Timer(time)` will be recognised as a countdown timer with the given
`time` in the format of 1h0m0s. The countdown timer will be displayed on the
`Survey Details` page.

For example, the following snippet from the markdown file:

```markdown
%% Timer(1h0m0s)
```

## Empty Line

`%% EmptyLine` will be recognised as an empty line. An empty line will be
displayed on the `Survey Details` page.

For example, the following snippet from the markdown file:

```markdown
%% EmptyLine
```

## Pagination

`%% PageBreak` will be recognised as a page break. The content after the
`PageBreak` tag will be displayed on the next page.

For example, the following snippet from the markdown file:

```markdown
%% PageBreak
```
