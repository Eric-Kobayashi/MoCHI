# AGENTS.md

## Cursor Cloud specific instructions

MoCHI (`pymochi`) is a single scientific Python CLI/library (PyTorch-based model
fitting for deep mutational scanning data). There are **no long-running services**
— it runs, computes, writes output files, and exits.

### Environment
- The startup update script provisions a `uv`-managed Python **3.9** virtualenv at
  `/workspace/.venv` and installs the pinned deps from `pymochi.yaml` plus test
  tooling. Use `uv` for dependency management (not `pip`/`conda` directly).
- Run everything through the venv interpreter, e.g. `/workspace/.venv/bin/python`,
  `/workspace/.venv/bin/pytest`, `/workspace/.venv/bin/flake8`.
- Non-obvious: `setup.py` intentionally leaves `install_requires` empty (deps are
  conda-managed upstream), so `uv pip install -e .` does **not** pull runtime deps.
  Dependencies must be installed explicitly (the update script does this).
- Non-obvious: `torch==1.10.1` imports `pkg_resources`, so `setuptools` must be
  installed in the venv or `import pymochi` fails.

### Test / lint / run
- Tests: `/workspace/.venv/bin/pytest pymochi/tests/` (16 tests, ~5s).
- Lint: `/workspace/.venv/bin/flake8 pymochi` — configured (max line length 119 in
  `setup.cfg`) but the existing code has thousands of pre-existing style warnings;
  it is not a passing gate.
- Run the app / smoke test: `/workspace/.venv/bin/python pymochi/bin/demo_mochi.py`
  (README says <10min; runs in ~15s on CPU). It writes results to
  `mochi_project_demo/` in the current working directory, so run it from a scratch
  dir. Core CLI is `pymochi/bin/run_mochi.py --model_design <file>`.
