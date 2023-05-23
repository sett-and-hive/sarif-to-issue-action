# syntax=docker/dockerfile:1

FROM node:20-bullseye-slim@sha256:95a950ec61796f4c00f6b208cb51000b8bd127ee53b0c1c52f2539a5ab66f8ef

WORKDIR /app

# Install dependencies
RUN npm install @security-alert/sarif-to-issue@1.10.4

RUN apt-get update && apt-get install --no-install-recommends -y jq=1.6-2.1 && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh ./entrypoint.sh

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
