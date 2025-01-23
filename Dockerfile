# syntax=docker/dockerfile:1@sha256:93bfd3b68c109427185cd78b4779fc82b484b0b7618e36d0f104d4d801e66d25

FROM node:22-bullseye-slim@sha256:8d01d258d1c400417c3ea058b10e6e0c93a605276aac84b3ec7cb0c08b8c5d33

WORKDIR /app

# Install dependencies
RUN npm install @security-alert/sarif-to-issue@1.10.10

RUN apt-get update && apt-get install --no-install-recommends -y jq=1.6-2.1 && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh ./entrypoint.sh

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
