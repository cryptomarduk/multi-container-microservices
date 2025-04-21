# Multi-Container Microservices Project

This repository demonstrates a DevOps-focused microservices architecture using Docker containers, Docker Compose, and CI/CD pipeline integration. The project showcases key skills relevant for a DevOps Engineer position.

## Architecture Overview

This project implements a microservices architecture with:

- **Python Flask API**: Backend service for data processing
- **Node.js Express API**: Frontend service with REST endpoints
- **MongoDB**: NoSQL database for persistent storage
- **Redis**: In-memory cache for performance optimization
- **Nginx**: Load balancer and reverse proxy
- **Prometheus & Grafana**: For monitoring and observability

## Technology Stack

- **Containerization**: Docker, Docker Compose
- **Languages**: Python, JavaScript (Node.js)
- **Databases**: MongoDB, Redis
- **Web Server**: Nginx
- **Monitoring**: Prometheus, Grafana
- **CI/CD**: GitHub Actions
- **Security**: Container scanning, secret management

## Project Structure

```
├── .github/
│   └── workflows/
│       ├── ci-pipeline.yml
│       └── cd-pipeline.yml
├── python-service/
│   ├── Dockerfile
│   ├── app.py
│   ├── requirements.txt
│   └── tests/
├── node-service/
│   ├── Dockerfile
│   ├── server.js
│   ├── package.json
│   └── tests/
├── nginx/
│   ├── Dockerfile
│   └── nginx.conf
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml
│   └── grafana/
│       └── dashboards/
├── scripts/
│   ├── deploy.sh
│   └── healthcheck.sh
├── docker-compose.yml
├── docker-compose.prod.yml
└── README.md
```

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Git
- GitHub account (for CI/CD)

### Local Development

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
   - Grafana Dashboards: http://localhost:3001

### Running Tests

```bash
docker-compose run python-service pytest
docker-compose run node-service npm test
```

## CI/CD Pipeline

This project uses GitHub Actions for continuous integration and deployment:

1. **CI Pipeline**: Triggered on pull requests to main branch
   - Runs unit and integration tests
   - Performs static code analysis
   - Scans Docker images for vulnerabilities
   - Builds Docker images

2. **CD Pipeline**: Triggered on push to main branch
   - Builds and tags Docker images
   - Pushes images to Docker Hub
   - Deploys to staging environment
   - Runs smoke tests
   - (Optional) Deploys to production with approval

## Monitoring and Observability

The project includes a comprehensive monitoring stack:

- **Prometheus**: Collects metrics from all services
- **Grafana**: Visualizes metrics with pre-configured dashboards
- **Log Aggregation**: Centralized logging with ELK stack (optional extension)

## Security Features

- Multi-stage Docker builds for smaller image footprint
- Container security scanning in CI pipeline
- Proper secret management using environment variables
- Principle of least privilege in container configurations

## Extending the Project

### Adding New Services

1. Create a directory for your service
2. Add Dockerfile and required code
3. Update docker-compose.yml to include your service
4. Update Nginx configuration if needed
5. Add monitoring configuration

### Scaling with Docker Swarm (Future Extension)

Instructions for deploying the stack on Docker Swarm:

```bash
docker stack deploy -c docker-compose.prod.yml microservices-stack
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
