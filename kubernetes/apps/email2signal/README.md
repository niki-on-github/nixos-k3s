# email2signal

Forward received emails to dockerized [signal-cli-rest-api](https://github.com/bbernhard/signal-cli-rest-api).

## Testing

Open shell in mailpit container and run:

```sh
echo -e "Subject: Test\n\nTest\n" | sendmail -S localhost:1025 self@signal.localdomain
```
