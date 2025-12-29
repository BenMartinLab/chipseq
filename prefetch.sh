#!/bin/bash

# exit when any command fails
set -e

if [[ -n "$CC_CLUSTER" ]]
then
  module purge
  module load StdEnv/2023
  module load sra-toolkit/3.0.9
fi

script_path=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
cp "${script_path}/samplesheet.csv" .
awk -F ',' 'NR > 1 {print $8}' samplesheet.csv | parallel -t prefetch
awk -F ',' 'NR > 1 {print $8}' samplesheet.csv | xargs -L 1 vdb-validate 2>&1 | grep Database
