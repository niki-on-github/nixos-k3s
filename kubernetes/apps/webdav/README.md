# WebDAV

WebDAV stands for "Web-based Distributed Authoring and Versioning". It is a set of extensions to the HTTP protocol.

## Floccus Endpoint

For now we use this WebDAV Endpoint for Floccus Firefox Plugin to store and sync our browser bookmarks across devices.

To use Floccus Directories for each profile you have to crete the directory manualy with `uid = 82` and `gid = 82` e.g. via ssh.

### Example

- Webdav URL: `https://webdav.{{ domain }}`
- username: `webdav`
- password: `{{ webservice_password }}` new
- passphrase: `{{ webservice_password }}` old
- file path profile 1: `vpn/bookmarks.xbel`
- file path profile 2: `private/bookmarks.xbel`
- file path profile 3: `banking/bookmarks.xble`
