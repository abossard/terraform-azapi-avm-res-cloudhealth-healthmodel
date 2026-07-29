#!/usr/bin/env bash

set -euo pipefail

readonly output="$(
  terraform test \
    -test-directory=tests/unit \
    -filter=tests/unit/root.tftest.hcl \
    -verbose \
    -no-color 2>&1
)"

readonly expected_types=(
  'Microsoft.CloudHealth/healthModels@2026-05-01-preview'
  'Microsoft.CloudHealth/healthModels/authenticationSettings@2026-05-01-preview'
  'Microsoft.CloudHealth/healthModels/discoveryRules@2026-05-01-preview'
  'Microsoft.CloudHealth/healthModels/entities@2026-05-01-preview'
  'Microsoft.CloudHealth/healthModels/relationships@2026-05-01-preview'
  'Microsoft.CloudHealth/healthModels/signalDefinitions@2026-05-01-preview'
)

for expected_type in "${expected_types[@]}"; do
  if ! rg --fixed-strings --quiet "${expected_type}" <<<"${output}"; then
    printf 'missing cascaded resource type: %s\n' "${expected_type}" >&2
    exit 1
  fi
done

printf 'resource type override plan contains all %s root/child types\n' "${#expected_types[@]}"
