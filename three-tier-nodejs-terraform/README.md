# Quick start

## Overview

[main.tf](main.tf) describes:
* A single EC2 instance running MariaDB.
* An auto-scaling group whose members run a NodeJS application that uses the database.
* Scale-down and scale-up policies that act when CPU usage crosses minimum and maxmium thresholds. 
* An ELB targetting the members of the auto-scaling group.


## Usage

Get Terraform from https://www.terraform.io/downloads.html.

Refer to the Terraform documentation on [variable configuration](https://www.terraform.io/docs/configuration/variables.html)
and [variables.tf](variables.tf) for the options expected. In particular you must supply values
for your AWS account and credential.

To accept the defaults in variables.tf and supply your AWS credentials as environment variables run:

```
export AWS_ACCESS_KEY_ID=<account>
export AWS_SECRET_KEY=<credential>
terraform apply
```

Some time later Terraform completes and outputs the address of the ELB:

```
Outputs:

elb = app-elb-2082232583.us-west-2.elb.amazonaws.com
```

The auto-scaling group uses cloud-init's [user-data](http://cloudinit.readthedocs.io/en/latest/topics/format.html#user-data-script)
to install and run the NodeJS app. Since this happens separately to Terraform's lifecycle the application
may take some time longer (generally between five and ten minutes) to be available at the ELB endpoint.

The auto-scaling policies act on CPU load and are configured to wait several minutes between each action.

To destroy the deployment run:

```
terraform destroy
```

And enter `yes` when prompted.
