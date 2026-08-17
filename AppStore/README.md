# App Store screenshots

Recaptured 2026-08-17 against the Open-Meteo build. Every shot shows the
"Modelled for" label, the CAMS/Open-Meteo attribution the licence requires, and
a settings screen with no API key field.

iPhone shots are 1320 × 2868 (6.9"), iPad shots 2064 × 2752 (13") — the two
sizes App Store Connect requires, the iPad set because the app builds for both
device families. Captured on simulators created for the purpose, so the home
screen holds nothing but the stock apps and this one.

| File | Shows |
|---|---|
| `01-main-reading.png` | The reading. Denver, AQI 51, Moderate |
| `01-main-reading-losangeles.png` | Central LA, AQI 53, Moderate |
| `01-main-reading-portland.png` | Portland OR, AQI 51, Moderate |
| `01-main-reading-nashville.png` | Nashville, AQI 55, Moderate |
| `02-settings.png` | Update schedule and the data source note |
| `03-widget-step1-touch-and-hold.png` | Touch and hold the home screen |
| `04-widget-step2-add-widget.png` | Edit → Add Widget |
| `05-widget-step3-choose-app.png` | Search for USAirQMinder |
| `06-widget-step4-add.png` | The medium widget preview, then Add Widget |
| `07-widget-on-home.png` | Both widget sizes on the home screen, live |

### iPad (2064 × 2752)

| File | Shows |
|---|---|
| `iPad-01-main-reading.png` | Denver, AQI 51, Moderate |
| `iPad-01-main-reading-losangeles.png` | Central LA, AQI 53, Moderate |
| `iPad-01-main-reading-portland.png` | Portland OR, AQI 51, Moderate |
| `iPad-01-main-reading-nashville.png` | Nashville, AQI 55, Moderate |
| `iPad-02-settings.png` | Settings, as a sheet |
| `iPad-03-add-widget.png` | The widget picker, USAirQMinder selected in the sidebar |
| `iPad-04-widget-on-home.png` | Both widget sizes on the home screen, live |

There is no longer an API key field to keep out of frame. The old note about
capturing `02` with the field empty, so a public screenshot couldn't hand out
someone's rate limit, no longer applies.

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

The four city variants of `01` (and their `iPad-01` counterparts) are
alternatives for the same store slot, not a sequence. Pick per storefront, or run them as a set to show the app works
anywhere in the country. Coordinates used:

| City | Latitude, longitude |
|---|---|
| Denver | `39.7392,-104.9903` |
| Los Angeles | `34.0522,-118.2437` |
| Portland | `45.5152,-122.6784` |
| Nashville | `36.1627,-86.7816` |

**All four now read Moderate, and that is a problem.** On the AirNow build,
Portland came in at 170 and rendered the red Unhealthy band — the case the app
exists for, and the obvious shot to lead with. On 2026-08-17 the whole country
was clean: a sweep of 22 US cities found nothing above 74 (Spokane), so no
location could produce anything but a yellow dial. The four shots are therefore
near-interchangeable and the set demonstrates exactly one of the six bands.

This is a scheduling problem, not a code one. Recapture `01` on a day with real
smoke somewhere and the red shot comes back. To find one, sweep candidate cities
for the current maximum before capturing rather than trusting a city that was
bad last time — Portland is not reliably bad, it just happened to be.

## Still to do before submitting

- **Recapture `01` on a bad-air day** so the set shows more than the Moderate
  band. See above — this is the one real gap.
- The in-app "Last checked" line in `01` reads the machine's real time, not
  9:41, since the status bar override doesn't reach inside the app. Only
  noticeable if you look for it.
