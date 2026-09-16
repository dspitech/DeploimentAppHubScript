#!/usr/bin/env bash
# ============================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# scripts/deploy.sh
# À copier dans le dépôt de l'application (azure-script-hub-fa365d79)
# Exécuté par le runner GitHub Actions auto-hébergé sur chaque VM.
#
# Sécurité du déploiement :
# - le build précédent est sauvegardé avant d'être remplacé
# - après redémarrage de pm2, on vérifie que l'appli répond vraiment
#   (plusieurs tentatives, avec délai)
# - si la vérification échoue, le build précédent est restauré et pm2
#   est rechargé dessus automatiquement -le site continue de servir
#   la dernière version qui fonctionnait, sans intervention manuelle.
# ============================================================
set -euo pipefail

REPO_NAME="$(basename "$(git rev-parse --show-toplevel)")"
APP_DIR="$HOME/projects/$REPO_NAME"
ENV_FILE="$HOME/projects/app.env"
HEALTH_URL="http://localhost:3000"
HEALTH_RETRIES=6
HEALTH_DELAY=5

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

# --- Sauvegarde du build actuellement servi, pour rollback si besoin ---
if [ -d "$APP_DIR/dist" ]; then
  rm -rf "$APP_DIR/dist_previous"
  mv "$APP_DIR/dist" "$APP_DIR/dist_previous"
  echo "==> Build précédent sauvegardé dans $APP_DIR/dist_previous"
fi

rsync -a --delete dist/ "$APP_DIR/dist/"

cd "$APP_DIR"

# Redémarrage sans coupure si le process existe déjà, sinon premier démarrage
if pm2 describe webapp > /dev/null 2>&1; then
  pm2 reload webapp
else
  pm2 start "$(which serve)" --name "webapp" -- -s dist -l 3000
fi

pm2 save

# --- Vérification que la nouvelle version répond réellement ---
echo "==> Vérification de la santé de l'application ($HEALTH_URL)..."
ok=false
for i in $(seq 1 "$HEALTH_RETRIES"); do
  if curl -fsS "$HEALTH_URL" -o /dev/null; then
    ok=true
    break
  fi
  echo "   Tentative $i/$HEALTH_RETRIES échouée, nouvel essai dans ${HEALTH_DELAY}s..."
  sleep "$HEALTH_DELAY"
done

if [ "$ok" = false ]; then
  echo "!! L'application ne répond pas après déploiement -ROLLBACK automatique."
  if [ -d "$APP_DIR/dist_previous" ]; then
    rm -rf "$APP_DIR/dist"
    mv "$APP_DIR/dist_previous" "$APP_DIR/dist"
    pm2 reload webapp || pm2 start "$(which serve)" --name "webapp" -- -s dist -l 3000
    pm2 save
    echo "==> Rollback effectué : le build précédent est de nouveau servi."
  else
    echo "!! Aucun build précédent disponible pour un rollback (premier déploiement)."
  fi
  exit 1
fi

echo "==> Déploiement terminé avec succès."
