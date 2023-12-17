#!/usr/bin/python3
##############################################################################
### NZBGET SCAN SCRIPT                                     ###
#
# Scans filename of incoming NZBs for embedded passwords.
#
##############################################################################
### OPTIONS                                                                ###
# The RegEx to match the password in the filename.
#regex=(.*)\{\{(.*)\}\}.nzb

### NZBGET SCAN SCRIPT                                     ###
##############################################################################

import re
import getopt
import sys
import os

nzbfile = os.environ.get('NZBNP_NZBNAME')
regex = os.environ.get('NZBPO_REGEX')

if nzbfile:
  pattern = re.compile(regex)
  match = pattern.search(nzbfile)
  password = ""
  name = nzbfile
  if match:
    name = match.group(1)
    password = match.group(2)

  print("[NZB] NZBNAME=" + name)
  if password:
    print("[NZB] NZBPR_*Unpack:Password=" + password)
