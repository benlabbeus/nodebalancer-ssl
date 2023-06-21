#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

NODE_BALANCER_ID=$1
CONFIG_ID=$2
PRIVATE_KEY_PATH=$3
CERTIFICATE_PATH=$4
API_TOKEN=$5
NAME=$6
SCRIPT_PATH="/usr/local/bin/${NAME}.sh"
SERVICE_PATH="/etc/systemd/system/${NAME}.service"
TIMER_PATH="/etc/systemd/system/${NAME}.timer"

cat << EOF > $SCRIPT_PATH
#!/bin/bash
PRIVATE_KEY=\$(awk 'NF {sub(/\\n/, "\\\\n"); printf "%s\\\\n",\$0;}' $PRIVATE_KEY_PATH)
CERTIFICATE=\$(awk 'NF {sub(/\\n/, "\\\\n"); printf "%s\\\\n",\$0;}' $CERTIFICATE_PATH)

echo "Private Key:"
echo "\$PRIVATE_KEY"

echo "Certificate:"
echo "\$CERTIFICATE"

curl -H "Authorization: Bearer $API_TOKEN" \
     -H "Content-Type: application/json" \
     -X PUT \
     -d '{
        "protocol": "https",
        "ssl_cert": "'"\$CERTIFICATE"'",
        "ssl_key": "'"\$PRIVATE_KEY"'"
     }' \
     https://api.linode.com/v4/nodebalancers/$NODE_BALANCER_ID/configs/$CONFIG_ID
EOF

chmod +x $SCRIPT_PATH

cat << EOF > $SERVICE_PATH
[Unit]
Description=Update Linode Node Balancer

[Service]
ExecStart=$SCRIPT_PATH
User=root
EOF

cat << EOF > $TIMER_PATH
[Unit]
Description=Runs ${NAME} script every 12 hours

[Timer]
OnBootSec=15min
OnUnitActiveSec=12h

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable ${NAME}.timer
systemctl start ${NAME}.timer
systemctl start ${NAME}.service