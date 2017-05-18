# Quick start

## Overview

[brooklyn-app.bom](brooklyn-catalog.bom) is an [Apache Brooklyn](https://brooklyn.apache.org/) 
blueprint describing a simple three-tier application:
* An instance running MariaDB.
* A cluster of Node.js servers.
* Auto-scaling policies acting on metrics published.by the Node.js application
* An Nginx load balancer fronting the Node.js servers.


## Usage

To install and run Apache Brooklyn and its CLI refer to the Brooklyn
[getting started guide](https://brooklyn.apache.org/v/latest/start/running.html).
Once the server is running add [locations](https://brooklyn.apache.org/v/latest/start/blueprints.html#locations)
for the clouds you want to target.

Use the `br` CLI tool to add `base-software-process.bom`, `nodejs.bom`, `mariadb.bom`
and `brooklyn-app.bom` to the catalog:

```
br catalog add ./base-software-process.bom
br catalog add ./mariadb.bom
br catalog add ./nodejs.bom
br catalog add ./brooklyn-app.bom
```

Then deploy `app.yaml`:
```
br deploy app.yaml
```

The auto-scaling policies on the Node cluster respond to the average number of `GET` requests to each
member. Scale-up occurs when the average crosses 100 reqs/sec and scale-down occurs when the average
falls below 50 reqs/sec.

To destroy the deployment use the `stop` effector on the application.
