# [FreshRSS](https://github.com/FreshRSS/FreshRSS)

FreshRSS is a self-hosted RSS feed aggregator.

## Backup / Restore

To backup your Abonnementverwaltung channels you can go to the Abonnementverwaltung Menu and use the `Importieren / Exportieren` Menu.

## Newsboat

add the following to `~/config/newsboat/config`:

```
urls-source "freshrss"
freshrss-url "https://rss.{{DOMAIN}}/api/greader.php"
freshrss-login "admin"
freshrss-password "mysupersecureexampleapipassword"
```
