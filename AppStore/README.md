# App Store screenshots

iPhone shots are 1320 × 2868 (6.9"), iPad shots 2064 × 2752 (13") — the two
sizes App Store Connect requires, the iPad set because the app builds for both
device families. Captured on simulators created for the purpose, so the home
screen holds nothing but the stock apps and this one.

| File | Shows |
|---|---|
| `01-main-reading.png` | The reading. Denver, AQI 83, Moderate, live from AirNow |
| `01-main-reading-losangeles.png` | Central LA, AQI 62, Moderate |
| `01-main-reading-portland.png` | Portland OR, AQI 170, **Unhealthy** — the red band |
| `01-main-reading-nashville.png` | Nashville, AQI 53, Moderate |
| `02-settings.png` | Key field and update schedule |
| `03-widget-step1-touch-and-hold.png` | Touch and hold the home screen |
| `04-widget-step2-add-widget.png` | Edit → Add Widget |
| `05-widget-step3-choose-app.png` | Search for USAirQMinder |
| `06-widget-step4-add.png` | The widget preview, then Add Widget |
| `07-widget-on-home.png` | The widget on the home screen, live |

### iPad (2064 × 2752)

| File | Shows |
|---|---|
| `iPad-01-main-reading.png` | Portland, AQI 170, Unhealthy |
| `iPad-02-settings.png` | Settings, as a sheet |
| `iPad-03-add-widget.png` | The widget picker with its sidebar |
| `iPad-04-widget-on-home.png` | The widget on the home screen, live |

`02` and `iPad-02` are captured with the API key field **empty** on purpose. A
real key in a public screenshot would be handing out someone's rate limit.

On iPad the reading screen lays out in two columns — dial on the left, category
and detail beside it — and centres in the height. `iPad-01` shows that. The
iPhone layout is untouched.

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

The four city variants of `01` are alternatives for the same store slot, not a
sequence. Pick per storefront, or run them as a set to show the app works
anywhere in the country. Coordinates used:

| City | Latitude, longitude |
|---|---|
| Denver | `39.7392,-104.9903` |
| Los Angeles | `34.0522,-118.2437` |
| Portland | `45.5152,-122.6784` |
| Nashville | `36.1627,-86.7816` |

Portland is the one worth leading with. At 170 it renders the red Unhealthy
band, which is the case the app exists for — the three Moderate readings all
look alike, and none of them shows what a bad-air day looks like. Readings are
live, though, so a rerun will show whatever the air is doing that day.

## Still to do before submitting

- The in-app clock in `01` reads the machine's real time, not 9:41, since the
  status bar override doesn't reach inside the app. Only noticeable if you look
  for it.
