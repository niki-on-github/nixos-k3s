# [Miniflux](https://miniflux.app/)

Miniflux is a minimalist and opinionated feed reader.

## Newsboat

add the following to `~/config/newsboat/config`:

```
urls-source "miniflux"
miniflux-url "https://rss.${domain}/"
miniflux-login "admin"
miniflux-password "mypassword"
```
