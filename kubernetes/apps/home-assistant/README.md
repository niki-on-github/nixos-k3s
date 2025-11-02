# [Home Assistant](https://github.com/home-assistant/core)

Open source home automation that puts local control and privacy first. Powered by a worldwide community of tinkerers and DIY enthusiasts. Perfect to run on a Raspberry Pi or a local server.


## Workarounds

Homne Assistant does not provide a proper mechanism to handle custom integration well. To fix this we git clone custom integrations inot `/config/addons` and generate the required symlinks to be able to easy update these integrations via git pull. Files inside `/config/www` do not support this, hear we need to copy the files.
