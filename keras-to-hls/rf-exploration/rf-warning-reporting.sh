#!/bin/bash

#
# Report the result of the HLS4ML design space exploration.
#

#
# The script inputs are:
# - input parameters (e.g. RF, model, etc.)
# - Vivado HLS / Vivado .log file
#
# The script greps for WARNING messages on the Vivado HLS and Vivado
# log files.
#
# The script output is a text file with the list of warnings
#

if [ ! $# -eq 6 ]; then
    echo "USAGE: $0 <job-log> <project-directory> <model> <reuse-factor> <warning-file> <verbose>"
    exit 1
fi

JOB_LOG=$1

PROJECT_DIR=$2

MODEL=$3

REUSE_FACTOR=$4

WARNING_FILE=$5

VERBOSE=$6

APP_FILE=$PROJECT_DIR/vivado_hls.app
if [ ! -f $APP_FILE ]; then echo "ERROR: File $APP_FILE does not exist!"; exit 1; fi

# If it does not exist, create a new CSV file and set the header line.
if [ ! -f $WARNING_FILE ]; then
    touch $WARNING_FILE
fi

#ARCHS=$(cat $APP_FILE | sed -e 's/ xmlns.*=".*"//g' | xmlstarlet sel -t -m "/project/solutions/solution" -v "@name" -n)
ARCHS="solution1"
for ARCH in $ARCHS; do
    VIVADO_HLS_REPORT_XML="$PROJECT_DIR/$ARCH/syn/report/csynth.xml"
    VIVADO_HLS_LOG="$PROJECT_DIR/../vivado_hls.log"
    VIVADO_REPORT_XML="$PROJECT_DIR/$ARCH/impl/report/verilog/myproject_export.xml"
    #VIVADO_LOG="$PROJECT_DIR/$ARCH/impl/report/verilog/autoimpl.log"

    #
    # AWK on the job log from GNU parallel
    #
    VIVADO_HLS_EXIT_VAL=$(awk -v RF=$REUSE_FACTOR '$10 == RF { print $7 }' $JOB_LOG)
    if [ -z "$VIVADO_HLS_EXIT_VAL" ]; then VIVADO_HLS_EXIT_VAL=?; fi

    #
    # Check if the report files exist
    #
    #[ -f "$VIVADO_REPORT_XML" ]
    VIVADO_EXIT_VAL=$?
    # as an alternative:  grep ERROR $VIVADO_LOG

    echo "INFO: Model: $MODEL" >> $WARNING_FILE
    echo "INFO: Reuse Factor: $REUSE_FACTOR" >> $WARNING_FILE

    if [ ! $VIVADO_HLS_EXIT_VAL -eq 0 ]; then
        echo "INFO: Vivado HLS exit value: $VIVADO_HLS_EXIT_VAL" >> $WARNING_FILE
        grep WARNING $VIVADO_HLS_LOG  >> $WARNING_FILE
        grep ERROR $VIVADO_HLS_LOG  >> $WARNING_FILE
        if [ $VIVADO_HLS_EXIT_VAL -eq -1 ]; then
            echo "ERROR: Timeout" >> $WARNING_FILE
        fi
    fi

    if [ $VIVADO_HLS_EXIT_VAL -eq 0 ]; then
        echo "INFO: Vivado HLS exit value: $VIVADO_HLS_EXIT_VAL" >> $WARNING_FILE
        grep WARNING $VIVADO_HLS_LOG  >> $WARNING_FILE
    fi

    echo "" >> $WARNING_FILE

    #if  [ $VIVADO_HLS_EXIT_VAL -eq 0 ] && [ ! $VIVADO_EXIT_VAL -eq 0 ]; then
    #    echo "INFO: Vivado exit value: $VIVADO_EXIT_VAL" >> $WARNING_FILE
    #    grep WARNING $VIVADO_LOG  >> $WARNING_FILE
    #    grep ERROR $VIVADO_LOG  >> $WARNING_FILE
    #fi

done
