#!/bin/bash

if [ ! -d ./tt ]; then
cat <<EOH
ABORTING as ./tt/ does not exist yet.
See the tt-support-tools step of: https://tinytapeout.com/guides/local-hardening/
Typically, you'd do:
1. git clone https://github.com/TinyTapeout/tt-support-tools tt
2. Source this script to create/activate a common venv (in ~/ttsetup@...): source $0
3. pip install -r tt/requirements.txt
4. pip install librelane==\$LIBRELANE_TAG
NOTE: You can read the contents of this script for some of that, e.g. the VENV part.
This will typically be followed by:
1. ./tt/tt_tool.py --gf --create-user-config
2. ./tt/tt_tool.py --gf --harden
NOTE: After the 1st run of harden step above, you should find the gf180mcuD PDK in \$TTTOOLS/pdk
EOH
else

    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        echo "WARNING: It looks like you ran $0 directly."
        echo "NORMALLY you should instead run: source $0"
        echo "MAYBE you want to give that another try?"
    fi

    # The following parameters are from:
    # https://tinytapeout.com/guides/local-hardening/#4-set-up-environment-variables
    # but can also be verified against:
    # https://github.com/TinyTapeout/tt-gds-action/blob/ttgf0p2/action.yml

    export TTPYTHON=python3.12
    export TTPROMPT=ttgf0p2
    export TTTOOLS=$HOME/ttsetup@$TTPROMPT
    mkdir -p "$TTTOOLS/pdk"
    export PDK_ROOT=$TTTOOLS/pdk
    export PDK=gf180mcuD
    # export OPENLANE_IMAGE_OVERRIDE=ghcr.io/tinytapeout/openlane2:ihp-v3.0.0.dev23
    # export TT_ARGS=--ihp
    export LIBRELANE_TAG=2.4.2

    # Mangling of https://github.com/TinyTapeout/tt-gds-action/blob/ac4c7934481e7c5fb9afa202a72a14025e78e13f/action.yml#L122
    export LINTER_LOG_BASE="runs/wokwi/*-verilator-lint/verilator-lint.log"

    export VENV_DIR="$TTTOOLS/venv"
    export VENV_CMD="$VENV_DIR/bin/activate"
    if [ ! -e "$VENV_CMD" ]; then
        echo "NOTE: Venv $VENV_CMD doesn't exist; creating it..."
        $TTPYTHON -m venv --prompt "$TTPROMPT" "$VENV_DIR"
        echo "DONE."
    fi
    echo "Activating VENV..."
    source "$VENV_CMD"
    echo "NOTE: If prompt doesn't include '($TTPROMPT)' then make sure you run this script via 'source'"

fi
