# Media Playback Debugging Checklist

## 1. File Upload/Selection Pipeline
- [ ] **Verify File Picker Configuration**: Ensure `FilePicker` allows selection of both audio (MP3, WAV, AAC) and video (MP4, WebM, OGG) formats.
- [ ] **Check Permissions**: Verify `READ_EXTERNAL_STORAGE` (or `READ_MEDIA_AUDIO`/`READ_MEDIA_VIDEO` for Android 13+) permissions are requested and granted.
- [ ] **Validate File Existence**: Ensure the selected file path actually exists and is readable by the app.

## 2. Media Processing Logic
- [ ] **Metadata Extraction**: Verify that metadata (title, artist, duration) can be extracted from video files. Video files may not have ID3 tags like MP3s.
- [ ] **Waveform Extraction**: Check if `audio_waveforms` supports video files. If not, implement a fallback or skip waveform generation for unsupported formats to prevent crashes.
- [ ] **Codec Support**: Ensure the device supports the codecs used in the media files (e.g., AAC, MP3, H.264).

## 3. Playback Configuration
- [ ] **Player Initialization**: Verify `just_audio` player initializes correctly with video file URIs.
- [ ] **Error Handling**: Catch and log specific errors from `just_audio` (e.g., `PlayerException`, `PlatformException`).
- [ ] **Resource Release**: Ensure resources are released properly when switching songs or closing the app.

## 4. Error Handling & Logging
- [ ] **Implement Logging**: Add detailed logging to `fetchSongs`, `_buildSongItem`, `playSong`, and playback event listeners.
- [ ] **User Feedback**: specific error messages to the user when playback fails (e.g., "File format not supported", "File not found").
