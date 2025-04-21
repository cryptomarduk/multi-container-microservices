# Multi-Container Microservices Project

A comprehensive DevOps-focused demonstration project featuring microservices architecture with Docker containers, advanced CI/CD pipeline integration, and modern monitoring solutions.

## Architecture Overview

![Architecture Diagram](architecture-diagram.png)

This project implements a robust microservices architecture with:

- **Python Flask API**: Backend service for data processing and analysis
- **Node.js Express API**: Frontend service providing RESTful endpoints
- **MongoDB**: NoSQL database for persistent data storage
- **Redis**: In-memory cache for performance optimization
- **Nginx**: Load balancer and reverse proxy
- **Prometheus & Grafana**: For comprehensive monitoring and observability

## Key Features

- **Containerized Microservices**: Each component runs in its own Docker container
- **Service Communication**: Inter-service communication with RESTful APIs
- **Database Integration**: MongoDB for persistent storage with Redis caching
- **Load Balancing**: Nginx configuration with reverse proxy and rate limiting
- **Monitoring Stack**: Prometheus metrics collection with Grafana dashboards
- **CI/CD Pipeline**: Automated testing, building, and deployment with GitHub Actions
- **Docker Compose**: Development and production environment configurations
- **Infrastructure as Code**: Ready for cloud deployment

## Technology Stack

- **Containerization**: Docker, Docker Compose
- **Languages**: Python (Flask), JavaScript (Node.js/Express)
- **Databases**: MongoDB, Redis
- **Web Server**: Nginx
- **Monitoring**: Prometheus, Grafana
- **CI/CD**: GitHub Actions
- **Security**: Container scanning, secret management, environment isolation

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Git
- (Optional) GitHub account for CI/CD pipeline

### Local Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/multi-container-microservices.git
   cd multi-container-microservices
   ```

2. Start the development environment:
   ```bash
   docker-compose up -d
   ```

3. Access the services:
   - Python API: http://localhost:5000
   - Node.js API: http://localhost:3000
   - Nginx (combined APIs): http://localhost:80
   - Grafana Dashboards: http://localhost:3001 (admin/admin)
   - Prometheus: http://localhost:9090

### Running Tests

```bash
# Python service tests
docker-compose exec python-service pytest

# Node.js service tests
docker-compose exec node-service npm test

# Run all tests with the testing script
./scripts/run_tests.sh
```

## CI/CD Pipeline

This project includes a comprehensive CI/CD pipeline using GitHub Actions:

### CI Pipeline (Runs on Pull Requests)
- Linting and static code analysis
- Unit and integration tests for all services
- Docker image building and testing
- Security scanning with Trivy
- Integration testing of services

### CD Pipeline (Runs on Merge to Main)
- Automated Docker image building
- Image tagging with semantic versioning
- Publishing to Docker Hub registry
- Deployment to staging environment
- Smoke tests
- Manual approval gate for production deployment
- Deployment to production environment

## Deployment

### Using the Deploy Script

The project includes a deployment script that handles:
- Environment detection (development, staging, production)
- Container health checks
- Graceful updates

```bash
# Deploy to development environment
./scripts/deploy.sh

# Deploy to staging environment
ENVIRONMENT=staging ./scripts/deploy.sh

# Deploy to production environment  
ENVIRONMENT=production ./scripts/deploy.sh
```

### Docker Swarm Deployment

For production environments, the project supports Docker Swarm:

```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.prod.yml microservices-stack
```

## Monitoring

The project includes a comprehensive monitoring stack:

- **Prometheus**: Collects metrics from all services
- **Grafana**: Visualizes metrics with pre-configured dashboards for:
  - Request rates and response times
  - Error rates
  - CPU and memory usage
  - Database performance

Default Grafana login: admin/admin

## Project Structure

```
├── .github/workflows/    # CI/CD pipeline definitions
├── python-service/       # Python Flask API service
├── node-service/         # Node.js Express API service 
├── nginx/                # Load balancer and reverse proxy
├── monitoring/           # Prometheus and Grafana configs
├── scripts/              # Utility scripts for deployment
├── docker-compose.yml    # Development environment
└── docker-compose.prod.yml # Production environment
```

## Security Considerations

- Multi-stage Docker builds for minimal attack surface
- Container vulnerability scanning in CI pipeline
- Environment-specific configuration
- No hard-coded secrets (environment variables used)
- Principle of least privilege in container configurations
- Rate limiting on API endpoints

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
