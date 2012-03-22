#!/usr/bin/env python

# http://archives.gentoo.org/gentoo-dev/msg_75881dcc749478a4fe7659d9b3594c75.xml

import sys
import portage

c = portage.config(config_profile_path=sys.argv[1])
for x in c.profiles:
	sys.stdout.write("%s\n" % (x,))
