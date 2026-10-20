# PushUpTracker

[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![CI](https://github.com/lucas-goldner/Pushup-Bro/actions/workflows/build_flutter_ios.yml/badge.svg?branch=main&event=pull_request)](https://github.com/lucas-goldner/Pushup-Bro/actions/workflows/build_flutter_ios.yml)

Track your pushups with ease using the sensors in your AirPods!

## Introduction

PushUpTracker is a cutting-edge iOS app developed with Flutter that leverages the advanced sensors in your AirPods to accurately track your pushups. Say goodbye to manual counting and hello to a seamless workout experience.
The best thing is the app uses the package I have made: https://pub.dev/packages/flutter_airpods

## Key Features

- Effortless tracking using the sensors in your AirPods
- Real-time pushup count displayed on your phone
- Set custom goals and track progress over time
- Store past workout sessions for easy reference
- Beautiful, intuitive user interface

## How it Works

Simply start a workout session and place your AirPods in your ears. The app will automatically detect and track each pushup you perform, providing an accurate count in real-time. No manual counting or awkward sensors required!

## Get Started

Download PushUpTracker from the App Store today and start tracking your pushups with ease. Whether you're a seasoned athlete or just starting your fitness journey, PushUpTracker is the perfect companion to help you reach your goals.

**Before running**, create a /config folder at the root of the /ios folder and
add a /dev and a /prod folder inside of it, inside of each of those add your GoogleServiceInfo.plist.
The paths should look like this at the end:
/ios/config/prod/GoogleService-Info.plist
/ios/config/dev/GoogleService-Info.plist

To run the project use:

```
$ flutter pub get

# If fluttergen is not installed go here: https://pub.dev/packages/flutter_gen
$ fluttergen

# If language files were not generated
$ dart pub global run intl_utils:generate

# For dev run
$ flutter run --flavor dev -t lib/main_dev.dart

# For prod run
$ flutter run --flavor prod -t lib/main_prod.dart
```
