# Overview

This repository contains examples illustrating how
[Terraform](https://www.terraform.io/), [Apache
Brooklyn](https://brooklyn.apache.org/),
and [Cloudsoft AMP](https://cloudsoft.io/amp) work, similarities and
differences, so people can evaluate when to use each.

The blueprints deploy a simple Node.js “TODO” application. Items are added and
removed to a list via a web interface. Items are persisted to a MySQL backend.
In the Brooklyn and AMP versions, the Node.js servers autoscale with demand,
and traffic is automatically load-balanced between instances.

Please refer to the documentation within each implementation for deployment
directions:
- [Three Tier Node.JS Terraform](./terraform/README.md)
- [Three Tier Node.JS Apache Brooklyn](./brooklyn/README.md)
- [Three Tier Node.JS Cloudsoft AMP](./amp/README.md)

# Deployment

For clarity, all implementations use shell-based provisioning, and for brevity
minimal capabilities for each component are configured. For example, the MySQL
database is not general-purpose or highly reusable; it is built for the
purposes of this demonstration. (Better MySQL blueprints are available in both
the Brooklyn/AMP and the Terraform communities).

It is straightforward in either Brooklyn/AMP or Terraform to write fuller
blueprints which are generalized and encapsulated for reuse as building blocks.

## Terraform

For Terraform we deploy 3 components: 

- A single node MySQL/MariaDB database, configured with a database/table
  appropriate for the “TODO” application
- A cluster of Node.JS servers in an AWS-specific Auto-Scaling Group
- An AWS Elastic Load Balancer: we chose to use ELB as it makes it simple for us
  to leverage an AWS autoscaling group (this is the standard pattern when using
  AWS and TF)

Each component is placed on the same subnet. The database and Node instances
use a security group that allows ingress from all addresses on the subnet. The
ELB component uses a security group that allows ingress on port 80 from
0.0.0.0/0. 

## Apache Brooklyn

The Brooklyn blueprint defines the entitines or components that are used in the
Brooklyn and AMP deployments.

- A single node MySQL/MariaDB database, configured with a database/table
  appropriate for the “TODO” application
- A cluster of Node.JS servers that provide the application logic, persisting to
  the database. Connectivity to the database is determined dynamically
- An Nginx-based load balancer. AMP can also configure platform and
  cloud-specific load balancers, and F5 boxes (as done for the Weather Company
  project); however Nginx is a quick and easy way to achieve immediate
  portability

The `nodejs.bom` and `mariadb.bom` are generic blueprints for those two
components, with no special application logic for this use case and no special
assumptions for AWS or a specific cloud.  The `brooklyn-app.bom` blueprint
passes config to those elements to set up the “TODO” application.

## Cloudsoft AMP

The blueprint deployed and managed by Cloudsoft AMP reuses the entities defined
in the Apache Brooklyn blueprint.

The AMP blueprint deplys in the same way as the Apache Brooklyn Blueprint, with
the addition that the blueprint also configures resources for “Application
Network Security”: Network segregation and accessibility is determined through
assigning named network entities within the blueprint, and the security
controls are applied using the mechanisms available on the target cloud or
platform. Application Network Security is currently supported on AWS and
OpenStack.

In this case, only the load balancer will be exposed on the public internet,
and other resources will be isolated.

# In-life management

## Terraform

For Terraform, an autoscaling group was configured to scale Node.JS based
on CPU utilization. Terraform does not offer facilities that automate failure
detection and node/service replacement. 

## Apache Brooklyn

In Apache Brooklyn, in-life management is accomplished primarily by applying
“policies” to entities within the blueprint. Policies observe certain
conditions of the application, the infrastructure on which it runs, or external
dependencies, make decisions about actions to take based on those observations,
and then take the appropriate action. 

For this application, we’ve placed four standard policies on the Node.JS entity
or cluster of entities. 
1. There is a service restarter on the Node.JS instance. Should the Node.JS
   process fail, it is automatically restarted
2. There is a failure detector on the JodeJS instance. This emits an “Entity
   Failed” event whenever a failure is detected, and similarly an “Entity
   Recovered” event when recovered.
3. On the Node.JS cluster there is a service replacer, which will replace a failed
   node with a newly provisioned one.
4. Finally, also on the Node.JS cluster there is an auto-scaler policy.
   Auto-scaling, and all policies, in AMP are extremely flexible, and may be
   triggered on any observable condition, individually or taken in aggregate. In
   this case we are scaling the Node.JS cluster on a metric provided by the
   Node.JS application itself [metric, and link to line]. In other cases we may
   choose to scale on CPU usage, requests per second, etc.

## Cloudsoft AMP

In-life management in the AMP deployment of this application is identical to
that mentioned above for Apache Brooklyn. 

# Conclusion

This repository shows a simple AMP-managed application side-by-side with the
analagous Terraform-deployed application. The following table briefly
summarizes other Brooklyn/AMP capabilities as they relate to Terraform. 

| Capability                                                                                   | Cloudsoft AMP/Apache Brooklyn                                                                                                                                             | Terraform                                                                                                                                                                                           |
|----------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Provision Secure 3-tier Autoscaling App in AWS                                               | YES                                                                                                                                                                       | YES                                                                                                                                                                                                 |
| Deploy elswhere: Softlayer, OpenStack, Azure, Kubernetes                                     | YES - The same blueprint works in all these clouds                                                                                                                        | PARTLY - New blueprints need to be written for each environment. Many items (ELB, auto-scaling) are specific to particular clouds.                                                                  |
| Live view of deployed resoures                                                               | YES                                                                                                                                                                       | PARTLY - Infrastructure Only. TF will show resources created by its providers but does not model processes or systems and it does not integrate with monitoring tools to show status                |
| Custom Policies                                                                              | YES - This is the main objective of autonomic management                                                                                                                  | NO. Not in Scope                                                                                                                                                                                    |
| Support for Cloud Service (DNS, S3, RedShift, etc)                                           | PARTLY - Blueprints can be written for any cloud service, with some available (e.g. AWS S3, R53, ELB) but the main focus is on portability, not on every native offering. | PARTLY, provision only - Excellent coverage for provisioning native services, but does not interact subsequently; relies on cloud-provider supplied integrations, e.g. AWS ELB + auto-scaling group |
| Integrations (Salt, Chef, Bash, Docker Images, REST calls, logstash, monitoring, ServiceNOW) | YES - Extensive integrations with authoring, monitoring, and management tools — you can even use Terraform                                                                | PARTLY - Custom provisioners can be written but there are not very many.                                                                                                                            |
| Community Size                                                                               | Small (enterprise-focused)                                                                                                                                                | Medium                                                                                                                                                                                              |
| Foundation-run Community                                                                     | Yes - Apache Sofware Foundation                                                                                                                                           | No - HashiCorp                                                                                                                                                                                      |
| Deploys Upgrades                                                                             | Partly - [improvements in progress](https://docs.google.com/document/d/1Lm47Kx-cXPLe8BO34-qrL3ZMPosuUHJILYVQUswEH6Y/edit#heading=h.gwaayi613qqk)                          | Yes                                                                                                                                                                                                 |



