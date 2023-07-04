# syntax=docker/dockerfile:1

FROM node:20-bullseye-slim@sha256:d634f3f7fd569adf841b8a8f73ad04a757ca7bbaf4b3c4c1163dcac3c064d3a5

WORKDIR /app

# Install dependencies
RUN npm install @security-alert/sarif-to-issue@1.10.4

RUN apt-get update && apt-get install --no-install-recommends -y jq=1.6-2.1 && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh ./entrypoint.sh

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
