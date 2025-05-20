#!/bin/bash

# Define variables
AMI_ID="ami-09c813fb71547fc4f"                  # e.g., ami-0abcdef1234567890
INSTANCE_TYPE="t2.micro"
KEY_NAME=""              # e.g., my-key-pair
SECURITY_GROUP_ID="sg-052b2eb75308383d4"  # e.g., sg-0123456789abcdef0
SUBNET_ID="subnet-0f73a6b273a171a27"      # e.g., subnet-0abcdef1234567890
HOSTED_ZONE_ID="Z07069691890X06YTPXD4" # e.g., Z0123456ABCDEFGH

DOMAIN_NAME="harshavn24.site"   # e.g., example.com

# ENTER YOUR CUSTOM SERVER NAMES HERE
SERVER_NAMES=("mongo" "catlog" "redis" "rabittmq" "mysql" "cart" "user" "cart" "dispatch" "payment" "frontend")

# Loop through your server names
for NAME in "${SERVER_NAMES[@]}"; do
  echo "Creating instance for $NAME..."

  # Launch EC2 instance
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --subnet-id "$SUBNET_ID" \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

  echo "Waiting for $NAME to start..."
  aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

  # Get public IP
  PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

  echo "$NAME public IP: $PUBLIC_IP"

  # Create Route 53 DNS record
  cat > "${NAME}_dns.json" <<EOF
{
  "Comment": "Creating A record for $NAME",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$NAME.$DOMAIN_NAME",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{
        "Value": "$PUBLIC_IP"
      }]
    }
  }]
}
EOF

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch "file://${NAME}_dns.json"

  echo "DNS A record created for $NAME => $NAME.$DOMAIN_NAME"
done