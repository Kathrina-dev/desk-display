# desk_display

Ambient landscape desk stand display and daily desk-time tracker for Android.

## NFC testing

In NFC Tools, choose **Write**, add a custom MIME record with MIME type
`application/vnd.deskstand` and any small payload such as `desk-display`, then
write it to an NFC tag. With the app installed, tapping the tag launches the
app through the Android NDEF intent filter without creating a duplicate task.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
