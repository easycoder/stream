#!/usr/bin/env bash
# Deploy the filming.eclecity.net site to DreamHost.
#
# Remote layout:
#   /                 <- AllSpeak triples (HTML, .json layouts, -main.as scripts)
#   /*.php            <- backend endpoints (login, bookings list/save/delete)
#   /.htaccess        <- URL rewrites for /admin and /{slug}
#   /data/YYYY/MM/DD/ <- per-booking JSON files, written server-side. NEVER touched by deploy.
#
# Usage:  ./deploy.sh
#
# Local-only files that must NOT be uploaded:
#   .credentials              dev-only plaintext fallback for login (if present)
#   server.as                 AllSpeak dev server
#   edit.html, asedit.*       browser editor for local AllSpeak development
#   .code-version             tracks the dev server's self-update cycle
#   .allspeak-init            marker file for the AllSpeak project bootstrap
#   allspeak-en.zip           local AllSpeak distribution archive
#   AI.md, .gitignore, deploy.sh  repo metadata
#   conversation/             build transcripts
#   seed.as, sample.json      one-time helpers
#   build.as                  replaced by export.php
# These are excluded by listing only the production files explicitly below.

set -euo pipefail

REMOTE="eclecity@eclecity.net:/home/eclecity/filming.eclecity.net"
LOCAL="$(cd "$(dirname "$0")" && pwd)"

# Optional: uncomment to refuse deploy with dirty working tree.
# if [[ -n "$(git -C "$LOCAL" status --porcelain 2>/dev/null)" ]]; then
#     echo "Working tree has uncommitted changes (or not a git repo):"
#     git -C "$LOCAL" status --short 2>/dev/null || true
#     echo
#     echo "Commit or stash before deploying."
#     exit 1
# fi

echo "Deploying filming.eclecity.net from ${LOCAL}..."

tar czf /tmp/filming-deploy.tar.gz \
    -C "$LOCAL" \
    admin.html admin-main.as admin.json \
    index.html index-main.as index.json \
    stream.html stream-main.as stream.json \
    email1.json email2.json \
    login.php auth-check.php \
    bookings.php bookings-save.php bookings-delete.php \
    export.php background.jpg .htaccess

ssh -o StrictHostKeyChecking=accept-new eclecity@eclecity.net \
    "cd ~/filming.eclecity.net && tar xzf -" < /tmp/filming-deploy.tar.gz

rm -f /tmp/filming-deploy.tar.gz

echo "Done."