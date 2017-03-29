# Quick start

## Overview

[app.bom](app.bom) is a [Cloudsoft AMP](https://cloudsoft.io/getamp/) blueprint describing a simple 
three-tier application:
* An instance running MariaDB.
* A cluster of NodeJS servers.
* Auto-scaling policies acting on metrics published.by the Node application
* An Nginx load balancer fronting the Node servers.

In supported clouds (AWS EC2 and OpenStack) [network security rules](https://cloudsoft.io/blog/amp-network-security)
restrict the communication between components so that only the Node servers may access the database,
only the load balancer may access the Node servers and only the load balancer may be accessed from 
the public internet.

## Usage

To install and run Cloudsoft AMP and its CLI refer to the AMP 
[getting started guide](https://docs.cloudsoft.io/start/index.html).
Once the server is running add [locations](https://docs.cloudsoft.io/locations/first-location/)
for the clouds you want to target.


Use the `br` CLI tool to add `nodejs.bom`, `mariadb.bom` and `app.bom` to the catalog:

```
br catalog add ./mariadb.bom
br catalog add ./nodejs.bom
br catalog add ./app.bom
```

Then use the AMP UI to deploy `example-app` to your chosen location.

The auto-scaling policies on the Node cluster respond to the average number of `GET` requests to each
member. Scale-up occurs when the average crosses 100 reqs/sec and scale-down occurs when the average
falls below 50 reqs/sec.

To destroy the deployment use the `stop` effector on the application.
