# [Signal REST API](https://github.com/bbernhard/signal-cli-rest-api)

Dockerized Signal Messenger REST API.

## Setup

1. Open register URL `https://signal-api.${domain}/v1/qrcodelink?device_name=signal-api` and scan the QR code with your signal app on
   your smartphone.
2. Test the registration with `curl --insecure -X POST -H "Content-Type: application/json" 'https://signal-api.${domain}/v2/send' -d '{"message": "Test via Signal API!", "number": "+491XXXXXX", "recipients": [ "+491XXXXXXX" ]}'`

## Testing

Using `wget`:

```bash
wget -O- --post-data='{"message": "test", "number": "+491XXXXXX", "recipients": [ "+491XXXX" ]}' --header='Content-Type:applicationgjson' 'http://signal-rest-api.notification.svc:8080/v2/send'
```
