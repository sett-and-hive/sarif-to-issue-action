# syntax=docker/dockerfile:1@sha256:9857836c9ee4268391bb5b09f9f157f3c91bb15821bb77969642813b0d00518d

FROM node:22-bullseye-slim@sha256:741a60f76e79ab4080ebb10d24ec0c2aa4527fc44e33a8d609c416cc351b4fff

WORKDIR /app

# Install dependencies
RUN npm install @security-alert/sarif-to-issue@1.10.10

RUN apt-get update && apt-get install --no-install-recommends -y jq=1.6-2.1 && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh ./entrypoint.sh

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
