# syntax=docker/dockerfile:1@sha256:865e5dd094beca432e8c0a1d5e1c465db5f998dca4e439981029b3b81fb39ed5

FROM node:22-bullseye-slim@sha256:01e6d7155cfe9567294142e456da98864df32fd51e7d64ea04c1287b3fdc4bc5

WORKDIR /app

# Install dependencies
RUN npm install @security-alert/sarif-to-issue@1.10.10

RUN apt-get update && apt-get install --no-install-recommends -y jq=1.6-2.1 && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh ./entrypoint.sh

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
