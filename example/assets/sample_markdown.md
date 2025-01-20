%% Menu-Begin
- Survey 1
- Survey 2
- Survey 3
- Survey 4
%% Menu-End

## Survey 1

%% Description-Begin
This survey is an example survey about **selection widgets**, including a date
pickers, a dropdown menu, some radio buttons and checkboxes.
%% Description-End

%% EmptyLine

Please select a date from the date picker.

%% Calendar(Date)

%% EmptyLine

Please select an option from the dropdown menu.

%% Dropdown(Dropdown Menu)
- Option 1
- Option 2
- Option 3
- Option 4

%% EmptyLine

1. This is Question 1. The following four options belong to the same group.
   Only one option can be selected.

%% Radio(Question 1,1,"Option 1. This is a long option that may wrap to the next
line if it needs to. When wrapping it does so indented to align the paragraph.
This example also demonstrates the use of escape characters, such as \".")

%% Radio(Question 1,2,"Option 2. Escape characters can also be used in the
label, such as \( and \).")

%% Radio(Question 1,3,"Option 3")

%% Radio(Question 1,4,"Option 4")

%% EmptyLine

2. This is Question 2. Only one option can be selected. The following four 
   options belong to a different group from Question 1, and the user's 
   selections for these two groups are independent and will not affect each 
   other. 

%% Radio(Question 2,1,"Option 1. If you choose this option, you will need to 
answer a follow-up question.",Hidden 1)

%% Radio(Question 2,2,"Option 2. If you choose this option, you will need to
answer another follow-up question.",Hidden 2)

%% Radio(Question 2,3,"Option 3")

%% Radio(Question 2,4,"Option 4")

%% Hidden-Begin(Hidden 1)
This is a follow-up question for Option 1.
%% InputML(Question 2.1)
%% Hidden-End

%% Hidden-Begin(Hidden 2)
This is a follow-up question for Option 2.
%% InputML(Question 2.2)
%% Hidden-End

%% EmptyLine

3. The following are two groups of checkboxes. This is Question 3. Multiple 
   options can be selected.

%% Checkbox(Question 3,1,"Option 1 This is a long option that may wrap to the
next line if it needs to. When wrapping it does so indented to align the
paragraph. This example also demonstrates the use of escape characters, such
as \".")

%% Checkbox(Question 3,2,"Option 2. If you choose this option, you will need to
answer another follow-up question.",Hidden 3)

%% Checkbox(Question 3,3,"Option 3")

%% Checkbox(Question 3,4,"Option 4")

%% Checkbox(Question 3,5,"Option 5")

%% Checkbox(Question 3,6,"Option 6")

%% Hidden-Begin(Hidden 3)
This is a follow-up question for Option 2.
%% InputML(Question 3.2)
%% Hidden-End

%% EmptyLine

4. This is Question 4. Multiple options can be selected as well. (Required)

%% Checkbox(Question 4,1,"Option 1")

%% Checkbox(Question 4,2,"Option 2")

%% Checkbox(Question 4,3,"Option 3")

%% Checkbox(Question 4,4,"Option 4")

%% Checkbox(Question 4,5,"Option 5")

%% Checkbox(Question 4,6,"Option 6")

%% EmptyLine

%% EmptyLine

%% Description-Begin
The following is a group of buttons, including a **Save** button and a
**Submit** button.

The **Save** button is used to collect all the data filled in by the user in the
survey form and save it to a local JSON file, with the default file name
being the survey's title.

The **Submit** button is used to send the user-filled data to a specified URL
via a POST request. Before submitting, please make sure the data receiving
server is running.
%% Description-End

%% EmptyLine

For saving the data to a local JSON file, the date, the dropdown menu and
Questions 1 and 4 are required.

%% Button-Begin(Save,0)
- Date
- Dropdown Menu
- Question 1
- Question 4
%% Button-End

%% EmptyLine

For submitting the data to a server, Question 1, Question 2 and Question 4 are
required.

%% Button-Begin(Submit,1,http://127.0.0.1:8081/receive-json)
- Question 1
- Question 2
- Question 4
%% Button-End

%% EmptyLine

## Survey 2

%% Description-Begin
The following is a group of **selection sliders**.

In this group of sliders, the survey form designer can customise the maximum 
value, minimum value, default value, and step length of the sliders. They can
also use text formatting commands to add labels to the sliders.
%% Description-End

%% EmptyLine

1. How would you describe your current mood?

   This example includes a group 
   of emojis that are evenly distributed at both ends, as well as a slider with 
   a range from 0 to 100.

%% H1Justify-Begin😭☹️🙂️😄%% H1Justify-End

%% Slider(Question 1,0,100,0,1)

%% EmptyLine

2. How would you rate your satisfaction with us?

   In this example, the minimum value that the user can select is 1, the 
   maximum value is 5, and the default value is 3.

%% AlignJustify-Begin  12345  %% AlignJustify-End

%% Slider(Question 2,1,5,3,1)

%% EmptyLine

3. This example allows the user to select values in increments of 5. The
   minimum value is 0, the maximum value is 50, and the default value is 0.

%% Slider(Question 3,0,50,0,5)

%% EmptyLine

%% EmptyLine

%% EmptyLine

For both saving the data to a local JSON file and submitting the data to a 
server, no question is required.

%% Button-Begin(Save,0)
%% Button-End

%% EmptyLine

%% Button-Begin(Submit,1,http://127.0.0.1:8081/receive-json)
%% Button-End

%% EmptyLine

## Survey 3

%% Description-Begin
The following is an example of a group of **text tools**, including formatted
text marked with Markdown syntax, single-line and multi-line text input boxes,
hyperlinks, text alignment tools, and heading text of different font sizes with
alignment options.
%% Description-End

%% EmptyLine

This paragraph is marked with **Markdown** syntax. You can click
[here](https://www.markdownguide.org/basic-syntax/) to learn more about _Markdown_.

%% EmptyLine

%% Description-Begin
This is a description box. It also supports **Markdown formatted** text
including [hyperlinks](https://www.markdownguide.org/basic-syntax/).
%% Description-End

%% EmptyLine

Next is a set of text examples with different font sizes and alignment options.

%% H1Left-Begin Heading 1 %% H1Left-End

%% H2Left-Begin Heading 2 %% H2Left-End

%% H3Left-Begin Heading 3 %% H3Left-End

%% H4Left-Begin Heading 4 %% H4Left-End

%% H5Left-Begin Heading 5 %% H5Left-End

%% H6Left-Begin Heading 6 %% H6Left-End

%% AlignLeft-Begin Left-aligned text %% AlignLeft-End

%% AlignCenter-Begin Center-aligned text %% AlignCenter-End

%% AlignRight-Begin Right-aligned text %% AlignRight-End

%% AlignJustify-Begin Text justified with words evenly distributed at both ends.
%% AlignJustify-End

%% PageBreak

%% Description-Begin
The following is a single-line input field and a multiple-line input field.
%% Description-End

%% EmptyLine

1. What is your name?

   This is an example of a single-line input box. Users can type or paste,
   but they can only enter a single line of text.

%% InputSL(Question 1)

%% EmptyLine

2. Do you have any feedback or suggestions?

   This is an example of a multiple-line input box. Users can enter multiple
   lines of text.

%% InputML(Question 2)

%% PageBreak

3. This is Question 3. The following four options belong to the same group.
   Only one option can be selected. (Required)

%% Radio(Question 3,1,"Option 1 This is a long option that may wrap to the next
line if it needs to. When wrapping it does so indented to align the paragraph.
This example also demonstrates the use of escape characters, such as \".")

%% Radio(Question 3,2,"Option 2")

%% Radio(Question 3,3,"Option 3")

%% Radio(Question 3,4,"Option 4")

%% EmptyLine

4. This is Question 4. Only one option can be selected. The following four
   options belong to a different group from Question 1, and the user's
   selections for these two groups are independent and will not affect each
   other.

%% Radio(Question 4,1,"Option 1. If you choose this option, you will need to
answer a follow-up question.",Hidden 1)

%% Radio(Question 4,2,"Option 2. If you choose this option, you will need to
answer another follow-up question.",Hidden 2)

%% Radio(Question 4,3,"Option 3")

%% Radio(Question 4,4,"Option 4")

%% Hidden-Begin(Hidden 1)
This is a follow-up question for Option 1.
%% InputML(Question 4.1)
%% Hidden-End

%% Hidden-Begin(Hidden 2)
This is a follow-up question for Option 2.
%% InputML(Question 4.2)
%% Hidden-End

%% EmptyLine

5. The following are two groups of checkboxes. This is Question 5. Multiple
   options can be selected.

%% Checkbox(Question 5,1,"Option 1 This is a long option that may wrap to the
next line if it needs to. When wrapping it does so indented to align the
paragraph. This example also demonstrates the use of escape characters, such
as \".")

%% Checkbox(Question 5,2,"Option 2. If you choose this option, you will need to
answer another follow-up question.",Hidden 3)

%% Checkbox(Question 5,3,"Option 3")

%% Checkbox(Question 5,4,"Option 4")

%% Checkbox(Question 5,5,"Option 5")

%% Checkbox(Question 5,6,"Option 6")

%% Hidden-Begin(Hidden 3)
This is a follow-up question for Option 2.
%% InputML(Question 5.2)
%% Hidden-End

%% EmptyLine

%% EmptyLine

%% EmptyLine

For both saving the data to a local JSON file and submitting the data to a
server, Question 1 is required.

%% Button-Begin(Save,0)
- Question 1
- Question 2
- Question 3
- Question 4
- Question 5
%% Button-End

%% EmptyLine

%% Button-Begin(Submit,1,http://127.0.0.1:8081/receive-json)
- Question 1
- Question 2
- Question 3
- Question 4
- Question 5
%% Button-End

%% EmptyLine

## Survey 4

%% Description-Begin
The following is a group of **multimedia tools**, including audio, video, and
images. These tools can be used to enhance the user experience, add context to
questions, or provide instructions for filling in the survey.
%% Description-End

%% EmptyLine

1. The following is a sample video. It could be an instructional video or a
   video related to the survey content.

%% EmptyLine

%% Video(sample_video.mp4)

%% H6Right-Begin 📍The Birch Building, ANU. Filmed by @tonypioneer.
%% H6Right-End

%% EmptyLine

2. The following is a sample audio. It could be a voice message, background
   music, or an audio clip related to the survey content.

%% Audio(sample_audio.mp3)

%% EmptyLine

3. The following is a sample image. We can use images to enhance the user
experience, or to add context for questions in a survey. The *Original* image 
here means the image is rendered to the width that spans the entire width of
the survey form, maintaining its aspect ratio. The *Resized* image below is
resized to a specific size, being 400 x 300 and 133 x 100 in this case. Note 
that in resizing the image, the aspect ratio is maintained, scaling the width
according to the image height.

%% EmptyLine

%% AlignCenter-Begin Original %% AlignCenter-End

%% Image(sample_image.jpg)

%% H6Right-Begin 📍Hancock Library, ANU. Photo by @tonypioneer. %% H6Right-End

%% AlignCenter-Begin Resized (400 x 300) %% AlignCenter-End

%% Image(sample_image.jpg,400,300)

%% EmptyLine

%% AlignCenter-Begin Resized (133 x 100) %% AlignCenter-End

%% Image(sample_image.jpg,133,100)

%% EmptyLine

%% EmptyLine

%% EmptyLine

%% Button-Begin(Save,0)
%% Button-End

%% EmptyLine

%% Button-Begin(Submit,1,http://127.0.0.1:8081/receive-json)
%% Button-End

%% EmptyLine
