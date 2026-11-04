#!/usr/bin/env python3
"""Return a small, bounded set of results from the local SearXNG instance."""

import json
import sys
import urllib.parse
import urllib.request


def main():
    query = sys.argv[1].strip()[:500] if len(sys.argv) > 1 else ""
    if not query:
        print(json.dumps({"error": "empty query"}))
        return

    url = "http://127.0.0.1:8888/search?" + urllib.parse.urlencode(
        {"q": query, "format": "json"}
    )
    try:
        request = urllib.request.Request(url, headers={"User-Agent": "Quickshell-AI/1.0"})
        with urllib.request.urlopen(request, timeout=12) as response:
            data = json.load(response)
        results = [
            {
                "title": str(item.get("title", ""))[:180],
                "url": str(item.get("url", ""))[:500],
                "snippet": str(item.get("content", ""))[:550],
            }
            for item in data.get("results", [])[:6]
            if item.get("url")
        ]
        print(json.dumps({"query": query, "results": results}, ensure_ascii=False))
    except Exception as error:
        print(json.dumps({"error": str(error)[:200]}))


if __name__ == "__main__":
    main()
