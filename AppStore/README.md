# App Store screenshots

All 1320 × 2868 — the 6.9" iPhone size App Store Connect requires. Captured on
a simulator created for the purpose, so the home screen holds nothing but the
stock apps and this one.

| File | Shows |
|---|---|
| `01-main-reading.png` | The reading. Denver, AQI 83, Moderate, live from AirNow |
| `02-settings.png` | Key field and update schedule |
| `03-widget-step1-touch-and-hold.png` | Touch and hold the home screen |
| `04-widget-step2-add-widget.png` | Edit → Add Widget |
| `05-widget-step3-choose-app.png` | Search for USAirQMinder |
| `06-widget-step4-add.png` | The widget preview, then Add Widget |
| `07-widget-on-home.png` | The widget on the home screen, live |

`02` is captured with the API key field **empty** on purpose. A real key in a
public screenshot would be handing out someone's rate limit.

## Reproducing them

```bash
xcrun simctl create "USAirQMinder Shots" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max \
  com.apple.CoreSimulator.SimRuntime.iOS-26-5
xcrun simctl boot <udid>
xcrun simctl install <udid> /path/to/USAirQMinder.app
xcrun simctl location <udid> set 39.7392,-104.9903      # Denver
xcrun simctl status_bar <udid> override --time "9:41" \
  --cellularBars 4 --wifiBars 3 --batteryState charged --batteryLevel 100
xcrun simctl io <udid> screenshot AppStore/01-main-reading.png
```

The status bar override is what gives every shot 9:41 and full bars instead of
whatever the machine's clock and simulated signal happen to be.

Denver is chosen because it usually reads Moderate — a yellow dial shows the
colour coding doing something, where a Good/green reading looks like the app
might have no states at all.

## Still to do before submitting

- Nothing here is an iPad size. App Store Connect wants 13" iPad shots too if
  the app is listed as iPad-compatible, and this builds for both.
- The in-app clock in `01` reads the machine's real time, not 9:41, since the
  status bar override doesn't reach inside the app. Only noticeable if you look
  for it.
