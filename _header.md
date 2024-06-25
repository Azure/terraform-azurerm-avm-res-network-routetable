# terraform-azurerm-avm-res-network-routetable

This is a module for deploying an Azure static route table. It should be used to deploy the route tabe, routes, and connect them to a subnet.

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are to be expected. 
> 
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

## Features And Notes
- This module deploys a route table.
- It can optionally also deploy a list of routes and connection to subnets.
- For information on the Azure virtual network traffic routing, see [Virtual Network Traffic Routing](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview).
- For information on the Azure virtual network custom routes, see [User Defined Routes](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview#custom-routes).

## Feedback
- Your feedback is welcome! Please raise an issue or feature request on the module's GitHub repository.
