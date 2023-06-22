# syntax=docker/dockerfile:1

FROM node:20-bullseye-slim@sha256:a70c22cb6ef7c6d809970b2889e5e556337fda8bfaa439b30c035efaef8fc3a1

WORKDIR /app

# Install dependencies
RUN npm install @security-alert/sarif-to-issue@1.10.4

RUN apt-get update && apt-get install --no-install-recommends -y jq=1.6-2.1 && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh ./entrypoint.sh

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
