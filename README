P4 scenarios
------

#### Overview
Scenarios are intended to be run with P4 switch emulator. Each scenario consists
of P4 program `<scenario>.p4`, commands passed to switch during tests
`commands.txt`, script with tests `test.py`.

#### Dependencies

* [P4 switch emulator](https://github.com/p4lang/behavioral-model)
* [P4 compiler](https://github.com/p4lang/p4c)

Compiler is expected to be installed system-wide (`make install` allows that).

Switch emulator installation directory is expected to be exported to
`SWITCH_EMULATOR_PATH`.

#### Compilation

To compile P4 programs, just run `make`. After compilation, resulting files
`scenarios/<scenario>/build/<scenario>.json` are used by switch emulator.

All available tagets:
  * `scenario-<scenario>` - compile specific scenario;
  * `scenario-<scenario>-graphs`- create graphs for parser, ingress, egress and
    deparser (placed in `build/graphs` of the scenario);
  * `scenario-<scenario>-clean` - remove build files for scenario;
  * `make all` - compile all scenarios (without graphs);
  * `make graphs` - compile graphs for all scenarios;
  * `make clean` - remove everything compiled;
  * `make test` - run tests for all scenarios (requires `all`).

#### Running tests
To run the tests, you need to specify switch emulator directory into required
environmental variable, then compile the sources and run `make test`
(super-user privilegies may be required and `-E` flag can be used to export
necessary variables: `sudo -E make test`).
