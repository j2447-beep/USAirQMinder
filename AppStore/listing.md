# App Store Connect listing

Everything to paste into the app record. Character counts are checked against
Apple's limits and noted beside each field.

---

## ⚠️ Read this first: the app is untestable without a key

A reviewer who opens USAirQMinder with no AirNow key sees the **"AirNow key
needed"** screen and nothing else. It cannot fetch a reading, so from App
Review's side the app does nothing at all. That is a Guideline 2.1 rejection
(App Completeness) as reliably as anything gets.

**Put a working AirNow key in App Review Notes.** Wording below. Consider
requesting a second key for this purpose rather than handing over the one on
your own devices, so it can be revoked afterwards without breaking your app.

---

## Fields

**Name** (12/30)
```
USAirQMinder
```

**Subtitle** (29/30)
```
Live EPA air quality near you
```

**Promotional text** (160/170) — editable without a new build
```
Air quality where you are, straight from the EPA's AirNow network: one number, the colour that goes with it, and what it actually means for going outside today.
```

**Keywords** (88/100) — comma separated, no spaces
```
air quality,AQI,AirNow,EPA,pollution,smoke,wildfire,PM2.5,ozone,asthma,smog,index,pollen
```

**Description**
```
USAirQMinder shows the current EPA Air Quality Index for wherever you happen to be in the United States.

One number, in the colour the EPA gives it, with the health guidance that goes with that band. No account, no sign-up, no feed to scroll.

WHAT YOU SEE

• The current AQI for the reporting area nearest you, and how far away that is
• The EPA's category — Good, Moderate, Unhealthy for Sensitive Groups, Unhealthy, Very Unhealthy, Hazardous — with its official health message
• Which pollutant is driving the number, and the readings for the others
• When the observation was actually taken, so you know how fresh it is

A HOME SCREEN WIDGET

Small and medium sizes, updating on their own so you can see the air without opening anything.

WHERE THE DATA COMES FROM

Readings come from AirNow, the EPA's air quality service, which gathers measurements from state, local and tribal monitoring agencies across the country. AirNow issues each person a free API key; you enter yours once in Settings. That is why there is no subscription — you are querying the EPA directly, not going through us.

PRIVACY

There is no account and no server of ours. Your approximate location goes to AirNow so it can tell the app which reporting area you are near, and nowhere else. No analytics, no advertising, no tracking of any kind.

NOT A MEDICAL DEVICE

Readings describe a monitoring area that may be some distance away and are published hourly. Air quality varies over short distances. Use the app for general awareness, and follow your doctor and official public health guidance for decisions about your health.

USAirQMinder is not affiliated with or endorsed by the U.S. Environmental Protection Agency.
```

**Support URL**
```
https://elderminder.com/usairqminder/support.html
```

**Privacy Policy URL**
```
https://elderminder.com/usairqminder/privacypolicy.html
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
| Availability | United States (the data only covers the US) |

Restricting availability to the US is worth doing. The app is honest about
finding no reporting area elsewhere, but a listing that cannot work in a
storefront invites one-star reviews from people who didn't read why.

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

Nothing else is collected. The AirNow API key is the user's own credential
stored on their device, not data collected about them — it is not declared
here. No contact info, no identifiers, no usage data, no diagnostics.

---

## Export compliance

`ITSAppUsesNonExemptEncryption` is already `false` in Info.plist, so the
question should not be asked at upload. If it is: the app uses only HTTPS,
which is exempt. Answer **No**.

---

## App Review Notes

```
USAirQMinder reads live data from the EPA's AirNow service (airnowapi.org), which issues a free API key per user. The app cannot show a reading until a key is entered, so please use this one to test:

    API key: <PASTE THE REVIEW KEY HERE — DO NOT COMMIT IT>

To enter it: open the app, tap the gear icon in the top right, paste the key into "AirNow API key", and tap Done. A reading appears immediately.

The app needs location access to find the nearest EPA reporting area. If you are testing outside the United States, AirNow has no coverage and the app will say so; simulating a US location (for example Denver, 39.7392, -104.9903) will show a live reading.

The home screen widget uses the same key via an App Group, and asks for its own location permission when added.

There is no account, no sign-in, and no server operated by us.
```

Paste the key straight into App Store Connect. **Do not commit it here** —
this repo is public at github.com/j2447-beep/USAirQMinder, and anything
committed stays in the history even after it's deleted. The review key is a
borrowed one; revoke it once the app is approved.
