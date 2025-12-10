#!/bin/bash

script_path=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
cd "$script_path" || { echo "Folder $script_path does not exists"; exit 1; }
source nfcore-modules.sh
source nfcore-env/bin/activate

nf-core pipelines download \
    --download-configuration yes \
    --container-cache-utilisation amend \
    --container-system singularity \
    --compress none \
    -d 6 \
    -r 2.1.0 \
    chipseq
