#!/usr/bin/env python

# http://archives.gentoo.org/gentoo-dev/msg_75881dcc749478a4fe7659d9b3594c75.xml

import operator
import os
import sys
import portage

def grab_profiles_desc(repo_path):

	lines = portage.util.grablines(
		os.path.join(repo_path, "profiles", "profiles.desc"))

	profiles = []

	for line in lines:

		if line.startswith("#"):
			continue

		line_split = line.split()
		if line_split:
			profiles.append(line_split)

	return profiles

def check_double_inclusion(repo_path, profile, out):

	profiles_dir = os.path.join(repo_path, "profiles")
	profile_path = os.path.join(profiles_dir, profile[1])
	c = portage.config(config_profile_path=profile_path)

	if len(c.profiles) != len(set(c.profiles)):

		previous = set()
		duplicates = set()

		for x in c.profiles:
			if x in previous:
				duplicates.add(x)
			previous.add(x)

		out.write("%s\t%s\n" % (profile[1],
			"\t".join((x[len(profiles_dir)+1:] for x in sorted(duplicates)))))

def main():

	portdir = os.path.realpath(portage.settings["PORTDIR"])
	profiles_desc = grab_profiles_desc(portdir)
	profiles_desc.sort(key=operator.itemgetter(1))

	for profile in profiles_desc:
		check_double_inclusion(portdir, profile, sys.stdout)

if __name__ == "__main__":
	main()
