# Akash CLI Deployment

This repository contains configuration and scripts for deploying applications to the Akash Network using Docker containers.

## Overview

This project provides a streamlined way to deploy applications to the Akash Network using Docker containers and CLI tools. It includes Docker configuration, deployment scripts, and necessary configuration files for seamless deployment.

## Prerequisites

- Docker and Docker Compose installed
- Akash CLI tools
- An Akash account with funded wallet
- Your Akash deployment certificate (`yourakashaddress.pem` file)

## Project Structure

```
.
├── .env                    # Environment variables
├── .gitignore             # Git ignore rules
├── Dockerfile             # Docker image configuration
├── docker-compose.yml     # Docker Compose configuration
├── deploy.yml             # Akash deployment configuration
└── entrypoint.sh         # Container entrypoint script
```

## Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/zJuuu/akash-deploy-example>
   cd akash-cli-deploy
   ```

2. Configure your environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. Set your Akash Address in the docker-compose.yml file

4. Place your Akash deployment certificate (`yourakashaddress.pem` file) in the project root.

## Usage

1. Build and start the containers:
   ```bash
   docker-compose up --build
   ```

2. It will automatically deploy the application to the Akash Network and close the deployment after 30 seconds.

## Deployment Configuration

The `deploy.yml` file contains the Akash deployment configuration. Modify this file to adjust:
- Container specifications
- Resource requirements
- Network configurations
- Storage requirements