# syntax=docker/dockerfile:1@sha256:dabfc0969b935b2080555ace70ee69a5261af8a8f1b4df97b9e7fbcf6722eddf

FROM node:22-bookworm-slim@sha256:4f77a690f2f8946ab16fe1e791a3ac0667ae1c3575c3e4d0d4589e9ed5bfaf3d

WORKDIR /app

# Install dependencies
RUN npm install @security-alert/sarif-to-issue@1.11.1

RUN apt-get update && apt-get install --no-install-recommends -y jq=1.6-2.1+deb12u1 && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh ./entrypoint.sh

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
