"""Counts the app data in Firebase project milk-tracker-hd (documents by
kind, and sign-in accounts).

    python tool/wipe_data.py

DELETING IS PERMANENTLY DISABLED. Since 2026-10-03 this project holds the
family's real milk logs; the owner asked that it never be wiped again, even
on request. For testing, use a separate throwaway household or a separate
Firebase project instead.

Authenticates with your gcloud login (the project owner), so it bypasses
the security rules. Standard library only.
"""
import json
import subprocess
import sys
import urllib.request

PROJECT = "milk-tracker-hd"
DOCS = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"
AUTH = f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT}"
TOKEN = subprocess.check_output(["gcloud", "auth", "print-access-token"], text=True).strip()


def call(method, url, body=None):
    req = urllib.request.Request(
        url,
        method=method,
        data=None if body is None else json.dumps(body).encode(),
        headers={
            "Authorization": f"Bearer {TOKEN}",
            "x-goog-user-project": PROJECT,
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req) as res:
        raw = res.read()
        return json.loads(raw) if raw else {}


def collections(parent):
    url = f"{parent}:listCollectionIds" if parent != DOCS else f"{DOCS}:listCollectionIds"
    return call("POST", url, {"pageSize": 300}).get("collectionIds", [])


def documents(parent, collection):
    """Every document path under parent/collection, depth-first (children first)."""
    out, token = [], None
    while True:
        url = f"{parent}/{collection}?pageSize=300&showMissing=true"
        if token:
            url += f"&pageToken={token}"
        page = call("GET", url)
        for d in page.get("documents", []):
            path = d["name"].split("/documents/", 1)[1]
            for sub in collections(f"{DOCS}/{path}"):
                out += documents(f"{DOCS}/{path}", sub)
            out.append(path)
        token = page.get("nextPageToken")
        if not token:
            return out


def users():
    out, token = [], None
    while True:
        body = {"returnUserInfo": True, "limit": "500"}
        if token:
            body["offset"] = token
        page = call("POST", f"{AUTH}/accounts:query", body)
        out += [u["localId"] for u in page.get("userInfo", [])]
        if len(page.get("userInfo", [])) < 500:
            return out
        token = str(len(out))


def main():
    confirm = "--yes" in sys.argv
    paths = [p for c in collections(DOCS) for p in documents(DOCS, c)]
    uids = users()
    by_kind = {}
    for p in paths:
        parts = p.split("/")
        kind = parts[0] if len(parts) == 2 else f"{parts[0]}/…/{parts[-2]}"
        by_kind[kind] = by_kind.get(kind, 0) + 1
    print(f"Firestore documents: {len(paths)}")
    for k, v in sorted(by_kind.items()):
        print(f"  {k}: {v}")
    print(f"Sign-in accounts: {len(uids)}")
    if confirm:
        sys.exit("\nRefused: this project holds real family data. Deleting is "
                 "disabled permanently (see the note at the top of this file).")
    print("\nRead-only count. Nothing was deleted.")
    return
    for p in paths:
        call("DELETE", f"{DOCS}/{p}")
    for i in range(0, len(uids), 1000):
        call("POST", f"{AUTH}/accounts:batchDelete", {"localIds": uids[i:i + 1000], "force": True})
    left = [p for c in collections(DOCS) for p in documents(DOCS, c)]
    print(f"\nDeleted. Remaining documents: {len(left)}, accounts: {len(users())}")


if __name__ == "__main__":
    main()
