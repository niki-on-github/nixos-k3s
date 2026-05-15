# [Piped](https://github.com/TeamPiped/Piped)

An open-source alternative frontend for YouTube which is efficient by design.

## Config

To configure you can use the [URL Parameters](https://docs.piped.video/docs/parameters/). Passing them via urlParam Middleware does not work. I assume the config is parsed in java scipt frontend from url parameter. Therefore to change the default config we need to edit the source code of piped.

My prefered settings would be: `?hl=de&region=de&quality=720&minimizeComments=true&rate=2&autoplay=false`

## Features

- Built in SponsorBlock
- Built in Adblock
- Requires less resurecs than Invidious

## Issues

Due to the following Issues i can not use piped yet:

- Audio language can not be changed and often used automatically translated auto [#4090](https://github.com/TeamPiped/Piped/issues/4090)
