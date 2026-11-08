# MuchToDo Backend Deployment Assessment

## Project Overview

This project provisions AWS infrastructure using Terraform and deploys the MuchToDo Golang backend API using Docker.

The infrastructure is deployed in the AWS Europe (Ireland) region (`eu-west-1`).

### Architecture

The deployment consists of:

- **VPC:** A custom VPC with CIDR `10.0.0.0/16`.
- **Public subnets:** Two public subnets across two Availability Zones.
- **Private subnets:** Two private subnets across two Availability Zones.
- **Internet Gateway:** Provides internet connectivity to public resources.
- **NAT Gateway:** Provides outbound internet access to private resources.
- **Application Load Balancer:** Distributes HTTP traffic to the backend.
- **Bastion Host:** Provides secure SSH access to private instances.
- **Backend EC2:** Runs the MuchToDo API in a Docker container.
- **MongoDB EC2:** Runs MongoDB as a separate service.

The backend communicates with MongoDB over the private network.

## Project Structure

```text
backend-deployment-assessment/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── user_data/
│       ├── backend_setup.sh
│       └── mongodb_setup.sh
├── app/
├── evidence/
├── Dockerfile
├── docker-compose.yml
├── docker-compose.aws.yml
├── .dockerignore
├── .gitignore
└── README.md
```

## Prerequisites

Install or configure the following:

- AWS CLI
- Terraform
- Docker Desktop
- Docker Compose
- Git
- An AWS account with the required permissions
- An SSH key pair for EC2 access

## 1. Configure AWS CLI

Configure your AWS credentials using the AWS CLI:

```bash
aws configure --profile terraform-learning
```

Set the AWS profile:

```bash
export AWS_PROFILE=terraform-learning
```

Verify the AWS identity:

```bash
aws sts get-caller-identity
```

## 2. Configure Terraform

Navigate to the Terraform directory:

```bash
cd terraform
```

Create your local variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Update `terraform.tfvars` with your own configuration values. Do not commit this file or expose AWS credentials.

Initialize Terraform:

```bash
terraform init
```

Format and validate the configuration:

```bash
terraform fmt
terraform validate
```

Review the infrastructure plan:

```bash
terraform plan
```

Provision the infrastructure:

```bash
terraform apply
```

Confirm the deployment when prompted.

View the infrastructure outputs:

```bash
terraform output
```

## 3. Build the Docker Image

Return to the project root:

```bash
cd ..
```

Build the backend image for the EC2 architecture:

```bash
docker build --platform linux/amd64 -t muchtodo-backend:latest .
```

Save the Docker image:

```bash
docker save muchtodo-backend:latest -o muchtodo-backend.tar
```

The image archive is transferred to the private backend EC2 instance during deployment.

## 4. Local Docker Compose Deployment

Create a local `.env` file containing the required application environment variables.

Do not commit `.env` to GitHub.

Start the backend and MongoDB services:

```bash
docker compose up -d --build
```

Check the running containers:

```bash
docker compose ps
```

Check the backend health endpoint:

```bash
curl http://localhost:8080/health
```

Stop the local containers:

```bash
docker compose down
```

The MongoDB data volume is retained unless explicitly removed.

## 5. Deploy to AWS EC2

The backend Docker image is transferred to the private Backend EC2 instance through the Bastion Host.

SSH access to the backend uses the Bastion Host as a jump server.

Example SSH command:

```bash
ssh -A -i startuptech-key.pem \
-o ProxyCommand="ssh -A -i startuptech-key.pem -W %h:%p ec2-user@BASTION_PUBLIC_IP" \
ec2-user@BACKEND_PRIVATE_IP
```

After connecting to the backend instance:

Load the transferred Docker image:

```bash
docker load -i muchtodo-backend.tar
```

Create the required environment configuration on the backend instance. Supply the MongoDB private connection URI and application secret securely.

Start the backend container:

```bash
sudo /usr/local/bin/docker-compose -f docker-compose.aws.yml up -d
```

Verify the container:

```bash
sudo /usr/local/bin/docker-compose -f docker-compose.aws.yml ps
```

Check the application health:

```bash
curl http://localhost:8080/health
```

### MongoDB Configuration

MongoDB runs as a separate service on its own private EC2 instance.

The MongoDB security group permits database traffic on port `27017` from the Backend security group only.

The backend connects to MongoDB using the private MongoDB address supplied through `MONGO_URI`.

## 6. Verify the Application Through the Load Balancer

Retrieve the ALB DNS name:

```bash
cd terraform
terraform output
```

Test the health endpoint:

```bash
curl -i http://YOUR_ALB_DNS_NAME/health
```

A successful response should return HTTP `200 OK` and a response indicating that the database is available.

## 7. Security Considerations

- Backend and MongoDB instances are deployed in private subnets.
- SSH access to the backend is through the Bastion Host.
- The backend security group permits HTTP traffic on port `8080` from the ALB security group.
- MongoDB traffic is restricted to the Backend security group.
- AWS credentials, `.env`, private SSH keys, and Terraform variable files are excluded from Git.
- Terraform state files are kept out of the public repository.

## 8. Cleanup and Resource Destruction

AWS resources can incur charges while they remain active, particularly NAT Gateways, load balancers, EC2 instances, and storage resources.

When the assessment is complete and the deployment is no longer required, destroy the infrastructure:

```bash
cd terraform
terraform destroy
```

Review the resources before confirming destruction.

Also check the AWS Console to confirm that chargeable resources have been removed.

## 9. Evidence

The `evidence/` directory contains screenshots documenting:

- Terraform initialization and planning.
- Terraform infrastructure provisioning.
- VPC and subnet configuration.
- Security groups and EC2 instances.
- Load balancer configuration.
- Docker image build and local Compose deployment.
- Backend health checks.
- SSH access through the Bastion Host.
- Docker deployment on EC2.
- Successful backend access through the Application Load Balancer.

---

**Project:** MuchToDo Backend Deployment Assessment  
**Tools:** AWS, Terraform, Docker, Docker Compose, Golang, MongoDB  
**AWS Region:** eu-west-1
