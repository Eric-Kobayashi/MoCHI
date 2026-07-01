# AGENTS.md

## Cursor Cloud specific instructions

MoCHI (`pymochi`) is a single scientific Python CLI/library (PyTorch-based model
fitting for deep mutational scanning data). The core product has **no long-running
services** — it runs, computes, writes output files, and exits.

This branch (`parallel-nextflow-folds`) also adds an **optional** Nextflow pipeline
under `nextflow/` for running cross-validation folds in parallel on an LSF+GPU
cluster.

### Environment
- This branch is `uv`-native: `pyproject.toml` + `uv.lock`, `requires-python >=3.11`.
  The startup update script provisions a `uv`-managed Python **3.11** virtualenv at
  `/workspace/.venv` via `uv sync --frozen` (same as `bootstrap_mochi_uv.sh`) and
  adds test tooling (pytest/flake8). Use `uv` for deps, not `pip`/`conda` directly.
- Run everything through the venv interpreter, e.g. `/workspace/.venv/bin/python`,
  `/workspace/.venv/bin/pytest`, `/workspace/.venv/bin/flake8`.
- `torch` is resolved from the CUDA-12.4 index (`torch==2.6.0+cu124` per `uv.lock`).
  This VM is CPU-only (`torch.cuda.is_available()` is `False`); the cu124 build runs
  fine on CPU. GPU-only tests auto-skip via `@pytest.mark.skipif(not
  torch.cuda.is_available())`.
- Behavior env vars used by the code: `MOCHI_DEVICE` (cpu|cuda|auto),
  `MOCHI_PARALLEL_MODE`, `MOCHI_GPU_PREFETCH`, `MOCHI_AMP` (see `pymochi/models.py`).

### Test / lint / run
- Setup / smoke: `bash bootstrap_mochi_uv.sh` (runs `uv sync --frozen` + verifies
  imports; the startup update script already does this).
- Tests: `/workspace/.venv/bin/pytest pymochi/tests/`. Current state: 49 passed,
  1 skipped (CUDA), 1 pre-existing failure
  (`test_MaterializingRowDataLoader_cpu_batches_match_materialized_split`) — that
  test expects a dense feature tensor but the `max_interaction_order=2` fixture is
  sparse-native, so the sibling sparse test contradicts it. This is a branch
  code/test issue, not an environment problem.
- Lint: `/workspace/.venv/bin/flake8 pymochi` (configured, max line length 119 in
  `setup.cfg`; many pre-existing warnings — not a passing gate).
- Run the app: `/workspace/.venv/bin/python pymochi/bin/demo_mochi.py` (runs in
  ~15s on CPU; writes to `mochi_project_demo/` in the CWD, so run from a scratch
  dir). Core CLI is `pymochi/bin/run_mochi.py --model_design <file>`.

### Nextflow pipeline (optional, cluster-only)
- `nextflow/scripts/submit_mochi_master_lsf.sh` / `run_mochi_lsf_gpu.sh` submit to an
  **LSF** scheduler and request **GPUs** (`bsub`, `gpack`, MIG). They cannot run in
  this CPU-only VM without an LSF cluster + GPUs + a `nextflow` binary/Java, and are
  out of scope for local dev. See `nextflow/RUN.md`.
