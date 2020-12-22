#!/bin/bash

timedatectl set-timezone Asia/Seoul

amazon-linux-extras install nginx1

systemctl start nginx
systemctl enable nginx

chmod 775 /var/log/nginx

yum install -y aws-kinesis-agent
if [[ $? -eq 0 ]];then
    cat <<EOF > /etc/aws-kinesis/agent.json
    {
    "cloudwatch.emitMetrics": true,
    "kinesis.endpoint": "kinesis.ap-northeast-2.amazonaws.com",
    "firehose.endpoint": "",
    
    "flows": [
        {
        "filePattern": "/var/log/nginx/access.log",
        "kinesisStream": "nginx-access-logs"
        }
    ]
    }
EOF
    systemctl start aws-kinesis-agent
    systemctl enable aws-kinesis-agent    
else
    echo "aws-kinesis-agent install failed"
fi