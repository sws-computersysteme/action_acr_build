FROM mcr.microsoft.com/azure-cli

LABEL "repository"="https://github.com/sws-computersysteme/action_acr_build"
LABEL "maintainer"="Stefan Bess"

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]