## Example Usage of MarkdownWidgets

See (lib/main.dart) for a simple example.

Run it with:

```
cd example
flutter create .
flutter run
```

If you want to test submitting the form results to the server via
POST, please run `make server` first. The server requires python
installed and the python packages flask and flask_cors installed.

## Config File

Users can customise the paths for markdown files and media files by modifying
the `config.json` file. The `config.json` file is located in the `assets`
folder.

The `config.json` file contains the following fields:

- `markdown`: The path and the type of the markdown file.
- `media`: The path and the type of the media file.

The path field supports both relative and absolute paths. If the path is
relative, the path is relative to the same level directory of app file, which
may be the debug folder or the release folder. The markdown file and media
file should be copied into the folder before running the app.

The type field supports the following values:
- `local`: The file is stored locally.
- `pod`: The file is stored in a POD.

When the paths for the markdown file and media files are not specified in the
`config.json` file, the app will load the `assets/surveys/surveys.md` markdown
file and the media files under `assets/surveys/media/` after running by default.

The following is the config.json file in this scenario.

```json
{
  "markdown": {
    "path": "",
    "type": "local"
  },
  "media": {
    "path": "",
    "type": "local"
  }
}
```

Note: When files are located in Flutter's assets directory, the app cannot
monitor changes to these files, and therefore, it cannot perform hot reload on
the file contents. Restarting the app is required to load the updated file
contents. However, if the user specifies the exact file paths in the
`config.json` file, the app can monitor changes to the files and perform hot
reload on their contents.

If we manually specify the file location in config.json, this location will
override the default file location. The `config.json` file supports both
absolute and relative paths. If a relative path is specified, it is relative to
the directory where the app is located. For macOS, this would be
`/Users/someone/.../markdown_widget_builder/example/build/macos/Build/Products/Debug/surveys.md`.
Below is an example of the config.json file used in this scenario.

```json
{
  "markdown": {
    "path": "surveys.md",
    "type": "local"
  },
  "media": {
    "path": "media",
    "type": "local"
  }
}
```

We can also specify the absolute path of the files as below.

```json
{
  "markdown": {
    "path": "/Users/someone/Downloads/surveys/surveys.md",
    "type": "local"
  },
  "media": {
    "path": "/Users/someone/Downloads/surveys/media",
    "type": "local"
  }
}
```

If the specified file or folder does not exist, a dialogue box will prompt
the user, and the default files in the `assets/surveys` directory will be
loaded.

If the default markdown file is also missing, the app will display an error
message on the page.
