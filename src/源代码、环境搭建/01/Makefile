.PHONY: help install test lint build run docker-build docker-up docker-down deploy rollback trace security

help:
	@echo "Available commands:"
	@echo "  make install      - Install dependencies"
	@echo "  make test         - Run tests"
	@echo "  make lint         - Run linter"
	@echo "  make build        - Build Docker image"
	@echo "  make run          - Run application locally"
	@echo "  make docker-build - Build Docker image"
	@echo "  make docker-up    - Start with Docker Compose"
	@echo "  make docker-down  - Stop Docker Compose"
	@echo "  make deploy       - Deploy to Kubernetes"
	@echo "  make rollback     - Rollback deployment"
	@echo "  make trace        - Trace version chain"
	@echo "  make security     - Run security scan"

install:
	npm install

test:
	npm test

lint:
	npm run lint

build:
	docker build -t cloud-native-demo:latest .

run:
	npm start

docker-build:
	docker build -t cloud-native-demo:latest .

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

deploy:
	@echo "Usage: make deploy IMAGE=cloud-native-demo:v1.0.0"
	@if [ -n "$(IMAGE)" ]; then \
		./scripts/deploy.sh deploy $(IMAGE); \
	fi

rollback:
	./scripts/deploy.sh rollback

trace:
	./scripts/trace.sh

security:
	./scripts/security-scan.sh
