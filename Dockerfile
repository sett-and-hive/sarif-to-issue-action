# syntax=docker/dockerfile:1@sha256:a57df69d0ea827fb7266491f2813635de6f17269be881f696fbfdf2d83dda33e

FROM node:21-bullseye-slim@sha256:788417c15fd7e0fde36a592e70c06fdb9b0a553733ad036e118ece9950d0d35e

WORKDIR /app

# Install dependencies
RUN npm install @security-alert/sarif-to-issue@1.10.10

RUN apt-get update && apt-get install --no-install-recommends -y jq=1.6-2.1 && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh ./entrypoint.sh

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
