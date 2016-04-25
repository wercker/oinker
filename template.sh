#!/bin/bash
cat > $APP_NAME.json <<EOF
{
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
		"cmd": "until rake cassandra:setup; do sleep 5; done && rails server",
    "ports": [0],
    "cpus": 0.25,
    "mem": 256.0,
		"working-dir": "/rails"
}
EOF
