FROM mcr.microsoft.com/azure-cli

LABEL "repository"="https://github.com/sws-computersysteme/action_acr_build"
LABEL "maintainer"="Stefan Bess"

RUN apt-get update && apt-get install -y git jq

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]