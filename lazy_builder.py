#!/usr/bin/env python3

# Copy from "lazy_builder.sh" as is:
# This tool accepts '<todo_list>' file in 'getatoms.py' format
# and attempts to build each package with default emerge options.
#
# Build logs are piped into the '<logs_dir>' log dirs.
# Results are piped into '<output_file>' file and look like
# filtered input (to be used by 'stable-or-kw.bash' keyworder).
#
# The script attempts not to build the same atom twice to
# ease automatic incremental builds with many failures.

import argparse
import enum
import os
import re
import shlex

logs_dir    = 'logs'

class Spec:
    """Namespace to hold minimal parsing of atom specifications.

    getatoms.py output and package.accept_keywords define a spec.
    """

    def get_bug(bug_spec):
        """Parse bug number out of bug spec.

        Example:
         '# bug #123' -> 123
        """
        m = re.match('^# bug #(\d+)$', bug_spec.strip())
        return int(m.group(1))

    def get_atom(atom_spec):
        """Parse atom of atom spec.

        Examples:
           '=foo/bar-1.2.3 **' -> '=foo/bar-1.2.3'
           '=foo/bar-1.2.3'    -> '=foo/bar-1.2.3'
        """
        return atom_spec.split(' ')[0]

class Task:
    """Task is a single bug to work on. As returned by getatoms.py"""

    bug_number = None
    atoms      = None

    def __init__(self, task_spec):
        """Initialize keywording/stabilization task getatoms.py entry.

        Example entry to build a task from:
              # bug #123
              =foo **
              =bar
        """
        bug_string, *atoms = task_spec.split('\n')
        self.bug_number = Spec.get_bug(bug_string)
        self.atoms = [Spec.get_atom(atom_spec) for atom_spec in atoms]

    def __repr__(self):
        return "Task(bug=%r,atoms=%r)" % (self.bug_number, self.atoms)

    def __str__(self):
        return "# bug #%d\n%s" % (self.bug_number, '\n'.join(self.atoms))


class Executor:
    """Run a Task and see if it succeeds."""

    logs_dir = None

    class Result(enum.IntEnum):
        """Result of a single emerge run action."""

        # Order matters: from weakest to strongest
        NO_ATOMS = enum.auto()
        PASS     = enum.auto()
        FAIL     = enum.auto()

    def __init__(self, logs_dir):
        if not os.path.exists(logs_dir):
            os.mkdir(logs_dir)
        self.logs_dir = logs_dir

    def _update_result(status, new_atom_result):
        """Advance existing 'status' result result of a freshly built atom."""

        return max(status, new_atom_result)

    def run(self, task):
        """Attempt to emerge all atoms in task and persist the result on file system."""

        result = Executor.Result.NO_ATOMS
        for atom in task.atoms:
            v = self._emerge_cached(atom)
            result = Executor._update_result(result, v)
        return result

    def _emerge_cached(self, atom):
        """Run emerge on specified atom or reads cached status."""
        # mangle atom into path-friendlier form
        emerge_log  = os.path.join(self.logs_dir, atom.replace('/', ':'))
        pass_marker = emerge_log + '.PASS'
        fail_marker = emerge_log + '.FAIL'

        # There already was build attempt with status: PASS, FAIL or a machine crash (no marker)
        if os.path.exists(pass_marker):
            print(atom + ': PASS (cached)')
            return Executor.Result.PASS
        if os.path.exists(fail_marker):
            # build failed or machine crashed
            print(atom + ': FAIL (cached)')
            return Executor.Result.FAIL
        if os.path.exists(emerge_log):
            # build failed or machine crashed
            print(atom + ': UNKNOWN (cached)')
            return Executor.Result.FAIL

        return Executor._emerge_uncached(atom, emerge_log, pass_marker, fail_marker)

    def _emerge_uncached(atom, emerge_log, pass_marker, fail_marker):
        """Run emerge and store result into places."""

        print(atom + ': BUILDING')
        os.system('( emerge -v1 {atom} && touch {pass_marker}; ) 2>&1 | tee {emerge_log}'.format(
            atom        = shlex.quote(atom),
            pass_marker = shlex.quote(pass_marker),
            emerge_log  = shlex.quote(emerge_log),
        ))

        if os.path.exists(pass_marker):
            os.rename(emerge_log, pass_marker)
            print(atom + ': PASS')
            return Executor.Result.PASS

        os.rename(emerge_log, fail_marker)
        print(atom + ': FAIL')
        return Executor.Result.FAIL


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_atoms",  help="List of bugs to process in getatoms.py format.", type=str)
    parser.add_argument("output_atoms", help="List of bugs tested successfullyin getatoms.py format.", type=str)
    parser.add_argument("logs_dir",     help="Directory to store logs as a build cache.", type=str)
    args = parser.parse_args()

    executor = Executor(args.logs_dir)

    with open(args.input_atoms, 'r') as i:
        with open(args.output_atoms, 'w') as o:
            for task_spec in i.read().strip().split('\n\n'):
                # empty file or many newlines
                if len(task_spec) == 0:
                    continue
                task = Task(task_spec)
                result = executor.run(task)
                if result == Executor.Result.PASS:
                    print("%s\n" % task, file=o)
    print("Done!")

main()
