#!/usr/bin/env bash
# ============================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# scripts/deploy.sh
# ============================================================
set -euo pipefail

REPO_NAME="$(basename "$(git rev-parse --show-toplevel)")"
APP_DIR="$HOME/projects/$REPO_NAME"
ENV_FILE="$HOME/projects/app.env"

echo "==> Déploiement de $REPO_NAME vers $APP_DIR"

# Le fichier d'environnement persistant (créé une fois par cloud-init, jamais
# committé dans Git) est copié dans le workspace AVANT le build, car les
# variables VITE_*/NEXT_PUBLIC_* sont injectées au moment du build, pas au runtime.
if [ -f "$ENV_FILE" ]; then
  cp -f "$ENV_FILE" .env
else
  echo "ATTENTION : $ENV_FILE introuvable, build sans variables d'environnement."
fi

npm ci --legacy-peer-deps
npm run build

mkdir -p "$APP_DIR"
rsync -a --delete dist/ "$APP_DIR/dist/"

cd "$APP_DIR"

# Redémarrage sans coupure si le process existe déjà, sinon premier démarrage
if pm2 describe webapp > /dev/null 2>&1; then
  pm2 reload webapp
else
  pm2 start "$(which serve)" --name "webapp" -- -s dist -l 3000
fi

pm2 save

echo "==> Déploiement terminé avec succès."