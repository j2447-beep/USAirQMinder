# App Store Connect listing

Everything to paste into the app record. Character counts are checked against
Apple's limits and noted beside each field.

---

## The key problem is gone

Earlier drafts of this file opened with a warning: a reviewer opening
USAirQMinder with no AirNow key saw a "key needed" screen and nothing else,
which is a Guideline 2.1 rejection waiting to happen.

That no longer applies. The app now reads from Open-Meteo, which needs no key
of any kind. A reviewer allows location and sees a reading. **Nothing needs to
be pasted into App Review Notes for the app to work.**

The trade is in what the data *is* — see "Saying it accurately" below, which
matters for keeping this listing truthful.

---

## Saying it accurately

The figures are **modelled, not measured**. They come from the Copernicus
Atmosphere Monitoring Service (CAMS) global forecast via Open-Meteo — a model
evaluated at the user's coordinates, not a reading from an EPA monitor.

What is genuinely the EPA's is the **scale**: `us_aqi` applies the EPA's
published AQI breakpoints, so 51 means Moderate exactly as it does on
airnow.gov.

So the listing may say "US Air Quality Index" and may explain that the index
follows the EPA's scale. It must **not** say the data comes from the EPA,
AirNow, or a monitoring network, and must not use "observed" or "measured".
The old copy did all of those; every field below has been corrected.

`AirNow` and `EPA` are also gone from the keyword list. The app no longer
touches AirNow at all, and leaning on "EPA" for discovery while serving
third-party model output is the kind of metadata claim worth not making.

---

## Fields

**Name** (12/30)
```
USAirQMinder
```

**Subtitle** (25/30)
```
Air quality where you are
```

**Promotional text** (164/170) — editable without a new build
```
Air quality where you are: one number, the colour that goes with it, and what it actually means for going outside today. No account, no key, nothing to sign up for.
```

**Keywords** (91/100) — comma separated, no spaces
```
air quality,AQI,pollution,smoke,wildfire,PM2.5,ozone,asthma,smog,index,forecast,particulate
```

**Description**
```
USAirQMinder shows the current US Air Quality Index for wherever you happen to be.

One number, in the colour that goes with it, and the health guidance for that band. No account, no sign-up, no API key, no feed to scroll.

WHAT YOU SEE

• The current AQI for your location
• The category — Good, Moderate, Unhealthy for Sensitive Groups, Unhealthy, Very Unhealthy, Hazardous — with the health message that goes with it
• Which pollutant is driving the number, and the figures for the others
• Which hour the figure applies to

A HOME SCREEN WIDGET

Small and medium sizes, updating on their own so you can see the air without opening anything.

WHERE THE NUMBERS COME FROM

Figures come from the Copernicus Atmosphere Monitoring Service (CAMS), the European Union's atmospheric monitoring programme, served by Open-Meteo. This is a forecast model: it estimates pollutant levels for your coordinates rather than reading them from an instrument nearby. That is why there is nothing to sign up for.

The index itself is the US EPA's. Its six categories and their thresholds are the ones published by the EPA, so a number here means what it means anywhere else you see a US AQI.

PRIVACY

There is no account and no server of ours. Your approximate location goes to Open-Meteo to fetch the figures, and to Apple's built-in geocoder to turn your coordinates into a place name. Nowhere else. No analytics, no advertising, no tracking of any kind.

NOT A MEDICAL DEVICE

These are modelled figures, not measurements, and a model can differ from what a monitor nearby would record — particularly during fast-moving events such as wildfire smoke. Use the app for general awareness. For actual EPA monitor readings, and for anything bearing on your health, see airnow.gov and follow your doctor and official public health guidance.

USAirQMinder is not affiliated with or endorsed by the U.S. Environmental Protection Agency, Open-Meteo, or the Copernicus Atmosphere Monitoring Service.
```

**Support URL**
```
https://elderminder.com/usairqminder/support.html
```

**Privacy Policy URL**
```
https://elderminder.com/usairqminder/privacypolicy.html
```

**Copyright**
```
2026 Dunville & Co.
```

**Marketing URL** — leave blank; there isn't one.

---

## Settings

| Field | Value |
|---|---|
| Primary category | Weather |
| Secondary category | Health & Fitness |
| Age rating | 4+ |
| Price | Free |
| Availability | United States |

Note that the *reason* for US-only availability has changed. It used to be a
hard data limit — AirNow covers the US and nothing else. CAMS is global, so the
app would now function anywhere. Keeping it US-only is a product decision: the
app is built around the US AQI scale and named accordingly. Worth revisiting as
a deliberate choice rather than carrying it forward as a constraint.

---

## App Privacy questionnaire

This must agree with the privacy policy or it is a rejection on its own.

| Question | Answer |
|---|---|
| Do you collect data from this app? | **Yes** — location leaves the device |
| Data type | **Location → Coarse Location** |
| Purpose | **App Functionality** |
| Linked to the user's identity? | **No** |
| Used for tracking? | **No** |

Nothing else is collected. There is no longer an API key to consider. No contact
info, no identifiers, no usage data, no diagnostics.

Location goes to two places — Open-Meteo and, via `CLGeocoder`, Apple. Both are
App Functionality and neither is linked or used for tracking, so the answers
above cover both; the privacy policy names them individually.

---

## Export compliance

`ITSAppUsesNonExemptEncryption` is already `false` in Info.plist, so the
question should not be asked at upload. If it is: the app uses only HTTPS,
which is exempt. Answer **No**.

---

## App Review Notes

```
USAirQMinder shows the US Air Quality Index for the user's current location.

No account, no sign-in, and no API key — the app works immediately on launch. Please allow location access when prompted; that is the only thing it needs.

Air quality figures come from Open-Meteo (open-meteo.com), a free public API serving Copernicus Atmosphere Monitoring Service (CAMS) forecast data. These are modelled figures for the user's coordinates rather than measurements from a monitoring station, which the app states in Settings, in its support page, and in its privacy policy. The index scale and its six categories are the US EPA's published AQI breakpoints; the app is not affiliated with the EPA and does not present its figures as EPA measurements.

The app also uses iOS's built-in CLGeocoder to turn coordinates into a place name for display.

If you are testing outside the United States you will still get a reading — CAMS is global — though the app is scoped to the US storefront.

The home screen widget fetches its own reading and asks for its own location permission when added.

There is no server operated by us.
```

No key to paste, and nothing to revoke afterwards.
