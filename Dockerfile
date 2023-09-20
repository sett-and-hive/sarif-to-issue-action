# syntax=docker/dockerfile:1

FROM node:20-bullseye-slim@sha256:737d756b6f93734c6d4732576c6a82d5bc7c47f2c1643d6877736387a5455429

WORKDIR /app

# Install dependencies
RUN npm install @security-alert/sarif-to-issue@1.10.4

RUN apt-get update && apt-get install --no-install-recommends -y jq=1.6-2.1 && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh ./entrypoint.sh

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
