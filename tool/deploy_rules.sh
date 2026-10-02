#!/usr/bin/env bash
# Deploys firestore.rules to project milk-tracker-hd using gcloud credentials.
# (Equivalent to `firebase deploy --only firestore:rules` for whoever's gcloud
# account owns the project; avoids needing the Firebase CLI logged into it.)
set -euo pipefail
cd "$(dirname "$0")/.."

P=milk-tracker-hd
TOK=$(gcloud auth print-access-token)
API=https://firebaserules.googleapis.com/v1/projects/$P
H=(-sS -H "Authorization: Bearer $TOK" -H "x-goog-user-project: $P" -H "Content-Type: application/json")

BODY=$(python3 -c 'import json; print(json.dumps({"source": {"files": [{"name": "firestore.rules", "content": open("firestore.rules").read()}]}}))')
RULESET=$(curl "${H[@]}" -X POST "$API/rulesets" -d "$BODY" \
  | python3 -c 'import sys, json; d = json.load(sys.stdin); print(d["name"]) if "name" in d else sys.exit(json.dumps(d, indent=2))')
echo "Compiled: $RULESET"

RELEASE="{\"release\": {\"name\": \"projects/$P/releases/cloud.firestore\", \"rulesetName\": \"$RULESET\"}}"
curl "${H[@]}" -X PATCH "$API/releases/cloud.firestore" -d "$RELEASE" \
  | python3 -c 'import sys, json; d = json.load(sys.stdin); print("Released at", d["updateTime"]) if "updateTime" in d else sys.exit(json.dumps(d, indent=2))'
