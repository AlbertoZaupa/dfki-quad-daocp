#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <platform_name> <ros_domain_id>" >&2
    exit 1
fi
for horizon in {10..20}; do
    ./automatic_solver_experiments.sh "$1" mpc_horizon_sweep "$2" "$horizon"
done
