#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-01ce89f25ab5c2e0b"

INSTANCES=(
  "mongodb"
  "redis"
  "mysql"
  "rabbitmq"
  "catalogue"
  "user"
  "cart"
  "shipping"
  "payment"
  "dispatch"
  "frontend"
)

ZONE_ID="Z0377755DD1CAPN8AAET"
DOMAIN_NAME="leardevops.online"

for instance in "${INSTANCES[@]}"
do

  echo "Creating instance: $instance"

  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[0].InstanceId" \
    --output text)

  echo "Instance ID: $INSTANCE_ID"

  # Wait until instance is running
  aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID"

  if [ "$instance" != "frontend" ]
  then

    IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PrivateIpAddress" \
      --output text)

  else

    IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text)

  fi

  echo "$instance IP address: $IP"

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch '{
      "Comment": "Creating record for '"$instance"'",
      "Changes": [
        {
          "Action": "UPSERT",
          "ResourceRecordSet": {
            "Name": "'"$instance"'.'"$DOMAIN_NAME"'",
            "Type": "A",
            "TTL": 1,
            "ResourceRecords": [
              {
                "Value": "'"$IP"'"
              }
            ]
          }
        }
      ]
    }'

done