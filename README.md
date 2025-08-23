# automate-opencart

This project is aimed at building a **Docker image for OpenCart** and deploying it to an **AWS EKS (Elastic Kubernetes Service) cluster** using Terraform and Kubernetes manifests.

## Project Overview
- Build a custom **Docker image** for OpenCart (PHP + Apache).
- Deploy OpenCart and MySQL as **Kubernetes deployments**.
- Expose OpenCart using a **LoadBalancer service** on AWS.
- Use Terraform to provision the **VPC, EKS cluster, and node groups**.

## Project Structure
- **Dockerfile** → Defines the OpenCart container image.
- **terraform/** → Contains Terraform code to create AWS VPC, EKS, and networking.

## Usage
1. **The github workflow build and publish the image on push**  
1. **Use teraform to deploy the app on EKS**  
