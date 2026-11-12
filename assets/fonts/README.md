# Inter Font Assets for Shree Shakti Electric

To enable the bundled offline Inter font across all platforms:

1. Download the following TTF font files from [rsms/inter releases](https://github.com/rsms/inter/releases):
   - `Inter-Regular.ttf` (Weight: 400)
   - `Inter-Medium.ttf` (Weight: 500)
   - `Inter-SemiBold.ttf` (Weight: 600)
   - `Inter-Bold.ttf` (Weight: 700)

2. Place them directly in this directory (`assets/fonts/`).

3. In `pubspec.yaml`, under `flutter:`, uncomment or add:
```yaml
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

*Note: The application's `AppTheme` is already pre-configured to use `fontFamily: 'Inter'` with seamless fallback to native platform fonts (Roboto on Android, Segoe UI on Windows).*
