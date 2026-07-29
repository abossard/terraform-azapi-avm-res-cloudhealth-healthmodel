#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
scratch="${repo_root}/.terraform/azapi-resource-compliance-test-${BASHPID}"

cleanup() {
  rm -rf -- "${scratch}"
}
trap cleanup EXIT

python3 - "${repo_root}" "${scratch}" <<'PY'
from pathlib import Path
import shutil
import sys

root = Path(sys.argv[1])
scratch = Path(sys.argv[2])


def copy_candidate(name):
    destination = scratch / name
    destination.mkdir(parents=True)
    for source in root.glob("*.tf"):
        shutil.copy2(source, destination / source.name)
    for module in (root / "modules").iterdir():
        if not module.is_dir():
            continue
        module_destination = destination / "modules" / module.name
        module_destination.mkdir(parents=True)
        for source in module.glob("*.tf"):
            shutil.copy2(source, module_destination / source.name)
    return destination


def role_assignment_source(directory):
    path = directory / "main.interfaces.tf"
    source = path.read_text()
    role_start = source.index('resource "azapi_resource" "role_assignment" {')
    assignment_start = source.index("  replace_triggers_refs = [", role_start)
    assignment_end = source.index("\n  ]", assignment_start) + len("\n  ]")
    if assignment_end < len(source) and source[assignment_end] == "\n":
        assignment_end += 1
    return path, source, assignment_start, assignment_end


baseline = copy_candidate("baseline")

zero = scratch / "zero"
(zero / "modules").mkdir(parents=True)

for name in ("heredoc", "comment", "duplicate", "missing", "path-mismatch"):
    directory = copy_candidate(name)
    path, source, start, end = role_assignment_source(directory)
    assignment = source[start:end]

    if name == "heredoc":
        replacement = (
            "  compliance_probe = <<-EOT\n"
            "    replace_triggers_refs = []\n"
            "  EOT\n"
        )
    elif name == "comment":
        replacement = "  # replace_triggers_refs = []\n"
    elif name == "duplicate":
        replacement = assignment + "  replace_triggers_refs = []\n"
    elif name == "missing":
        replacement = ""
    else:
        replacement = assignment.replace(
            '"properties.principalId"',
            '"properties.notPrincipalId"',
            1,
        )

    path.write_text(source[:start] + replacement + source[end:])
PY

pass_count=0

expect_pass() {
  local name="$1"
  local fixture="$2"
  local output="${scratch}/${name}.log"

  if "${script_dir}/azapi-resource-compliance.sh" "${fixture}" >"${output}" 2>&1; then
    printf '%s: accepted\n' "${name}"
    pass_count=$((pass_count + 1))
    return
  fi

  printf '%s: expected acceptance, got:\n' "${name}" >&2
  cat "${output}" >&2
  exit 1
}

expect_rejection() {
  local name="$1"
  local fixture="$2"
  local output="${scratch}/${name}.log"

  if "${script_dir}/azapi-resource-compliance.sh" "${fixture}" >"${output}" 2>&1; then
    printf '%s: expected rejection, guard exited 0\n' "${name}" >&2
    cat "${output}" >&2
    exit 1
  fi

  printf '%s: rejected — %s\n' "${name}" "$(head -n 1 "${output}")"
  pass_count=$((pass_count + 1))
}

expect_pass "baseline" "${scratch}/baseline"
expect_rejection "zero-resource" "${scratch}/zero"
expect_rejection "heredoc-spoof" "${scratch}/heredoc"
expect_rejection "comment-spoof" "${scratch}/comment"
expect_rejection "duplicate-assignment" "${scratch}/duplicate"
expect_rejection "missing-assignment" "${scratch}/missing"
expect_rejection "path-mismatch" "${scratch}/path-mismatch"

printf 'compliance mutation tests: %s passed, 0 failed\n' "${pass_count}"
