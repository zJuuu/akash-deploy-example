FROM ghcr.io/akash-network/provider:0.6.4

RUN apt-get update && apt-get install -y curl jq

WORKDIR /akash-deployment

ARG AKASH_ACCOUNT_ADDRESS
ENV AKASH_ACCOUNT_ADDRESS=${AKASH_ACCOUNT_ADDRESS}

COPY deploy.yml .
COPY ${AKASH_ACCOUNT_ADDRESS}.pem /root/.akash/

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

