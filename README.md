Introduction
------------

This repository contains a docker-compose configuration for monitoring a JVM using JMX with following stack

* influxdb 1.1
* jmxtrans (latest)
* grafana 4.0

Jmxtrans is writing statistics to InfluxDB in this case. Grafana will then read back from InfluxDB and visualize the statistics in a configurable dashboard.

Setup
-----

The setup can be started after installing docker and docker-compose. Minimum required version for docker is 1.10.0 and 1.7.0 for docker-compose. 
Installation instructions can be found on the docker website.

Once this is done, a simple `docker-compose up` will generate the needed config files for the defined environment variables. 
An environment can be easily added by adding new variables in the docker compose file, suffixed by the environment name. 

For example

```
JMX_HOST_PROD=prod170
JMX_PORT_PROD=175000
JMX_ALIAS_PROD=prod
```

Name of the created dashboard for CERN is PROD and is used to do the required configuration for jmxtrans and grafana. A new dashboard should be present after the
stack is started. 

Grafana
-------
Grafana can be accessed by opening the :3000 url in a browser. Default login is admin/admin and can be changed once it is running.
