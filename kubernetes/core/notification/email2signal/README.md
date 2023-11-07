# email2signal

Forward received emails to signal-cli-rest-api.

## Testing

```bash
curl --url 'smtp://server02.lan:8025' --mail-from 'developer@local.domain' --mail-rcpt '+491XXXXXX@signal.localdomain' --upload-file mail.txt
```
