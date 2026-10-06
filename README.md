# DAOCP quadruped benchmark

This fork of [dfki-quad](https://github.com/dfki-ric-underactuated-lab/dfki-quad)
extends its QP benchmark code with [DAOCP](https://github.com/AlbertoZaupa/daocp.git), implementing the quadruped benchmark from [this paper](https://arxiv.org/abs/2609.33451). It compares DAOCP,
HPIPM, DAQP and qpOASES on the original Go2 simulation trajectories, using
the same Eiquadprog whole-body controller for every MPC solver.

Docker downloads and builds [this acados fork](https://github.com/AlbertoZaupa/acados)
DAOCP. No host installation of either
library is required. Only the optional qpOASES, DAQP and DAOCP backends are
enabled in acados; HPIPM is built by default.

On an x86-64 Linux host with Docker installed, run:

```bash
./build_new_image.sh
# One standing and one trotting trajectory per solver, at N=20:
./automatic_solver_experiments.sh desktop mpc_fixed 123 20
# One trotting trajectory per solver at each N from 10 through 20:
./run_horizon_sweep.sh desktop 123
```

For just standing or trotting at a fixed horizon, use `mpc_stand` or
`mpc_trot` instead of `mpc_fixed`, which runs both. Horizon variants use separate Docker
build volumes. Results are ROS bags under `ws/src/solver_experiments/`, with
failed trajectories listed in `failed_attempts.txt`. The scripts return a
nonzero status when an experiment fails.

DAOCP and HPIPM use the uncondensed OCP; DAQP and qpOASES use full
condensing. Warm starting is enabled, HPIPM uses `SPEED_ABS`, and the solver
tolerance is `1e-3`.
`/solve_time` records QP diagnostics; `acados_total_time` includes condensing,
the backend solve and solution expansion.

The Docker build applies [a small acados interface patch](docker/patches/acados-benchmark.patch).
The HPIPM interface otherwise clears the previous primal solution before every
solve, defeating primal warm starting. The patch preserves it when warm
starting is enabled and retains the reset for cold starts. This is required
to obtain the intended warm-start performance. A separate Dockerfile
adjustment adapts the original WBC wrapper to the newer HPIPM API.

The robot model, controller and simulation come from the original repository;
see [upstream](https://github.com/dfki-ric-underactuated-lab/dfki-quad) for their
documentation and attribution. The original [license](LICENSE) is retained.
