# Quick start

## Overview


`app.yaml` describes a cluster of [Apache Spark](https://spark.apache.org/) nodes to which Spark applications can subsequently be deployed. It uses definitions from the [brooklyn-spark](https://github.com/brooklyncentral/brooklyn-spark) project written by the [Apache Brooklyn](https://brooklyn.apache.org/) community.

## Usage

To install and run Apache Brooklyn and its CLI refer to the Brooklyn
[getting started guide](https://brooklyn.apache.org/v/latest/start/running.html).
Once the server is running add [locations](https://brooklyn.apache.org/v/latest/start/blueprints.html#locations)
for the clouds you want to target.

Use the `br` CLI tool to add `brooklyn-spark.bom` to the catalog and then deploy `app.yaml`:

```
br catalog add https://raw.githubusercontent.com/Montlake/blueprint-illustrations/spark-demo-brooklyn/brooklyn-spark.bom
br deploy https://raw.githubusercontent.com/Montlake/blueprint-illustrations/spark-demo-brooklyn/app.yaml
```

This will deploy the blueprint to AWS EC2 in region us-west-2.

To submit a Spark application click on one of your Spark clusters, invoke the "SubmitSparkApp" effector, the output of the effector will go be displayed in the effectors activity tab.

To destroy the deployment use the `stop` effector on the application.

Or use the `br` CLI tool:

```
# list the applications
br app 

    Id           Name                Status    Location
    x5jg2kaxc9   Example App         RUNNING   do2dmc7xhk

# stop the app
br app x5jg2kaxc9 stop
```
