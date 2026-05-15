# [Miniflux](https://miniflux.app/)

Miniflux is a minimalist and opinionated feed reader.

## Config

### Rewrite

You can specify URL rewrite rule per feed. Example `rewrite("^.*youtube\.com/(.+)$"|"https://invidious.k8s.lan/$1")`.

## RSS URLS

- Read https://joeyehand.com/blog/2025/01/15/i-ditched-the-algorithm-for-rssand-you-should-too

## RSS Reader

### Newsboat (Linux)

add the following to `~/config/newsboat/config`:

```
urls-source "miniflux"
miniflux-url "https://rss.${domain}/"
miniflux-login "admin"
miniflux-password "mypassword"
```

### NetNewsWire (iOS)

1. Enable the Google Reader Integration in `Settings > Integrations > Google Reader`.
2. Select `FreshRSS` endpoint in NetNewsWire and add URL with tailing slash e.g. `https://miniflux.k8s.lan/` in NetNewsWire.

### Capy Reader (Android)

Us the Google Reader of miniflux to conenct.

