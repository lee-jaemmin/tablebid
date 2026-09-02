#!/bin/bash

git clone https://github.com/flutter/flutter.git --depth 1 -b 3.41.3 flutter
export PATH="$PATH:$(pwd)/flutter/bin"

flutter pub get
flutter build web --dart-define=API_BASE_URL="API_BASE_URL" --dart-define=JUSO_CONFM_KEY="JUSO_CONFM_KEY"