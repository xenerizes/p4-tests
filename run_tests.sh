#!/usr/bin/env bash

export PYTHONPATH=$(pwd)

if [ -z "$SWITCH_EMULATOR_PATH" ]; then
  echo "Couldn't find behavioral model; please set path in SWITCH_EMULATOR_PATH"
  exit 1
fi

if [[ "$SWITCH_EMULATOR_PATH" == *\/ ]]; then
  SWITCH_EMULATOR_PATH=${SWITCH_EMULATOR_PATH%?}
fi

SWITCH_EXEC=${SWITCH_EMULATOR_PATH}/targets/simple_switch/simple_switch
CLI_EXEC=${SWITCH_EMULATOR_PATH}/targets/simple_switch/sswitch_CLI.py

function start_switch {
  SWITCH_SETTINGS=scenarios/${1}/build/l2sw.json ;
  COMMANDS_FILE=scenarios/${1}/commands.txt ;
  chmod +x $CLI_EXEC ;
  $SWITCH_EXEC -i 0@veth1 -i 1@veth3 -i 2@veth5 -i 3@veth7 $SWITCH_SETTINGS &
  sleep 2 ;
  $CLI_EXEC < $COMMANDS_FILE
}

function stop_switch {
  pkill -P $$
}

./tools/veth_setup.sh > /dev/null ;
for scenario in l2sw; do
  start_switch l2sw > /dev/null && \
  python3 -B scenarios/${scenario}/test.py && \
  stop_switch
done ;
./tools/veth_teardown.sh
