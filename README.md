# Stock Wise

Inventory app for small businesses, built with Flutter and Firebase. Runs on Android and in the browser.

Live: https://stockwisemy.vercel.app

## Features

- Sign in with Google
- Items sorted into folders, with stock in and stock out records
- Barcode scanning with the camera, and barcode images for items
- Low-stock and out-of-stock counts on the home screen
- Prices shown in a chosen currency

## Run locally

```
flutter pub get
flutter run -d chrome
```

The exchange-rate API key is not in this repo. The app gets rates from the site's `/api/rates` function (`api/rates.js`), which reads the key from the `EXCHANGE_RATE_API_KEY` environment variable on Vercel.
