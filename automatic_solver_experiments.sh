#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 <platform_name> <mpc_fixed|mpc_stand|mpc_trot|mpc_horizon_sweep> <ros_domain_id> <horizon>" >&2
    exit 1
fi
platform_name=$1
preset=$2
domain_id=$3
horizon=$4
if [[ ! "$platform_name" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
    echo "Platform name may contain only letters, digits, dots, underscores and hyphens." >&2
    exit 1
fi
case "$preset" in
    mpc_fixed|mpc_stand|mpc_trot|mpc_horizon_sweep) ;;
    *) echo "Unknown benchmark preset: $preset" >&2; exit 1 ;;
esac
if [[ ! "$domain_id" =~ ^[0-9]{1,3}$ ]] || (( 10#$domain_id > 232 )); then
    echo "ROS_DOMAIN_ID must be an integer from 0 through 232." >&2
    exit 1
fi
if [[ ! "$horizon" =~ ^(1[0-9]|20)$ ]]; then
    echo "Horizon must be an integer from 10 through 20." >&2
    exit 1
fi
domain_id=$((10#$domain_id))

results_dir="$PWD/ws/src/solver_experiments/results"
if [[ -e "$results_dir" ]]; then
    echo "Move the existing staging directory before starting: $results_dir" >&2
    exit 1
fi
docker image inspect dfki_quad_daocp:latest >/dev/null
mkdir "$results_dir"

# Keep compiled variants separate. The simulator is started by the runner.
docker_options=(--rm --init --net=host
    --volume="$PWD/ws/src:/root/ros2_ws/src"
    --volume="dfki_quad_daocp_n${horizon}_build:/root/ros2_ws/build"
    --volume="dfki_quad_daocp_n${horizon}_install:/root/ros2_ws/install"
    --volume="dfki_quad_daocp_n${horizon}_log:/root/ros2_ws/log")

status=0
docker run "${docker_options[@]}" dfki_quad_daocp:latest /bin/bash -ci \
    "colcon build --symlink-install --cmake-args -DROBOT_NAME=go2 -DWITH_VICON=OFF -DMPC_PREDICTION_HORIZON=$horizon && source install/setup.bash && source /root/setup_ulab_workspace.bash && export ROS_DOMAIN_ID=$domain_id && ros2 run solver_experiments solver_experiments --ros-args -p mpc_prediction_horizon:=$horizon -p test_preset:=$preset" || status=$?

# Preserve failed runs too; the runner lists failed trajectories in the folder.
result_dir="$PWD/ws/src/solver_experiments/${platform_name}-N${horizon}-${preset}_$(date '+%Y%m%d_%H%M%S')"
mv "$results_dir" "$result_dir"
echo "Results: $result_dir"
exit "$status"
