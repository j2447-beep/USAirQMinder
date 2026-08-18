# App Review Information — answers to Apple's Guideline 2.1 questions

Version 1.0 build 1 was rejected 2026-08-05 under **Guideline 2.1 — Information
Needed**. Apple asked seven numbered questions. Paste the answers below into the
**Notes** field of App Review Information before resubmitting.

Two items (1 and 2) cannot be answered from this repo — see the flags.

---

## ⚠️ Before pasting: three things to fix

1. **Revoke the AirNow API key** that is currently in the Notes field
   (`4E830C94-…`). The app no longer contacts AirNow, the key is described in
   `listing.md` as borrowed, and it is sitting in plain text in App Store
   Connect. Remove it from the Notes entirely.
2. **The existing Notes open with "SAirQMinder"** — missing the U. A reviewer
   read that.
3. **Replace the screenshots.** 9 iPhone + 6 iPad are attached but all are
   AirNow-era: they show a "· N km away" line and an API key field that no
   longer exist. The recaptured set is in `AppStore/`. The iPhone set also has
   `01-main-reading.png` twice, and the iPad set is missing the Denver primary.

---

## 1. Screen recording on a physical device

**❗ You must do this — it cannot be produced here.** Apple requires a physical
device running the latest OS; a simulator recording does not satisfy this, and
the tooling available in this project drives simulators only.

The recording must start with launching the app and show the typical flow.
Apple specifically asks that prompts requesting sensitive data are included, and
this app has one, so the order matters:

1. Launch from the home screen (start recording before the tap)
2. **The location permission prompt** — let it appear on camera, then Allow
3. The reading appearing: number, category, colour, pollutant breakdown
4. Pull to refresh, or the refresh button
5. The gear icon → Settings, showing the update schedule and data-source note
6. Optionally: long-press the home screen and add the widget, both sizes

There is no account, no purchase, no subscription and no user-generated content,
so the other bullets in Apple's item 1 do not apply.

## 2. Devices and operating systems tested

**❗ Needs your input** — this repo only records simulator testing, and Apple
asks what it was tested on *before submitting*, on physical devices.

Verified in the iOS 26.5 simulator: iPhone 17 Pro, iPhone 17 Pro Max, iPad Pro
13-inch (M4). Add the real devices you have tested on, with their iOS versions.
If it has not been run on a physical device yet, do that first — Apple reviews
on hardware and item 1 requires a device recording regardless.

## 3. Functions and target audience

```
USAirQMinder shows the current US Air Quality Index for the user's location.

WHAT IT DOES
The app requests the device's approximate location, fetches the air quality
figures modelled for that point, and displays the resulting US AQI as a single
number with its official category (Good, Moderate, Unhealthy for Sensitive
Groups, Unhealthy, Very Unhealthy, Hazardous), the colour associated with that
band, and the published health guidance for it. It also names which pollutant
is driving the index and lists the sub-index for each of the six pollutants
(PM2.5, PM10, ozone, NO2, SO2, CO). A home screen widget shows the same
headline figure in small and medium sizes.

TARGET AUDIENCE
General consumers who want a quick, unambiguous read on outdoor air quality:
people who exercise outdoors, people with asthma or other respiratory
sensitivity, parents deciding whether children should play outside, and anyone
in a region affected by wildfire smoke.

THE PROBLEM IT SOLVES
Air quality information is usually either buried inside a general weather app
or presented as raw pollutant concentrations that require interpretation. This
app answers one question — "is the air OK where I am right now?" — in a form
that needs no expertise to read.

THE VALUE IT PROVIDES
One glanceable number in a standard colour scheme, with plain-language health
guidance. No account, no sign-up, no subscription, no advertising, and no
configuration required before it works.
```

## 4. Setup and access instructions

