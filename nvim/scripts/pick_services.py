"""Read picker candidates using existing credentials; never print credentials.

Python 3.11+ standard library only. Editing remains in the existing URI handlers.
"""

import argparse
import base64
import json
import os
from pathlib import Path
import re
import sys
import tomllib
import urllib.error
import urllib.parse
import urllib.request


def request(base, resource, headers, params):
    url = base.rstrip("/") + "/" + resource + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=30) as response:
        return json.load(response)


def candidates(service, resource, domain):
    state = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
    if service == "docbase":
        if not re.fullmatch(r"[a-zA-Z0-9-]+", domain):
            raise ValueError("Invalid DocBase domain")
        with (state / "denops-docbase/teams" / f"{domain}.toml").open("rb") as stream:
            credentials = tomllib.load(stream)
        headers = {"X-DocBaseToken": credentials["token"], "Accept": "application/json"}
        posts = []
        page = 1
        while True:
            result = request(
                f"https://api.docbase.io/teams/{domain}", "posts", headers,
                {"q": "tag:template" if resource == "templates" else "desc:changed_at",
                 "page": page, "per_page": 100},
            )
            batch = result["posts"]
            posts.extend(batch)
            if not batch or not result.get("meta", {}).get("next_page"):
                break
            page += 1
        return posts

    with (state / "denops-inkdrop/credentials.toml").open("rb") as stream:
        credentials = tomllib.load(stream)
    base = credentials["baseUrl"]
    parsed = urllib.parse.urlsplit(base)
    if parsed.scheme not in ("http", "https") or not parsed.hostname:
        raise ValueError("Invalid Inkdrop base URL")
    auth = base64.b64encode(
        (credentials["username"] + ":" + credentials["password"]).encode()
    ).decode()
    headers = {"Authorization": "Basic " + auth, "Accept": "application/json"}
    if resource != "notes":
        return request(base, resource, headers, {})
    notes, skip = [], 0
    while True:
        batch = request(base, "notes", headers,
                        {"limit": 100, "skip": skip, "sort": "updatedAt", "descending": "true"})
        notes.extend(batch)
        if len(batch) < 100:
            return notes
        skip += len(batch)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("service", choices=("docbase", "inkdrop"))
    parser.add_argument("resource", choices=("posts", "templates", "notes", "books", "tags"))
    parser.add_argument("--domain", default="wacul")
    args = parser.parse_args()
    try:
        print(json.dumps(candidates(args.service, args.resource, args.domain), ensure_ascii=False))
    except FileNotFoundError:
        print(f"No {args.service} credentials. Run :DocbaseLogin or :InkdropLogin first.", file=sys.stderr)
        return 1
    except urllib.error.HTTPError as error:
        print(f"{args.service}: HTTP {error.code}", file=sys.stderr)
        return 1
    except (OSError, ValueError, KeyError, TypeError):
        print(f"Could not load {args.service} candidates. Check credentials and service availability.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
