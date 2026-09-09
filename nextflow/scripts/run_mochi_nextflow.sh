#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${MOCHI_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
NEXTFLOW_ROOT="${NEXTFLOW_ROOT:-${REPO_ROOT}/nextflow}"
NEXTFLOW_BIN="${NEXTFLOW_BIN:-nextflow}"
MOCHI_VENV="${MOCHI_VENV:-${REPO_ROOT}/.venv}"
PYTHON_BIN="${PYTHON_BIN:-${MOCHI_VENV}/bin/python}"
NEXTFLOW_PROFILE="${NEXTFLOW_PROFILE:-local}"
RESUME="${RESUME:-0}"
# The workflow config uses legacy dynamic closures. Nextflow 26.04 enables
# its strict parser by default, so select the compatible parser unless callers
# have explicitly chosen one.
export NXF_SYNTAX_PARSER="${NXF_SYNTAX_PARSER:-v1}"

param_value_from_args() {
    local key="${1}"
    shift
    local arg=""
    local next=""
    while [ "$#" -gt 0 ]; do
        arg="${1}"
        next="${2:-}"
        if [ "${arg}" = "--${key}" ] && [ -n "${next}" ]; then
            printf '%s' "${next}"
            return
        fi
        case "${arg}" in
            --${key}=*)
                printf '%s' "${arg#*=}"
                return
                ;;
        esac
        shift
    done
}

if ! command -v "${NEXTFLOW_BIN}" >/dev/null 2>&1; then
    echo "Nextflow executable not found: ${NEXTFLOW_BIN}" >&2
    echo "Install Nextflow and Java, or set NEXTFLOW_BIN to its path." >&2
    exit 1
fi

if ! command -v "${PYTHON_BIN}" >/dev/null 2>&1 && [ ! -x "${PYTHON_BIN}" ]; then
    echo "Python interpreter not found at ${PYTHON_BIN}" >&2
    exit 1
fi

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    exec "${NEXTFLOW_BIN}" run -help
fi

RUN_NAME="${RUN_NAME:-$(param_value_from_args run_name "$@")}"
RUN_NAME="${RUN_NAME:-mochi-benchmark-$(date +%Y%m%d_%H%M%S)}"
OUTPUT_ROOT="${OUTPUT_ROOT:-$(param_value_from_args output_root "$@")}"
OUTPUT_ROOT="${OUTPUT_ROOT:-${PWD}/results}"
WORK_DIR="${WORK_DIR:-${OUTPUT_ROOT%/}/${RUN_NAME}/work}"

nextflow_args=(
    run "${NEXTFLOW_ROOT}/main.nf"
    -profile "${NEXTFLOW_PROFILE}"
    -c "${NEXTFLOW_ROOT}/nextflow.config"
    -work-dir "${WORK_DIR}"
    --repo_root "${REPO_ROOT}"
    --nextflow_root "${NEXTFLOW_ROOT}"
    --mochi_venv "${MOCHI_VENV}"
    --mochi_python "${PYTHON_BIN}"
    --output_root "${OUTPUT_ROOT}"
    --run_name "${RUN_NAME}"
    "$@"
)

if [ "${RESUME}" = "1" ]; then
    nextflow_args+=(-resume)
fi

exec "${NEXTFLOW_BIN}" "${nextflow_args[@]}"
