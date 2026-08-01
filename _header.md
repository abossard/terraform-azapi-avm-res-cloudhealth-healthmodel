# CloudHealth health model resource module candidate

> **Preview:** `Microsoft.CloudHealth/healthmodels@2026-05-01-preview` is a preview service/API. Microsoft may not provide support; check the product documentation before production use.

This repository is a staging implementation of the proposed `avm-res-cloudhealth-healthmodel` Terraform resource module. It is not an approved or published Azure Verified Module.

Its intended home is the repository `Azure/terraform-azapi-avm-res-cloudhealth-healthmodel`, which would publish to the Terraform Registry as `Azure/avm-res-cloudhealth-healthmodel/azapi`. That repository does not exist yet: the AVM module proposal has not been filed, the AVM core team has not approved it, and nothing has been published. Until then this checkout is a proposal artifact, not a consumable module.

The module manages one health model, its model-named root entity, and typed CloudHealth child resources. Callers compose multiple module instances for model-of-models architectures.

## Identity and authorization boundary

`role_assignments` creates role assignments **on the health model resource**. It does not authorize the health model's managed identity to read monitored resources.

The caller must grant the attached system- or user-assigned identity the built-in `Reader` role at every monitored Azure scope. Azure Monitor workspace and Log Analytics query scenarios can require additional data-plane permissions appropriate to those services. Metric names, PromQL, and KQL are evaluated by Azure; static Terraform validation cannot prove that a metric or query exists or returns data.

## Region availability

No location allow-list is embedded because preview availability changes. Query current CloudHealth provider availability before deployment and select a supported region.

## Releases and upgrade path

`v0.1.0` is tagged as a GitHub Release on this staging repository. It is **not** available from the Terraform Registry: registry listing requires the AVM proposal, core-team approval, and the `Azure/…` repository described above, none of which have happened. Consume this version by Git reference, not by registry `source`.

The release path follows the AVM specifications:

- **Pre-`1.0.0` versioning.** The first release is `v0.1.0`, and the module stays in the `v0.x.y` range until the AVM core team notifies the owner that `v1.0.0` is allowed. While below `1.0.0` the major version is never bumped: the **minor** version is bumped for breaking changes as well as for feature updates, and the **patch** version is bumped only for backward-compatible fixes. Consumers should therefore pin a minor version — for example `version = "~> 0.1.0"` — and read the release notes before moving to a new minor. See [SNFR17](https://azure.github.io/Azure-Verified-Modules/spec/SNFR17/) and [SNFR18](https://azure.github.io/Azure-Verified-Modules/spec/SNFR18/).
- **Release tags.** Releases are cut as GitHub Releases and every tag carries the `v` prefix.
- **First publication is manual.** For a brand-new module the owner must contact the AVM core team, via the [AVM - Module Triage](https://github.com/orgs/Azure/projects/529) project, to request the initial listing on the HashiCorp Terraform Registry.
- **Subsequent releases publish automatically.** Once the module is listed, later release tags are published to the registry without further core-team action. See the [AVM Terraform contribution flow](https://azure.github.io/Azure-Verified-Modules/contributing/terraform/contribution-flow/) and [SNFR19](https://azure.github.io/Azure-Verified-Modules/spec/SNFR19/).
- **Preview API caveat.** `Microsoft.CloudHealth` currently ships preview API versions only. A move to a stable API version will be treated as a breaking change and released under the rules above.
