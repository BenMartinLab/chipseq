#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=2:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=scale-factors-%A.out

script_name=$(basename "${BASH_SOURCE[0]}")
script_path=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
if ! [[ -f "${script_path}/${script_name}" ]] && [[ -n "$SLURM_JOB_ID" ]]
then
  slurm_command=$(scontrol show job "$SLURM_JOB_ID" | awk -F '=' '$0 ~ /Command=/ {print $2; exit}')
  script_name=$(basename "$slurm_command")
  script_path=$(dirname "$slurm_command")
fi
source "${script_path}/nfcore-env/bin/activate"

echo "Running python script ${script_path}/scale-factors.py"
python "${script_path}/scale-factors.py" "$@"