```
No setup is required. There are no accounts, no login credentials, no demo
account, no in-app purchases, and no sample files.

TO USE THE APP
1. Launch the app.
2. Tap "Allow While Using App" when iOS asks for location access. This is the
   only permission requested and the app cannot show a reading without it.
3. The reading appears immediately.

The refresh button (arrows, top right) and pull-to-refresh both fetch again.
The gear icon opens Settings, which contains the update interval and a note
describing the data source. There is nothing to configure for the app to work.

TO TEST THE WIDGET
Touch and hold an empty area of the home screen, tap Edit then Add Widget,
search for USAirQMinder, and choose the small or medium size. The widget asks
for its own location permission, because iOS treats it as a separate process.

IF TESTING FROM A SIMULATOR OR OUTSIDE THE UNITED STATES
The app will still return a reading — the underlying model has global coverage.
To see a US reading, simulate a US location, for example Denver at
39.7392, -104.9903.
```

## 5. External services used

```
The app uses two external services and nothing else.

1. OPEN-METEO AIR QUALITY API  (air-quality-api.open-meteo.com)
   Supplies all air quality figures. Open-Meteo is a free public weather and
   air quality API that serves forecast data from the Copernicus Atmosphere
   Monitoring Service (CAMS), the European Union's atmospheric monitoring
   programme. The app sends only the device's approximate latitude and
   longitude; no key, account, identifier or personal data is attached to the
   request. No registration is required to use the API.

   Important clarification: these are MODELLED figures, not measurements from
   a monitoring station. What the app takes from the US Environmental
   Protection Agency is the index SCALE — the published AQI breakpoints and
   the six category names — not the data. The app states this in Settings, on
   its support page and in its privacy policy, and it explicitly disclaims any
   affiliation with the EPA.

2. APPLE CLGEOCODER  (iOS system framework)
   Converts the device's coordinates into a place name for display, for
   example "Denver, CO". This is the standard iOS reverse-geocoding API. It is
   best-effort only; if it fails the app displays "Your location" instead.

NOT USED: no authentication or identity provider, no payment processor, no
advertising network, no analytics or crash-reporting SDK, no AI or machine
learning service, no third-party SDKs of any kind, and no server operated by
the developer. The app has no backend.
```

## 6. Regional differences

```
There are no regional differences in features or content. The app behaves
identically everywhere: it requests location, fetches the figures modelled for
those coordinates, and displays the US AQI for them. No feature is gated,
altered or withheld by region, and there is no region-specific content.

The underlying data source has global coverage, so the app returns a reading
for any location worldwide rather than failing outside a particular country.

App Store availability is set to the United States because the app presents the
US Air Quality Index specifically, which is the scale meaningful to a US
audience — but that is a distribution choice, not a functional difference.
```

## 7. Regulated industry and third-party material

```
REGULATED INDUSTRY: no. USAirQMinder is a general-interest environmental
information app. It is not a medical device, provides no diagnosis, treatment
or medical advice, and involves no health records, financial services,
gambling, or any other regulated activity. It states plainly in the app, on its
support page and in its privacy policy that the figures are for general
awareness, that they are modelled rather than measured, and that users should
follow their doctor and official public health guidance for health decisions,
directing them to airnow.gov for actual EPA monitor readings.

THIRD-PARTY MATERIAL: the air quality data is obtained from the Open-Meteo
public API and is licensed under Creative Commons Attribution 4.0 (CC-BY 4.0).
Open-Meteo's free tier is provided for non-commercial use, and Open-Meteo's own
definition of non-commercial expressly includes "apps that do not have
subscriptions or advertising". USAirQMinder is free, contains no advertising,
no subscriptions and no in-app purchases, and therefore falls within that
permitted use. Its usage is far below the published free-tier limits of 10,000
requests per day.

The licence requires attribution to both the CAMS data provider and Open-Meteo.
The app displays "CAMS via Open-Meteo" beneath every reading and in the medium
widget, and names both in Settings and in the privacy policy.

No proprietary, licensed or otherwise protected third-party material is
included. The US EPA's Air Quality Index scale and its category thresholds are
a published public standard; the app applies that scale and does not reproduce
any EPA content, branding or data, and states that it is not affiliated with or
endorsed by the EPA.
```
