#!/usr/bin/env bash
# Build da versão web na Netlify (configurado em netlify.toml, na raiz do repositório).
# Roda dentro de App_Pablife/.
set -euo pipefail

# Mesma versão do Flutter fixada em .tool-versions (ex.: "3.38.6-stable" -> "3.38.6").
FLUTTER_VERSION="$(awk '/^flutter /{print $2}' .tool-versions)"
FLUTTER_VERSION="${FLUTTER_VERSION%-stable}"
FLUTTER_DIR="$HOME/flutter-$FLUTTER_VERSION"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter config --no-analytics >/dev/null
flutter --version

# firebase_options.dart fica fora do repositório (.gitignore). Na web o Firebase
# não é iniciado (ver main.dart), então basta um arquivo que compile.
if [ ! -f lib/firebase_options.dart ]; then
  cat > lib/firebase_options.dart <<'EOF'
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform =>
      throw UnsupportedError('Firebase não é usado na versão web.');
}
EOF
fi

flutter pub get --enforce-lockfile
# Sem o service worker do Flutter: cada publicação vale já na próxima visita.
flutter build web --release --no-wasm-dry-run --pwa-strategy=none
# Para quem ainda tem o worker antigo instalado (ver o arquivo).
cp scripts/flutter_service_worker.js build/web/flutter_service_worker.js
