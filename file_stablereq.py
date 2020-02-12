#!/usr/bin/env python

# The script generates a simple stablereq template URL from pkgcheck output.
# It does a few things:
# 1. The "input" is provided into 'raw_pkgcheck_output' variable.
#    It's a raw output of:
#      $ portageq --no-regex --no-version --maintainer-email=slyfox@gentoo.org --repo=gentoo |
#        xargs --no-run-if-empty pkgcheck scan --keywords=StableRequest --repo=gentoo | ./file_stablereq.py
#    Usually raw output looks like:
#       app-misc/golly
#         StableRequest: version 3.3: slot(0) no change in 62 days for unstable keywords: [ ~amd64, ~x86 ]
# 2. Extract list of keywords for stabilization, get gentoo version of a package to stabilize
# 3. resolve package to maintainer list
# 4. Generate prefilled STABLEREQ URL

# I use it as:
#    ### TODO: try '-R FormatReporter --format=' here
#    $ PROJECTS=slyfox ./run_pkgcheck_for_maintained.sh --keywords=StableRequest | ./file_stablereq.py

from urllib.parse import urlencode
import re
import subprocess
import sys

class Package:
  def __init__(self, cpn, raw_pkgcheck_output):
    """Parse raw string into python object.

    Input is in form of:
    'StableRequest: version 3.3: slot(0) no change in 62 days for unstable keywords: [ ~amd64, ~x86 ]'
    """

    m = re.search(r'^StableRequest: version (.*): slot\((.*)\) no change in (.*) days for unstable keywords: \[ (.*) \]$', raw_pkgcheck_output)
    [pv, slot, days, raw_arches] = m.group(1,2,3,4)
    skip_chars = {
        '~': ' ',
        ',': ' ',
    }
    arches = raw_arches.translate(str.maketrans(skip_chars)).split()

    p = "%s-%s" % (cpn, pv)
    maintainers = subprocess.check_output("equery m -m =%s | tail -n +1" % p, shell=True).decode('utf-8').strip().split()

    self.P           = p
    self.DAYS        = days
    self.ARCHES      = arches
    self.MAINTAINERS = maintainers

def stablereq_url(package):
    # TODO: some arches like prefix map to different email aliases
    all_maintainers = package.MAINTAINERS + ["%s@gentoo.org" % a for a in package.ARCHES]

    summary = '=%s stabilization' % (package.P)
    comment = ("In tree for %s days. Let's stabilize =%s for:\n" % (package.DAYS, package.P) +
               "    " + ' '.join(package.ARCHES))

    stabilization_atoms = [package.P]

    form = {
        'form_name':    'enter_bug',
        'product':      'Gentoo Linux',
        'component':    'Stabilization',
        'bug_status':   'CONFIRMED',
        'bug_severity': 'normal',

        'short_desc':   summary,
        'comment':      comment,
        'keywords':     'STABLEREQ',

        'assigned_to':  all_maintainers[0],
        'cc':           ','.join(all_maintainers[1:]),
        'cf_stabilisation_atoms': '\n'.join(stabilization_atoms),

        'cf_runtime_testing_required': 'No',
    }

    return ('https://bugs.gentoo.org/enter_bug.cgi?%s' % urlencode(form))

def main():
    #    Raw input comes from 'pkgcheck scan --keywords=StableRequest' in for of:
    #
    #       app-misc/golly
    #         StableRequest: version 3.3: slot(0) no change in 62 days for unstable keywords: [ ~amd64, ~x86 ]
    #
    #       some-other/package
    #         StableRequest: ...
    #         StableRequest: ...

    for raw_per_package in sys.stdin.read().strip().split('\n\n'):
        [cpn, raw_stable_reqs] = raw_per_package.split('\n', 1)
        print(cpn)
        for raw_stable_req in raw_stable_reqs.split('\n'):
            p = Package(cpn, raw_stable_req.strip())

            print(raw_stable_req)
            print("Stablereq URL: %s" % stablereq_url(p))

main()
