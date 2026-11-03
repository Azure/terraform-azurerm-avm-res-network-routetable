# terraform-azurerm-avm-res-network-routetable

This is a module for deploying an Azure static route table. It deploys the route table and its routes.

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are to be expected. 
> 
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

## Features And Notes
- This module deploys a route table.
- It can optionally also deploy a list of routes. Associate the route table with subnets in the subnets' own configuration.
- For information on the Azure virtual network traffic routing, see [Virtual Network Traffic Routing](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview).
- For information on the Azure virtual network custom routes, see [User Defined Routes](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview#custom-routes).

## Upgrading from 0.6.x or earlier

The route table, its lock and role assignments, and the routes managed while `routes_legacy_mode` is true are now AzAPI resources, and the module no longer uses the AzureRM provider. `moved` blocks carry them to their new addresses in the state, so nothing is recreated. Terraform 1.11 or later is required.

1. `subnet_resource_ids` is no longer supported, because AzAPI cannot remove a subnet association when it is deleted. Remove the input before upgrading. The associations it created stay in Azure and are removed from the state without being changed, so no subnet is routed differently. Terraform still needs the AzureRM provider to remove them from the state, so keep its `provider` block in your root module until the upgrade has been applied. Associate the route table in each subnet's configuration instead, for example with the `route_table` attribute of the subnets of the `Azure/avm-res-network-virtualnetwork/azurerm` module, or the `properties.routeTable.id` property of a subnet. The association already exists, so this changes nothing in Azure, but a separate association resource has to be imported rather than created. A route table that is still associated with a subnet cannot be deleted.
1. A `ReadOnly` lock blocks the upgrade, because the route table and its role assignments are updated. Change it to `CanNotDelete`, or remove it, until the upgrade is applied.
1. Cross-tenant role assignments, which set `delegated_managed_identity_resource_id`, need extra steps. The AzureRM provider stored their ID with a `|<tenant-id>` suffix that the `moved` block cannot convert. Before planning, remove each one from the state, then import it at its new address with an `import` block in your root module:

   ```pwsh
   terraform state rm 'module.<module-name>.azurerm_role_assignment.this["<key>"]'
   ```

   ```hcl
   import {
     to = module.<module-name>.azapi_resource.role_assignments["<key>"]
     id = "<role assignment resource ID, without the |<tenant-id> suffix>"
   }
   ```

1. Run `terraform init -upgrade`, then `terraform plan`. The plan must not destroy or replace anything except the AVM telemetry deployment, whose name includes the module version. It updates the route table, its lock and role assignments, and the routes managed in legacy mode, in place with the same settings. Routes managed by the route submodule are not changed. The plan also adds:
   - a `random_uuid` for each role assignment, which only exists in the state. The assignments keep their names;
   - `time_sleep.lock_removal`, when a lock is set;
   - AVM telemetry resources, when telemetry is enabled. The telemetry resources of 0.5.x or earlier are removed from the state without being destroyed.

   Role assignment descriptions were not sent by earlier versions. A description you set is added to the existing assignment in place.
1. Apply the plan. The route table is updated with the same settings, and its routes are read from Azure and sent back unchanged. Later plans report no changes, except that, when telemetry is enabled, each plan updates the AVM telemetry deployment to record the apply.

Route tables deployed with version 0.4.x or earlier keep their routes in place only while `routes_legacy_mode` is true. Do not change `routes_legacy_mode` for an existing route table.

Other changes:

- `parent_id` can be set instead of `resource_group_name`.
- `resource_types`, `retry`, `timeouts` and `ignore_body_changes` cover the route table, its routes, lock and role assignments, and are passed to the route submodule.
- `lock` accepts `notes`, and `role_assignments` accepts `name`.
- The `resource` output keeps the attribute names of the `azurerm_route_table` resource, and while `routes_legacy_mode` is true the `routes` output keeps those of the `azurerm_route` resource.
- Role names are matched, ignoring case, against the role definitions that can be assigned in the resource group, and an unknown name fails during plan.
- Route table and route names are validated during plan.
- The route in the route submodule moved to `azapi_resource.this`. A `moved` block updates the state, including for configurations that call the submodule directly.

## Feedback
- Your feedback is welcome! Please raise an issue or feature request on the module's GitHub repository.
