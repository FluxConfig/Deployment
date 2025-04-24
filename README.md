# FluxConfig System deployment guidance

**This guide covers the deployment of all system services on a single device. To learn more about deploying each part separately, visit the corresponding guides :**

- [FluxConfig.Storage](https://github.com/FluxConfig/FluxConfig.Storage/blob/master/deployment/DEPLOY.md)
- [FluxConfig.Management](https://github.com/FluxConfig/FluxConfig.Management/blob/master/deployment/DEPLOY.md)
- [FluxConfig.WebClient](https://github.com/FluxConfig/FluxConfig.WebClient/blob/master/deployment/DEPLOY.md)

## Getting started

### 0. Prerequisites

**Docker and docker-compose installed on the system.**

**TLS certificate in .pfx format and password for .pfx file**

### 1. Download deployment script

```bash
curl -LJO https://raw.githubusercontent.com/FluxConfig/Deployment/refs/heads/master/fluxconfig.sh
```

### 2. Fill .cfg file as it shown in [template](https://github.com/FluxConfig/Deployment/blob/master/fluxconfig.template.cfg)

**You can create and fill it manually**

**Download and fill it manually**

```bash
curl -LJO https://raw.githubusercontent.com/FluxConfig/Deployment/refs/heads/master/fluxconfig.template.cfg
```

**Or let the script download it.**

```bash
./fluxconfig.sh -c "non-existing.cfg"
Fetching docker-compose.yml...
docker-compose.yml successfully downloaded

Config file not found. Do you want to download template file? y/n
y

Fetching fluxconfig.template.cfg...
fluxconfig.template.cfg successfully downloaded

Please fill the configuration file and run this script again.
```

### 2.1 .cfg arguments

| **Argument** | **Description**                                                                                                                                                                                                                                                               | **Example**                         |
|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------|
| **FC_TAG**         | Tag/version of the FluxConfig images which will be used <br> You can find all tags [here](https://hub.docker.com/u/fluxconfig)                                                                                                                 | 1.0-pre                             |
| **STORAGE_API_PORT**      | Port for FluxConfig.Storage api, which will be exposed from container                                                                                                                                                                                                                            | Any free port, e.g 7077             |
| **MANAGEMENT_API_PORT** | Port for FluxConfig.Management api, which will be exposed from container                                                                                                                                                                                                                              | Any free port, e.g 7070              |
| **FC_CLIENT_PORT** | Port for FluxConfig.WebClient , which will be exposed from container                                                                                                                                                                                                                           | Any free port, e.g 3000          |
| **EXTERNAL_CERT_PATH**      | Path to .pfx TLS cert from build directory, <br> which will be mounted to "/https/certs/" directory within container                                                                                                                                                          | ~/dev-certs/https/cert.pfx          |
| **INTERNAL_CERT_PATH**      | Path to .pfx TLS cert from within container, <br> "/https/certs/<path to .pfx from mounted dir>"                                                                                                                                                                              | /https/certs/cert.pfx               |
| **CERT_PSWD**         | Password for .pfx TLS certificate                                                                                                                                                                                                                                             | password                            |
| **FCM_SYSADMIN_EMAIL**   | Email of the account that will be granted system administrator rights during system initialization. Can be changed after installation                                                                                                                                           | admin@gmail.com                      |
| **FCM_SYSADMIN_USERNAME**  | Username of the account that will be granted system administrator rights during system initialization. Can be changed after installation                                                                                                                                        | FluxAdmin                            |
| **FCM_SYSADMIN_PASSWORD**   | Password of the account that will be granted system administrator rights during system initialization. Can be changed after installation                                                                                                                                        | 12345678                             |
| **PG_USER**             | Username for internal PostgreSQL connection, fill it or leave empy for auto generation                                                                                                                                                                                          | PgUser                               |
| **PG_PSWD**             | Password for internal PostgreSQL connection, fill it or leave empy for auto generation                                                                                                                                                                                          | PgPassword                           |
| **MONGO_USERNAME**         | Username for internal MongoDB connection, fill it or leave empy for auto generation                                                                                                                                                                                           | MongoUser                           |
| **MONGO_PASSWORD**         | Password for internal MongoDB connection, fill it or leave empy for auto generation                                                                                                                                                                                           | MongoPassword                       |

### 3. Execute deployment script

**Give executable permissions to the file**

```bash
chmod +x fluxconfig.sh
```

**Deploy**

```bash
./fluxconfig.sh -c "PATH TO YOUR .cfg FILE"
```
