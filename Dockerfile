# syntax=docker/dockerfile:1

FROM node:18-bullseye-slim

WORKDIR /app

# Install dependencies
RUN npm install @security-alert/sarif-to-issue@1.10.4

RUN apt-get update && apt-get install --no-install-recommends -y jq=1.6-2.1 && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh ./entrypoint.sh

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
