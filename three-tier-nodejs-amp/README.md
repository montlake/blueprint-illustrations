# Quick start

## Overview

Extends the Apache Brooklyn blueprints in [brooklyn-app.bom](../three-tier-nodejs-brooklyn/brooklyn-catalog.bom)
to use [Cloudsoft AMP's](https://cloudsoft.io/getamp/) network security features.
 
In supported clouds (AWS EC2 and OpenStack) [network security rules](https://cloudsoft.io/blog/amp-network-security)
restrict the communication between components so that only the Node.js servers may access the database,
only the load balancer may access the Node.js servers and only the load balancer may be accessed from 
the public internet.


## Usage

To install and run Cloudsoft AMP and its CLI refer to the AMP 
[getting started guide](https://docs.cloudsoft.io/start/index.html).
Once the server is running add [locations](https://docs.cloudsoft.io/locations/first-location/)
for the clouds you want to target.

Add `base-software-process.bom`, `nodejs.bom`, `mariadb.bom` and `brooklyn-app.bom` to the catalog as 
per the instructions for Apache Brooklyn, then add `amp-catalog.bom` from this project.

Use the Brooklyn CLI tool to deploy `app.yaml`:
```
br deploy app.yaml
```

The auto-scaling policies on the Node cluster respond to the average number of `GET` requests to each
member. Scale-up occurs when the average crosses 100 reqs/sec and scale-down occurs when the average
falls below 50 reqs/sec. The [Brooklyn entity for Apache JMeter](https://github.com/cloudsoft/jmeter-entity/)
is a useful way to demonstrate this.

To destroy the deployment use the `stop` effector on the application.
