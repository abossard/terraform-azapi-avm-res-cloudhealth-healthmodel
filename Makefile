SHELL := /bin/bash
AVM_MAKEFILE_REF := main

$(shell curl -H 'Cache-Control: no-cache, no-store' -sSL "https://raw.githubusercontent.com/Azure/avm-terraform-governance/$(AVM_MAKEFILE_REF)/Makefile" -o avmmakefile)
-include avmmakefile

.PHONY: azapi-resource-compliance
azapi-resource-compliance:
	./tests/azapi-resource-compliance-test.sh

pr-check: azapi-resource-compliance

.PHONY: role-assignment-replacement
role-assignment-replacement:
	./tests/integration/role-assignment-replacement.sh

tf-test-integration: role-assignment-replacement
