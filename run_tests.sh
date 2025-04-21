#!/bin/bash
set -e

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

# Check if Docker Compose is running
if ! docker-compose ps | grep -q "Up"; then
  log_error "Docker Compose services are not running. Please start them with 'docker-compose up -d'"
  exit 1
fi

# Run Python service tests
log_info "Running Python service tests..."
docker-compose exec -T python-service pytest --cov=. --cov-report=term
if [ $? -ne 0 ]; then
  log_error "Python service tests failed!"
  exit 1
fi
log_info "Python service tests completed successfully"

# Run Node.js service tests
log_info "Running Node.js service tests..."
docker-compose exec -T node-service npm test
if [ $? -ne 0 ]; then
  log_error "Node.js service tests failed!"
  exit 1
fi
log_info "Node.js service tests completed successfully"

# Run integration tests
log_info "Running integration tests..."
docker-compose ps | grep -q "nginx-proxy.*Up" || {
  log_error "Nginx service is not running!"
  exit 1
}

# Test Nginx endpoint
curl -s -o /dev/null -w "%{http_code}" http://localhost/health | grep -q "200" || {
  log_error "Nginx health check failed!"
  exit 1
}
log_info "Nginx health check passed"

# Test Python API endpoint
curl -s -o /dev/null -w "%{http_code}" http://localhost/api/python/ | grep -q "200" || {
  log_error "Python API check failed!"
  exit 1
}
log_info "Python API check passed"

# Test Node.js API endpoint
curl -s -o /dev/null -w "%{http_code}" http://localhost/api/node/ | grep -q "200" || {
  log_error "Node.js API check failed!"
  exit 1
}
log_info "Node.js API check passed"

# Test data processing endpoint with actual data
log_info "Testing data processing integration..."
RESULT=$(curl -s -X POST -H "Content-Type: application/json" -d '{"values":[1,2,3,4,5]}' http://localhost/api/node/process-with-python)

# Check if the result contains expected fields
echo $RESULT | grep -q "sum" && echo $RESULT | grep -q "avg" || {
  log_error "Data processing integration test failed!"
  log_error "Response: $RESULT"
  exit 1
}
log_info "Data processing integration test passed"

log_info "All tests passed successfully!"
