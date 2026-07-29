#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
output="${repo_root}/.terraform/role-assignment-replacement-${BASHPID}.jsonl"

cleanup() {
  rm -f -- "${output}"
}
trap cleanup EXIT

cd -- "${repo_root}"
mkdir -p .terraform
terraform init -backend=false -test-directory=tests/integration -input=false -no-color >/dev/null

if ! terraform test \
  -test-directory=tests/integration \
  -filter=tests/integration/role-assignment-replacement.tftest.hcl \
  -verbose \
  -json >"${output}"; then
  jq -r 'select(.type == "diagnostic") | .diagnostic.summary + ": " + .diagnostic.detail' "${output}" >&2
  exit 1
fi

address='azapi_resource.role_assignment["reader"]'

jq -s -e --arg address "${address}" '
  def replacement_actions(run_name):
    [
      .[]
      | select(.type == "test_plan" and .["@testrun"] == run_name)
      | .test_plan.resource_changes[]
      | select(.address == $address)
      | .change.actions
    ];

  replacement_actions("principal_change_replaces_role_assignment") == [["delete", "create"]]
  and replacement_actions("description_change_replaces_role_assignment") == [["delete", "create"]]
' "${output}" >/dev/null

printf '%s\n' 'principal_change_replaces_role_assignment: -/+; Plan: 1 to add, 0 to change, 1 to destroy.'
printf '%s\n' 'description_change_replaces_role_assignment: -/+; Plan: 1 to add, 0 to change, 1 to destroy.'
