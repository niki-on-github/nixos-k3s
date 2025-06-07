# Multus Networks

## Wake On Lan

To use the multus interface to send the wol package we need to add the interface for the dst `255.255.255.255/32`:

```
"routes": [{"dst": "255.255.255.255/32"}],
```
