# CircleCI Flutter Client

<a href='https://play.google.com/store/apps/details?id=dev.gmem.cci.cci_app&ah=WZfJbfSMQvAo8DzlLMDwyk1qD-Q&pcampaignid=pcampaignidMKT-Other-global-all-co-prtnr-py-PartBadge-Mar2515-1'><img width=170 alt='Get it on Google Play' src='https://play.google.com/intl/en_gb/badges/static/images/badges/en_badge_web_generic.png'/></a>

View and run jobs from your mobile device!

## About

This is a Flutter app written as an experiment for interacting with the CircleCI API. Despite being an employee of 
CircleCI, this should not be considered an official app.

[Flutter](https://flutter.dev/docs/get-started/install) is required to build this project. 
[IntelliJ IDEA](https://www.jetbrains.com/idea/) is the easiest way to get up and running with the Fluter plugin, and
generally recommended as the editor for playing with this project.

Currently, only Android is officially supported, but theoretically it should be possible to build for iOS as well.

## Building

`flutter build apk --target-platform android-arm,android-arm64,android-x64 --split-per-abi` will generate APKs for each
platform that can be installed on the device. Otherwise, `flutter install` can be used to install the app on a device
connected with debugging enabled.