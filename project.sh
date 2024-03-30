#!/bin/bash

vpc_name="vpc-group-4"
vpc_cidr_block="10.0.0.0/16"
region="us-east-2"
security_group_name="group-4-sg"
inbound_ports=(22 80 443)
subnet_cidr_blocks=("10.0.1.0/24" "10.0.2.0/24" "10.0.3.0/24")
azs=("us-east-2a" "us-east-2b" "us-east-2c")
ami_image_id="ami-019f9b3318b7155c5"

# 1. VPC named "vpc-group-4" with CIDR block 10.0.0.0/16 	
# Create a VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr_block --region $region --query Vpc.VpcId --output text)

# Created a tag to give the VPC a name
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=$vpc_name

# 2. Security group named "sg-group-4"  --> AWS naming convention prevents us from creating a SG that starts with "sg-". Changing the name to "group-4-sg"

sg=$(aws ec2 create-security-group --group-name $security_group_name --description "Allows inbound traffic on ports 22, 80, 443" --vpc-id $vpc_id --region $region --query GroupId --output text)

# 3. Open inbound ports 22, 80, 443 for everything in security group "sg-group-4" 

# Since we have ports array defined above, we can iterate through it and perform the action needed

for port in "${inbound_ports[@]}"
do
   aws ec2 authorize-security-group-ingress --group-id $sg --protocol tcp --port $port --cidr 0.0.0.0/0 --region $region
done

# 4. Create 3 public subnets: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24 in each availability zones respectively (us-east-2a, us-east-2b, us-east-2c) 

# Since we have subnet CIDR ranges array and AZs array defined above, we can iterate through them in parallel, accessing indeces of the arrays rather than values. For that, "!" is defined on the first line of the loop

subnet_id=""

for i in "${!subnet_cidr_blocks[@]}"
do
  cidr_block="${subnet_cidr_blocks[$i]}"
  az="${azs[$i]}"
  subnet_id=$(aws ec2 create-subnet --cidr-block "$cidr_block" --availability-zone "$az" --vpc-id "$vpc_id" --query Subnet.SubnetId --output text)
done

# 5. Create Internet Gateway 

igw_id=$(aws ec2 create-internet-gateway --region $region --query InternetGateway.InternetGatewayId --output text)

# 6. Attach Internet Gateway to VPC "vpc-group-4" 	

aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id --region $region

# 7. Create EC2 Instance named "ec2-group-4" with security group "sg-group-4". Since the task does not specify the subnet where we need to create an ec2 instance,
# this can be done either in default subnet, or we need to provide subnet id. Since I deleted my default subnet, I need to provide subnet id. I am using subnet id of 
# "us-east-2c" AZ and CIDR block "10.0.3.0/24".

aws ec2 run-instances  --tag-specifications  'ResourceType=instance,Tags=[{Key=Name,Value=ec2-group-4}]' --image-id $ami_image_id --count 1 --instance-type t2.micro --security-group-ids $sg --subnet-id $subnet_id
