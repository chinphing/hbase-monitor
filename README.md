docker compose的方式一次性安装和配置一下三个服务，用于java程序的监控。
  * influxdb 
  * jmxtrans 
  * grafana

### 要看到最终实现的效果，需要四个步骤：

1、监控的目标java程序启动时需要启用jmx，并且设置好jmx开放的端口，通过设置java的启动参数来实现。比如：hbase就是要启用hbase-env.sh中的下面几个选项：
    
    export HBASE_JMX_BASE="-Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
    export HBASE_MASTER_OPTS="$HBASE_MASTER_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10101"
    export HBASE_REGIONSERVER_OPTS="$HBASE_REGIONSERVER_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10102"
    export HBASE_THRIFT_OPTS="$HBASE_THRIFT_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10103"
    export HBASE_ZOOKEEPER_OPTS="$HBASE_ZOOKEEPER_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10104"
    export HBASE_REST_OPTS="$HBASE_REST_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10105"
  
  其中很重要的就是10101这个端口，用于开放HBase的基础统计数据，其他端口类似。
  
2、设置docker-compose.xml中的服务器ip地址以及对应的jmxtrans端口号，分别是：JMX_HOST_TEST，JMX_PORT_TEST

3、docker-compose up -d启动全部的服务。

4、在浏览器中打开http://服务器的ip:3000，用admin/admin登陆就可以看到效果。

###添加新的机器
 默认的配置中，只添加了一个监控机器，如果要添加新的机器的话，需要添加对应的配置，配置文件在conf/influxdb.json.tmpl中。
 
 
 另外可以考虑用nicolargo/docker-influxdb-grafana里面的Telegraf替换jmxtrans，因为Telegraf的应用范围更广泛，不只是能够监控java程序，几乎可以监控从操作系统到web服务器到消息队列到hbase等所有的程序，更适合做成一个监控平台。
