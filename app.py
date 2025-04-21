#!/usr/bin/env python3
from flask import Flask, jsonify, request
from pymongo import MongoClient
import redis
import os
import json
import time
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

# Flask Application
app = Flask(__name__)

# Environment variables
mongo_uri = os.environ.get('MONGO_URI', 'mongodb://localhost:27017/microservices')
redis_host = os.environ.get('REDIS_HOST', 'localhost')
redis_port = int(os.environ.get('REDIS_PORT', 6379))

# Database connections
mongo_client = MongoClient(mongo_uri)
mongo_db = mongo_client.get_database()
redis_client = redis.Redis(host=redis_host, port=redis_port, decode_responses=True)

# Prometheus metrics
REQUEST_COUNT = Counter('python_request_count', 'App Request Count', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('python_request_latency_seconds', 'Request latency in seconds', ['method', 'endpoint'])

@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    request_latency = time.time() - request.start_time
    REQUEST_LATENCY.labels(request.method, request.path).observe(request_latency)
    REQUEST_COUNT.labels(request.method, request.path, response.status_code).inc()
    return response

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for the service."""
    health_status = {
        'status': 'healthy',
        'services': {
            'mongo': check_mongo_connection(),
            'redis': check_redis_connection()
        }
    }
    return jsonify(health_status)

def check_mongo_connection():
    """Check MongoDB connection."""
    try:
        mongo_db.command('ping')
        return 'connected'
    except Exception:
        return 'disconnected'

def check_redis_connection():
    """Check Redis connection."""
    try:
        redis_client.ping()
        return 'connected'
    except Exception:
        return 'disconnected'

@app.route('/metrics', methods=['GET'])
def metrics():
    """Prometheus metrics endpoint."""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/', methods=['GET'])
def index():
    """Root endpoint."""
    return jsonify({'message': 'Welcome to Python Microservice API!'})

@app.route('/api/data', methods=['GET'])
def get_data():
    """Get data from MongoDB with Redis caching."""
    cache_key = 'api_data'
    
    # Try to get data from cache
    cached_data = redis_client.get(cache_key)
    if cached_data:
        app.logger.info('Data retrieved from cache')
        return jsonify(json.loads(cached_data))
    
    # If not in cache, get from MongoDB
    data = list(mongo_db.data.find({}, {'_id': 0}))
    
    # Store in cache for 60 seconds
    redis_client.setex(cache_key, 60, json.dumps(data))
    app.logger.info('Data retrieved from MongoDB and stored in cache')
    
    return jsonify(data)

@app.route('/api/data', methods=['POST'])
def add_data():
    """Add data to MongoDB."""
    data = request.json
    if not data:
        return jsonify({'error': 'No data provided'}), 400
    
    # Insert data into MongoDB
    result = mongo_db.data.insert_one(data)
    
    # Invalidate cache
    redis_client.delete('api_data')
    
    return jsonify({'message': 'Data added successfully', 'id': str(result.inserted_id)}), 201

@app.route('/api/process', methods=['POST'])
def process_data():
    """Process data with a Python-specific algorithm."""
    data = request.json
    if not data or 'values' not in data:
        return jsonify({'error': 'No data provided or invalid format'}), 400
    
    # Simple processing example (could be more complex in real application)
    values = data['values']
    result = {
        'sum': sum(values),
        'avg': sum(values) / len(values) if values else 0,
        'min': min(values) if values else None,
        'max': max(values) if values else None,
        'processed_at': time.time()
    }
    
    return jsonify(result)

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def server_error(error):
    """Handle 500 errors."""
    app.logger.error(f'Internal error: {error}')
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=os.environ.get('FLASK_ENV') == 'development')
