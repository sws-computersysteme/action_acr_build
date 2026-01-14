# ACP Github Code zu Dockerimage im Azure Repository

Buildet und pusht ein Docker-Image direkt in eine **Azure Container Registry (ACR)** – einfach und automatisiert mit GitHub Actions!

## Features

- Login bei Azure per Service Principal
- Build eines Docker-Images aus einem GitHub-Repository
- Push des Images direkt in eine ACR
- Unterstützt private Git-Repositories über GitHub Access Token
- Automatische Nutzung der `.node-version`-Datei für Build-Argumente
- Flexible Build-Argumente über JSON

## Inputs

| Name | Beschreibung | Erforderlich | Standardwert |
|:-----|:--------------|:-------------|:-------------|
| `service_principal` | Service Principal mit Contributor-Rechten auf der ACR | ✅ | - |
| `service_principal_password` | Passwort des Service Principals | ✅ | - |
| `tenant` | Azure Tenant ID | ✅ | - |
| `registry` | Name der ACR (ohne `.azurecr.io`) | ✅ | - |
| `repository` | Name des Repositorys (wird sonst automatisch erkannt) | ❌ | aktuelles Repo |
| `git_access_token` | GitHub Access Token (optional - nutzt lokalen Checkout wenn nicht angegeben) | ❌ | - |
| `image` | Docker-Image-Name | ❌ | leer |
| `tag` | Docker-Tag (Standard: Commit SHA) | ❌ | aktueller Git-Ref |
| `branch` | Branch, aus dem gebaut wird | ❌ | `master` |
| `folder` | Ordner im Repository mit dem Docker-Quellcode | ✅ | - |
| `dockerfile` | Pfad zur `Dockerfile` | ❌ | `./Dockerfile` |
| `build_args` | Build-Argumente als JSON | ❌ | - |

## Outputs

| Name | Beschreibung |
|:-----|:-------------|
| `ci_repository_name` | Repository-Name ohne Owner |
| `ci_action_ref_name` | Branch oder Tag-Name, der den Workflow ausgelöst hat |
| `node_version` | Aus `.node-version` gelesene Node.js-Version |

## Beispiel-Verwendung

```yaml
jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Azure Build and Push
        uses: sws-computersysteme/action_acr_build@v1
        with:
          service_principal: ${{ secrets.AZURE_SP_USERNAME }}
          service_principal_password: ${{ secrets.AZURE_SP_PASSWORD }}
          tenant: ${{ secrets.AZURE_TENANT }}
          registry: myregistry
          git_access_token: ${{ secrets.GIT_ACCESS_TOKEN }}
          folder: src
          image: my-app
          tag: latest
```

MIT License © 2025 Stefan Bess