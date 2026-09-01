"""Launch the Nextflow workflow installed with pymochi."""

import os
import shutil
import subprocess
import sys
import sysconfig
from pathlib import Path


def workflow_root() -> Path:
    """Return the installed workflow directory."""
    configured_root = os.environ.get("MOCHI_NEXTFLOW_ROOT")
    root = Path(configured_root) if configured_root else (
        Path(sysconfig.get_path("data")) / "share" / "pymochi" / "nextflow"
    )
    if not (root / "main.nf").is_file():
        raise RuntimeError(
            f"MoCHI Nextflow workflow not found at {root}. "
            "Set MOCHI_NEXTFLOW_ROOT to a workflow directory."
        )
    return root


def main() -> None:
    """Run the installed workflow with the current Python environment."""
    root = workflow_root()
    launcher = root / "scripts" / "run_mochi_nextflow.sh"
    if not launcher.is_file():
        raise RuntimeError(f"MoCHI Nextflow launcher not found at {launcher}")

    environment = os.environ.copy()
    environment["NEXTFLOW_ROOT"] = str(root)
    environment["MOCHI_REPO"] = str(Path(__file__).resolve().parents[2])
    environment["PYTHON_BIN"] = sys.executable
    subprocess.run(["bash", str(launcher), *sys.argv[1:]], env=environment, check=True)


if __name__ == "__main__":
    main()
