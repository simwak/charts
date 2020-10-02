# Gitea Helm Chart

> :warning: This is a fork of https://gitea.com/gitea/helm-chart. This releases includes custom CA capability, OAuth configureation, PostgreSQL fullnameOverride support and corrected default storage class. Do not use this chart if do not need these features or if they are already implemented in the official chart. This chart does not increase the patch level nor should it be a long time solution to use.

[Gitea](https://gitea.io/en-us/) is a community managed lightweight code hosting solution written in Go. It is published under the MIT license.

Readme will be updated with examples in the next few days

## Introduction

This helm chart has taken some inspiration from https://github.com/jfelten/gitea-helm-chart
But takes a completly different approach in providing database and cache with dependencies.
Also this chart provides ldap and admin user configuration with values as well as it is deployed as statefulset to retain stored repositories.

## Dependencies

Gitea can be run with external database and cache. This chart provides those dependencies, which can be
enabled, or disabled via [configuration](#configuration).

Dependencies:

* Postgresql
* Memcached
* Mysql

## Installing

```
  helm repo add gitea-charts https://dl.gitea.io/charts/
  helm install gitea gitea-charts/gitea
```

## Prerequisites

* Kubernetes 1.12+
* Helm 3.0+
* PV provisioner for persistent data support

## Examples

### Gitea Configuration

Gitea offers lots of configuration. This is fully described in the [Gitea Cheat Sheet](https://docs.gitea.io/en-us/config-cheat-sheet/).

```yaml
  gitea:
    config:
      APP_NAME: "Gitea: With a cup of tea."
      repository:
        ROOT: "~/gitea-repositories"
      repository.pull-request:
        WORK_IN_PROGRESS_PREFIXES: "WIP:,[WIP]:"
```

### Ports and external url

By default port 3000 is used for web traffic and 22 for ssh. Those can be changed:

```yaml
  service:
    http: 
      port: 3000
    ssh:
      port: 22
```

This helmchart automatically configures the clone urls to use the correct ports. You can change these ports by hand using the gitea.config dict. However you should know what you're doing.

### Cache

This helm chart can use a built in cache. The default is memcached from bitnami.

```yaml
  gitea:
    cache:
      builtIn:
        enabled: true
```

If the built in cache should not be used simply configure the cache in gitea.config

```yaml
  gitea:
    config:
      cache:
        ENABLED: true
        ADAPTER: memory
        INTERVAL: 60
        HOST: 127.0.0.1:9090
```
### Persistence

Gitea will be deployed as a statefulset. By simply enabling the persistence and setting the storage class according to your cluster
everything else will be taken care of. The following example will create a PVC as a part of the statefulset. This PVC will not be deleted
even if you uninstall the chart.
When using Postgresql as dependency, this will also be deployed as a statefulset by default. 

If you want to manage your own PVC you can simply pass the PVC name to the chart. 

```yaml
  persistence:
    enabled: true
    existingClaim: MyAwesomeGiteaClaim
```

In case that peristence has been disabled it will simply use an empty dir volume.

Postgresql handles the persistence in the exact same way. 
You can interact with the postgres settings as displayed in the following example:

```yaml
  postgresql:
    persistence:
      enabled: true
      existingClaim: MyAwesomeGiteaPostgresClaim
```

Mysql also handles persistence the same, even though it is not deployed as a statefulset.
You can interact with the postgres settings as displayed in the following example:

```yaml
  mysql:
    persistence:
      enabled: true
      existingClaim: MyAwesomeGiteaMysqlClaim
```

### Admin User

This chart enables you to create a default admin user. It is also possible to update the password for this user by upgrading or redeloying the chart.
It is not possible to delete an admin user after it has been created. This has to be done in the ui.

```yaml
  gitea:
    admin:
      username: "MyAwesomeGiteaAdmin"
      password: "AReallyAwesomeGiteaPassword"
      email: "gi@tea.com"
```

### LDAP Settings

Like the admin user the ldap settings can be updated but also disabled or deleted.

```yaml
  gitea:
    ldap:
      enabled: true
      name: 'MyAwesomeGiteaLdap'
      securityProtocol: unencrypted
      host: "127.0.0.1"
      port: "389"
      userSearchBase: ou=Users,dc=example,dc=com
      userFilter: sAMAccountName=%s
      adminFilter: CN=Admin,CN=Group,DC=example,DC=com
      emailAttribute: mail
      bindDn: CN=ldap read,OU=Spezial,DC=example,DC=com
      bindPassword: JustAnotherBindPw
      usernameAttribute: CN
```

## Configuration

### Others

| Parameter           | Description                       | Default                      |
|---------------------|-----------------------------------|------------------------------|
|statefulset.terminationGracePeriodSeconds| Image to start for this pod | gitea/gitea |


### Image

| Parameter           | Description                       | Default                      |
|---------------------|-----------------------------------|------------------------------|
|image.repository| Image to start for this pod | gitea/gitea |
|image.version| Image Version | 1.12.2 |
|image.pullPolicy| Image pull policy | Always |

### Persistence

| Parameter           | Description                       | Default                      |
|---------------------|-----------------------------------|------------------------------|
|persistence.enabled| Enable persistence for Gitea |true|
|persistence.existingClaim| Use an existing claim to store repository information | |
|persistence.size| Size for persistence to store repo information | 10Gi |
|persistence.accessModes|AccessMode for persistence||
|persistence.storageClass|Storage class for repository persistence|standard|

### Ingress

| Parameter           | Description                       | Default                      |
|---------------------|-----------------------------------|------------------------------|
|ingress.enabled| enable ingress | false|
|ingress.annotations| add ingress annotations | |
|ingress.hosts| add hosts for ingress as string list | git.example.com |
|ingress.tls|add ingress tls settings|[]|

### Service

| Parameter           | Description                       | Default                      |
|---------------------|-----------------------------------|------------------------------|
|service.http.type| Kubernetes service type for web traffic | ClusterIP |
|service.http.port| Port for web traffic | 3000 |
|service.ssh.type| Kubernetes service type for ssh traffic | ClusterIP |
|service.ssh.port| Port for ssh traffic | 22 |
|service.ssh.annotations| Additional ssh annotations for the ssh service ||

### Gitea Configuration

| Parameter           | Description                       | Default                      |
|---------------------|-----------------------------------|------------------------------|
|gitea.config | Everything in app.ini can be configured with this dict. See Examples for more details | {} |

### Memcached BuiltIn

Memcached is loaded as a dependency from [Bitnami](https://github.com/bitnami/charts/tree/master/bitnami/memcached) if enabled in the values. Complete Configuration can be taken from their website.

The following parameters are the defaults set by this chart

| Parameter           | Description                       | Default                      |
|---------------------|-----------------------------------|------------------------------|
|memcached.service.port|Memcached Port| 11211|

### Mysql BuiltIn

Mysql is loaded as a dependency from stable. Configuration can be found from this [website](https://github.com/helm/charts/tree/master/stable/mysql)

The following parameters are the defaults set by this chart

| Parameter           | Description                       | Default                      |
|---------------------|-----------------------------------|------------------------------|
|mysql.mysqlRootPassword|Password for the root user. Ignored if existing secret is provided|gitea|
|mysql.mysqlUser|Username of new user to create.|gitea|
|mysql.mysqlPassword|Password for the new user. Ignored if existing secret is provided|gitea|
|mysql.mysqlDatabase|Name for new database to create.|gitea|
|mysql.service.port|Port to connect to mysql service|3306|
|mysql.persistence|Persistence size for mysql |10Gi|

### Postgresql BuiltIn

Postgresql is loaded as a dependency from bitnami. Configuration can be found from this [Bitnami](https://github.com/bitnami/charts/tree/master/bitnami/postgresql)

The following parameters are the defaults set by this chart

| Parameter           | Description                       | Default                      |
|---------------------|-----------------------------------|------------------------------|
|postgresql.global.postgresql.postgresqlDatabase| PostgreSQL database (overrides postgresqlDatabase)|gitea|
|postgresql.global.postgresql.postgresqlUsername| PostgreSQL username (overrides postgresqlUsername)|gitea|
|postgresql.global.postgresql.postgresqlPassword| PostgreSQL admin password (overrides postgresqlPassword)|gitea|
|postgresql.global.postgresql.servicePort|PostgreSQL port (overrides service.port)|5432|
|postgresql.persistence.size| PVC Storage Request for PostgreSQL volume |10Gi|
