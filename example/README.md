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

In the example code of this package, users can customise the paths for
markdown files and media files by modifying the `config.json` file. The
`config.json` file is located in the `assets` folder. The location of the
`assets` folder may be different on different platform:

On macOS, it is at `riopod/build/macos/Build/Products/Debug/riopod.app/Contents/Frameworks/App.framework/Versions/A/Resources/flutter_assets/assets`.

On Windows, it is at `riopod\build\windows\x64\runner\Debug\data\flutter_assets\assets`.

On Linux, it is at `riopod/build/linux/x64/debug/bundle/data/flutter_assets/assets`.

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
