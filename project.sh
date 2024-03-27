#!/bin/bash

vpc_name="vpc-group-4"
vpc_cidr_block="10.0.0.0/16"
region="us-east-2"

# 1. VPC named "vpc-group-4" with CIDR block 10.0.0.0/16 	
# Create a VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr_block --region $region --query Vpc.VpcId --output text)

# Created a tag to give the VPC a name
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=$vpc_name