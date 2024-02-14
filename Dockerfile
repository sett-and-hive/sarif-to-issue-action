# syntax=docker/dockerfile:1@sha256:ac85f380a63b13dfcefa89046420e1781752bab202122f8f50032edf31be0021

FROM node:21-bullseye-slim@sha256:b64d3ff72c327bc8184d7a6d85ed189901a407891340e4693a246f34eb2993aa

WORKDIR /app

# Install dependencies
RUN npm install @security-alert/sarif-to-issue@1.10.10

RUN apt-get update && apt-get install --no-install-recommends -y jq=1.6-2.1 && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh ./entrypoint.sh

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
