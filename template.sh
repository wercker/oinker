#!/bin/bash
cat > $APP_NAME.json <<EOF
[{
    "id": "/$APP_NAME",
    "instances": $INSTANCES,
    "container": {
        "type": "DOCKER",
        "docker": {
            "image": "$APP_IMAGE",
            "network": "BRIDGE",
            "forcePullImage": true,
            "portMappings": [
                {
                    "containerPort": $CONTAINER_PORT,
                    "hostPort": 0,
                    "servicePort": 10000,
                    "protocol": "tcp"
                }
            ]
        }
    },
    "healthChecks": [{
          "protocol": "HTTP",
          "portIndex": 0
    }],
     "labels":{
          "HAPROXY_GROUP":"external",
          "HAPROXY_0_VHOST":"$MESOS_DNS_HOST",
          "HAPROXY_0_PORT": "80"
    },
    "env":{
          "SECRET_KEY_BASE": "be6ea21bd0e8ddad06accbdfbfcbc6f120815744a8177fb1196442c1670401c86a1d020f1fb62f9b7d6bacc8cf818de277d23d3f3e7dcf704ca88965e5b9ed86",
          "CASSANDRA_HOSTS": "node-0.cassandra.mesos"
    },
    "cmd": "until bundle exec rake cassandra:setup; do sleep 5; done && rails server",
    "ports": [0],
    "cpus": 0.25,
    "mem": 256.0,
    "working-dir": "/rails"
}]
EOF
