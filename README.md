# Sõnamobi

Mobile user interface for accessing [Sõnaveeb](https://sonaveeb.ee/) dictionary.
Online only. It fetches raw html pages and preprocesses them for displaying.

Why is it better:

* Less requests and caching, hence faster answers.
* Easy to operate with one hand.
* Words forms are easier accessible.
* Translate definitions and examples with a tap.
* History and bookmarks.
* Dark mode.
* No tracking.

The app is not authorized by EKI, it's an independent work.

## Building instructions

It's a regular Flutter application, so the instructions are as usual. Although
first you need to open your [Google Cloud Console](https://console.cloud.google.com/apis/dashboard),
add a Cloud Translation API, and generate an API key. Then copy
`lib/keys.dart.example` to `lib/keys.dart` and put the key in there.
Finally,

    flutter pub get
    flutter run

Or whatever you need.

## Author and License

Written by Ilja Zverev, published under the ISC license.
