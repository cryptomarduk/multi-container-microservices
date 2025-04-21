#!/bin/bash
set -e

# Deploy script for multi-container microservices project
# This script can be run manually or through the CI/CD pipeline

# Configuration - override these with environment variables
ENVIRONMENT=${ENVIRONMENT:-development}  # development, staging, production
DOCKER_COMPOSE_FILE=${DOCKER_COMPOSE_FILE:-"docker-compose.yml"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
  log_info "Checking dependencies..."
  
  # Check for Docker
  if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker and try again."
    exit 1
  fi
  
  # Check for Docker Compose
  if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
  fi
  
  log_info "All dependencies are installed."
}

check_docker_compose_file() {
  log_info "Checking Docker Compose file..."
  
  if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    log_error "Docker Compose file not found: $DOCKER_COMPOSE_FILE"
    exit 1
  fi
  
  log_info "Docker Compose file found: $DOCKER_COMPOSE_FILE"
}

set_environment_variables() {
  log_info "Setting environment variables for $ENVIRONMENT environment..."
  
  if [ "$ENVIRONMENT" = "production" ]; then
    export DOCKER_COMPOSE_FILE="docker-compose.prod.yml"
    export GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-"admin"}
    # Add other production-specific variables here
  elif [ "$ENVIRONMENT" = "staging" ]; then
    export DOCKER_COMPOSE_FILE="docker-compose.staging.yml"
    export GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-"admin"}
    # Add other staging-specific variables here
  else
    export DOCKER_COMPOSE_FILE="docker-compose.yml"
    # Add other development-specific variables here
  fi
  
  # Export the DockerHub username if available
  if [ -n "$DOCKERHUB_USERNAME" ]; then
    export DOCKERHUB_USERNAME
  fi
  
  log_info "Environment variables set for $ENVIRONMENT environment."
}

pull_latest_images() {
  log_info "Pulling latest Docker images..."
  
  if [ "$ENVIRONMENT" != "development" ]; then
    docker-compose -f "$DOCKER_COMPOSE_FILE" pull
    log_info "Latest Docker images pulled successfully."
  else
    log_info "Skipping pull in development environment."
  fi
}

deploy_services() {
  log_info "Deploying services to $ENVIRONMENT environment..."
  
  # Stop and remove existing containers
  docker-compose -f "$DOCKER_COMPOSE_FILE" down || true
  
  # Start services
  docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
  
  log_info "Services deployed successfully to $ENVIRONMENT environment."
}

check_service_health() {
  log_info "Checking service health..."
  
  # Wait for services to be healthy
  local max_retries=30
  local retry_interval=5
  local retry_count=0
  
  while [ $retry_count -lt $max_retries ]; do
    if docker-compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "(healthy)"; then
      log_info "All services are healthy."
      return 0
    fi
    
    log_warning "Waiting for services to be healthy... (${retry_count}/${max_retries})"
    sleep $retry_interval
    retry_count=$((retry_count + 1))
  done
  
  log_error "Services did not become healthy within the timeout period."
  docker-compose -f "$DOCKER_COMPOSE_FILE" ps
  return 1
}

# Main script execution
main() {
  log_info "Starting deployment for $ENVIRONMENT environment..."
  
  check_dependencies
  set_environment_variables
  check_docker_compose_file
  pull_latest_images
  deploy_services
  check_service_health
  
  log_info "Deployment completed successfully!"
}

# Execute main function
main
