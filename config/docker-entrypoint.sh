#!/bin/bash -x
#
# The MIT License
# Copyright © 2010 JmxTrans team
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

set -e


set_conf () {
    if [ $# -ne 3 ]; then
        echo "set_conf requires three arguments: <key> <value> <env>"
        exit 1
    fi
    
    REPLACE=$(echo "$2" | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')
    echo "$3"
    find /var/lib/jmxtrans -type f -name "*-$3.json" -exec sed -i 's|'\${"$1"}'|'"$REPLACE"'|g' {} \;
    find /dashboards -type f -name "*-$3.json" -exec sed -i 's|'\${"$1"}'|'"$REPLACE"'|g' {} \;
}

for e in $(env); do
    key=${e%=*}
    value=${e#*=}
    if [[ $key == JMX_* ]]; then 
        env=${key##*_}
        key=${key%_*}
        if [ ! -f /var/lib/jmxtrans/influxdb-$env.json -o ! -f /dashboards/grafanadashboard-$env.json ]; then
            cp /var/lib/jmxtrans/influxdb.json.tmpl "/var/lib/jmxtrans/influxdb-$env.json"
            cp /dashboards/grafanadashboard.json.tmpl "/dashboards/grafanadashboard-$env.json"
        fi
        set_conf $key $value $env
    fi

    if [[ $key == INFLUXDB* ]]; then
        set_conf $key $value "*"
    fi

done

sleep 5
curl -s -XGET 'http://admin:admin@172.18.0.1:3000/api/datasources' --header "Content-Type: application/json"
[ $? ] && curl -s -XPOST 'http://admin:admin@172.18.0.1:3000/api/datasources' --header 'Content-Type: application/json' --data '{"Name":"influx","type":"influxdb","url":"http://172.18.0.1:8086","access":"direct","isDefault":true,"database":"influx","user":    "root","password":"root"}'

for dashboard in $(ls /dashboards/*.json); do
   curl -s -XPOST 'http://admin:admin@172.18.0.1:3000/api/dashboards/db' -H 'Content-Type: application/json; charset=utf-8' -H 'Accept: application/json' --data-binary @"$dashboard"
done

chown -R jmxtrans "$JMXTRANS_HOME"

EXEC="-jar $JAR_FILE -e -j $JSON_DIR -s $SECONDS_BETWEEN_RUNS -c $CONTINUE_ON_ERROR $ADDITIONAL_JARS_OPTS"
GC_OPTS="-Xms${HEAP_SIZE}m -Xmx${HEAP_SIZE}m -XX:PermSize=${PERM_SIZE}m -XX:MaxPermSize=${MAX_PERM_SIZE}m"
JMXTRANS_OPTS="$JMXTRANS_OPTS -Dlog4j.configuration=file:///${JMXTRANS_HOME}/conf/log4j.xml"

MONITOR_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.ssl=false \
    -Dcom.sun.management.jmxremote.authenticate=false \
    -Dcom.sun.management.jmxremote.port=9999 \
    -Dcom.sun.management.jmxremote.rmi.port=9999 \
    -Djava.rmi.server.hostname=${PROXY_HOST}"

if [ "$1" = 'start-without-jmx' ]; then
    set -- gosu jmxtrans tini -- java -server $JAVA_OPTS $JMXTRANS_OPTS $GC_OPTS $EXEC
elif [ "$1" = 'start-with-jmx' ]; then
    set -- gosu jmxtrans tini -- java -server $JAVA_OPTS $JMXTRANS_OPTS $GC_OPTS $MONITOR_OPTS $EXEC
fi

exec "$@"
