# aerOS contributions to Orion-LD and deployment configurations

[Orion-LD](https://github.com/FIWARE/context.Orion-LD) is an open-source implementation of the NGSI-LD context broker developed by the FIWARE Foundation, which is continuously being improved within the scope of aerOS. This broker plays a crucial role in the Data fabric of T4.2 and domain federation of T4.6, but for management reasons it has been decided to store this repository in the T4.2 group of Gitlab.

<p>
  <a href="https://github.com/FIWARE/context.Orion-LD" target="_blank">
    <img src="https://img.shields.io/badge/View%20on-GitHub-181717?logo=github&style=for-the-badge" alt="View on GitHub">
  </a>
</p>

## Installation

The official container image is available in [DockerHub](https://hub.docker.com/r/fiware/orion-ld) and the latest release version is [1.10.0](https://github.com/FIWARE/context.Orion-LD/releases/tag/1.10.0). In addition, a new image is automatically generated and uploaded for each push to the main branch (*develop*), although it's not a new version release, just a development release.

However, as the testing and improvement of Orion-LD inside the scope of aerOS is constant, verified and tested changes in the source code are packaged into custom container images without waiting for official releases in Dockerhub. Therefore, these custom images are available in the aerOS private Common deployments repository, under the name *registry.gitlab.aeros-project.eu/aeros-public/common-deployments/orion-ld*. The latest tag is *1.4.2*, which includes new features such as distributed subscriptions and advanced CSRs filtering, and, in addition, it fixes an important bug related with the internal cache of Context Source Registrations.

> ⚠️**Warning** \
>  From Orion-LD 1.3.0 version (the latest one is 1.4.2), at least the **1.5.0 version of the aerOS API Gateway is installed** in the Domain, otherwise the Federation won't work as expected.
> 
>   This happens because Orion-LD has replaced the _onlyIds_ by the _pick_ URL parameter in its federated requests, so the _pick_ parameter must be included in the KrakenD configuration.
>


Orion-LD can be installed using [Docker compose](./docker/) in Docker machines (if you want to use a Docker image from the *common deployments* repository, you have to perform the *docker login* first):

```bash
  docker compose -f docker-compose-aeros.yaml up -d
```

or a [Helm chart](./helm-charts/orion-ld/) for K8s clusters, which **has been created from scratch during the aerOS project** (with the default configuration):

```bash
  helm install orion-ld aeros-common/orion-ld --set broker.args.brokerId=Domain01 --debug
```

In case you want to use a Docker image from the *common deployments* repository, the *aeros-common-deployments* **secret** is added to the *imagePullSecrets* of the broker in the default values of the chart, but **it must be previously created in the cluster** (this is the recommended configuration):

```bash
helm install orion-ld aeros-common/orion-ld --set broker.args.brokerId=Domain01 --set broker.args.traceLevel="70-99" --set broker.args.subordinateEndpoint=<full-broker-url-pointing-to-/ex/v1-endpoint>
```

In case you want to use the official Docker image from Dockerhub:

```bash
helm install orion-ld aeros-common/orion-ld --set broker.image.repository=fiware/orion-ld --set broker.image.tag=1.9.0 --set broker.args.brokerId=Domain01 --set broker.args.traceLevel="70-99"
```

In case your domain contains IEs with different CPU architectures than x64/AMD64, use the *chartNodeSelector* value to deploy it in a x64 arch node:

```bash
helm install orion-ld aeros-common/orion-ld --set broker.args.brokerId=Domain01 --set broker.args.traceLevel="70-99" --set broker.nodeSelector."beta\.kubernetes\.io/arch"=amd64
```

Finally, to deploy the broker and the MongoDB in a certain node, use the *chartNodeSelector* value:

```bash
  helm install orion-ld aeros-common/orion-ld --set chartNodeSelector."kubernetes\.io/hostname"=kubeedge-core --set broker.args.brokerId=Domain01
```

To deploy one of those components in a certain node, use the *<component>.nodeSelector* value:

```bash
  helm install orion-ld aeros-common/orion-ld --set broker.nodeSelector."kubernetes\.io/hostname"=node1 --set mongodb.nodeSelector."kubernetes\.io/hostname"=node2 --set broker.args.brokerId=Domain01 
```

> ⚠️**Warning** \
>  If you want to use the **distributed subscriptions** feature, you will have to set properly the *broker.args.subordinateEndpoint* value.
>

### Configuration

Some CLI arguments must be included when running Orion-LD to be compliant with the aerOS requirements:

- **-brokerId <broker_ID>**: unique identifier for the context broker. This value must be the domain name in aerOS, for instance, Domain03.
- **-forwarding**: enables brokers federation to perform distributed operations.
- **-experimental**: enables certain needed features. This flag is not required if *mongocOnly* is enabled.
- **-wip [feature1,feature2,...,featureN]**: enables new (under development) features. In aerOS it is recommended to use *-wip entityMaps,distSubs*.
    
    - **entityMaps**: CRUD operations for distributed NGSI-LD entities.
    - **distSubs**: distributed NGSI-LD subscriptions.
- **-noArrayReduction**: prevents the replacement of object arrays of a single element with an object. This occurs by default because of the JSON-LD specification.
- **-subordinateEndpoint**: only if the wip *distSubs* is enabled. It specifies the endpoint (e.g. https://domain.aeros-project.eu/orionld/ex/v1 or http://192.168.1.202:1028/ngsi-ld/ex/v1 that will be used to fill in the *notification* value of the subordinated subscriptions that are automatically created when a federated subscription is created.


Other CLI arguments for general purposes:

- **-dbhost <mongodb_url>**: url of the MongoDB database (e.g. 192.168.1.202:1028). The default value is *localhost:1026*.
- **-t**: trace levels. Use *0-255* to display all the information and *70-99* to only display information about distributed operations.
- **-logLevel <level>**: log level, *DEBUG* is recommended.
- **-disableFileLog**: disables the storage of logging messages into the default */tmp/orionld.log* file.
- **-mongocOnly**: enables the use of the new MongoDB driver for the C language, which provides a performance improvement. If it's not included, the broker will use the legacy MongoDB driver (in C++) that only supports MongoDB versions older than the 6.0. This flag overrides the *experimental* option.
- **-multiservice**: enables multi tenancy mode, which means the use of *NGSILD-Tenant* header.
- **-pageSize**: page size for results pagination. The default value is *20*, but it can be modified in runtime using the *limit* URL parameter in the queries.
- **-socketService**: enables a TCP socket that can be used for health checks. By default, it listens at 1027 TCP port.
- **-ssPort <port_number>**: modifies the TCP socket port (by default is 1027).

NGSI-LD entities persistence:

- **-troe**: enables the TRoE (temporal representation of entities) to persist the values of the entities attributes. It needs an additional **Timescale** database to work properly.
- **-troeHost <postgresql_host>**: host of the PostgreSQL database. The default value is *localhost*.
- **-troePort <postgresql_port>**: port of the PostgreSQL database. The default value is *5432*.
- **-troeUser <postgresql_user>**: username of the PostgreSQL database. The default value is *localhost*.
- **-troePwd <postgresql_pwd>**: password of the PostgreSQL database. The default value is *localhost*.

### Mintaka

[FIWARE Mintaka](https://github.com/FIWARE/mintaka) is an implementation of the NGSI-LD temporal retrieval API. It relies on the Orion-LD Context Broker to populate the required TimescaleDB database. Therefore, the Orion-LD instance must be configured to persist the historical values of the entities in a TimescaleDB (check the CLI arguments related with NGSI-LD entities persistence) to finally enable the use of Mintaka, because Mintaka actually just performs some read queries in the TimescaleDB.

<p>
  <a href="https://github.com/FIWARE/mintaka" target="_blank">
    <img src="https://img.shields.io/badge/View%20on-GitHub-181717?logo=github&style=for-the-badge" alt="View on GitHub">
  </a>
</p>

This TRoE related configuration must be applied after installing the Mintaka Helm chart (at least the **-troe** option because it enables the TRoE feature, the other configuration options can be prepopulated), because Orion-LD must be able to reach the TimescaleDB which is deployed in the Mintaka chart. Otherwise, the Orion-LD broker will fail.

> ⚠️**Warning** \
>  By default, all the entities will be historically persisted when enabling TRoE. 
>  To configure the entity types that are historically persisted, please set the proper values in the Helm chart (*troe* -> *allEntityTypes* and *entityTypes*).
>

Mintaka and the needed TimescaleDB can be installed using the provided Helm chart, which is still under development and open to changes:

```bash
  helm install mintaka aeros-common/mintaka
```

After installing the Mintaka Helm chart, if Orion-LD hasn't been installed yet, install it setting the proper TRoE related values:

```yaml
broker:
  args:
    troe:
      enabled: true
      host: mintaka-timescaledb.default.svc.cluster.local
      port: 5432
      user: orion
      password: 0r10n
      # Set to true to persist all the entities
      allEntityTypes: false
      # If allEntityTypes is set to false, set the entity types to be persisted
      entityTypes:
        - https://uri.etsi.org/ngsi-ld/default-context/Domain
        - https://uri.etsi.org/ngsi-ld/default-context/InfrastructureElement
        - https://uri.etsi.org/ngsi-ld/default-context/Service
        - https://uri.etsi.org/ngsi-ld/default-context/ServiceComponent
```

```bash
  helm install orion-ld aeros-common/orion-ld --set broker.args.brokerId=Domain01 -f troe-values.yaml --debug
```

If Orion-LD has been already installed, upgrade the chart with the proper TRoE related values. In this case, only the entities which are created after the enabling of TRoE will be persisted in the TimescaleDB, so only those entities will be available for Mintaka.

```yaml
broker:
  args:
    troe:
      enabled: true
      host: mintaka-timescaledb.default.svc.cluster.local
      port: 5432
      user: orion
      password: 0r10n
      # Set to true to persist all the entities
      allEntityTypes: false
      # If allEntityTypes is set to false, set the entity types to be persisted
      entityTypes:
        - https://uri.etsi.org/ngsi-ld/default-context/Domain
        - https://uri.etsi.org/ngsi-ld/default-context/InfrastructureElement
        - https://uri.etsi.org/ngsi-ld/default-context/Service
        - https://uri.etsi.org/ngsi-ld/default-context/ServiceComponent
```

```bash
  helm upgrade orion-ld aeros-common/orion-ld -f troe-values.yaml --reuse-values --debug
```


## Persistent storage of NGSI-LD entities in aerOS
Currently, the continuum data (Infrastructure Elements, Domains, Services, ...) is not being persisted, so only lastest value of these data is available (actually the latest values of the NGSI-LD entities attributes), as it's the purpose of a context broker, which means that **aerOS does not provide historical data of the continuum by default**.
However, these historical data can be useful for multiple purposes, for instance, to train an AI algorithm to be used in the HLO Allocator or to check the evolution of the performance of an IE over time.

Therefore, a solution has been envisaged to address this issue. This solution consists of deploying an additional instance of Orion-LD in the continuum (in the entrypoint domain), with the NGSI-LD entities persistence configured (*-troe* related options), in order to retrieve the configured entities from all the context brokers of the continuum with the configured time periodicity (these configurations are perfomed through the creation of a NGSI-LD distributed subscription). This way, these entities are stored in a TimescaleDB that can be queried by Mintaka (or other custom component) to be available for the final users or applications.

A testing procedure has been included inside the [continuum-entities-persistent-storage folder](./continuum-entities-persistent-storage/) to help in the adoption of this procedure.


## User guide

This is a list of useful official information about NGSI-LD and Orion-LD:

- [Introduction to NGSI-LD Entities and Attributes](https://github.com/FIWARE/context.Orion-LD/blob/develop/doc/manuals-ld/entities-and-attributes.md)
- [A guide to the NGSI-LD Context](https://github.com/FIWARE/context.Orion-LD/blob/develop/doc/manuals-ld/the-context.md)
- [Orion-LD quick start guide](https://github.com/FIWARE/context.Orion-LD/blob/develop/doc/manuals-ld/quick-start-guide.md)
- [NGSI-LD tutorial step-by-step](https://ngsi-ld-tutorials.readthedocs.io/en/latest/)
- [NGSI-LD in a Nutshell](https://docs.google.com/presentation/d/14aoHGYzmfn_a31ByG_Tf8pejuP6oWhjqhraLsPtRp_k)
- [Examples of NGSI-LD payloads](https://forge.etsi.org/rep/cim/NGSI-LD/-/tree/master/examples)
- [OpenAPI Specification for NGSI-LD API](https://forge.etsi.org/rep/cim/ngsi-ld-openapi/-/raw/v1.7.1/openapi-3.0.3/ngsi-ld-api.yaml): you can test it at [Swagger UI](https://forge.etsi.org/swagger/ui)


In addition, a [Postman collection](./Orion-LD.postman_collection.json) has been included to guide the users about the use of Orion-LD in aerOS.


> ⚠️ In aerOS, it must be used the *aerOS HTTP header* with a value of *true* when sending distributed requests to the context broker


The *aerOS-Array-Concat: TRUE* header can be used in entities' PATCH requests to concatenate arrays instead of replacing them (the default NGSI-LD behavior). This is useful when the NGSI-LD entity has an array attribute and the user wants to add a new element to that array without replacing the existing elements.


## Development and testing

The source code of Orion-LD is hosted in a [GitHub repository](https://github.com/FIWARE/context.Orion-LD) under a AGPL-3.0 license. This repository also includes a [developer guide](https://github.com/FIWARE/context.Orion-LD/blob/develop/doc/manuals-ld/developer-documentation.md), a [local installation guide from source](https://github.com/FIWARE/context.Orion-LD/blob/develop/doc/manuals-ld/installation-guide-ubuntu-20.04.1.md) (it's recommended to install Orion-LD from source in a machine with Ubuntu 20.04.1) and a [guide for installing and using Functional Tests](https://github.com/FIWARE/context.Orion-LD/blob/develop/doc/manuals-ld/installation-guide-functional-tests-ubuntu20.04.1.md).

### GitHub issues and pull requests

The testing and improvement process of Orion-LD in aerOS has been conducted using GitHub issues, so this is the list of the issues opened in the scope of aerOS:

- [#1466](https://github.com/FIWARE/context.Orion-LD/issues/1466)
- [#1467](https://github.com/FIWARE/context.Orion-LD/issues/1467)
- [#1468](https://github.com/FIWARE/context.Orion-LD/issues/1468)
- [#1469](https://github.com/FIWARE/context.Orion-LD/issues/1469)
- [#1478](https://github.com/FIWARE/context.Orion-LD/issues/1478)
- [#1479](https://github.com/FIWARE/context.Orion-LD/issues/1479)
- [#1480](https://github.com/FIWARE/context.Orion-LD/issues/1480)
- [#1525](https://github.com/FIWARE/context.Orion-LD/issues/1525)
- [#1551](https://github.com/FIWARE/context.Orion-LD/issues/1551)
- [#1556](https://github.com/FIWARE/context.Orion-LD/issues/1556)
- [#1583](https://github.com/FIWARE/context.Orion-LD/issues/1583)
- [#1589](https://github.com/FIWARE/context.Orion-LD/issues/1589)
- [#1630](https://github.com/FIWARE/context.Orion-LD/issues/1630)
- [#1644](https://github.com/FIWARE/context.Orion-LD/issues/1644)
- [#1652](https://github.com/FIWARE/context.Orion-LD/issues/1652)
- [#1672](https://github.com/FIWARE/context.Orion-LD/issues/1672)
- [#1673](https://github.com/FIWARE/context.Orion-LD/issues/1673)
- [#1688](https://github.com/FIWARE/context.Orion-LD/issues/1688)
- [#1692](https://github.com/FIWARE/context.Orion-LD/issues/1692)
- [#1715](https://github.com/FIWARE/context.Orion-LD/issues/1715)
- [#1733](https://github.com/FIWARE/context.Orion-LD/issues/1733)
- [#1748](https://github.com/FIWARE/context.Orion-LD/issues/1748)
- [#1762](https://github.com/FIWARE/context.Orion-LD/issues/1762)
- [#1778](https://github.com/FIWARE/context.Orion-LD/issues/1778)
- [#1803](https://github.com/FIWARE/context.Orion-LD/issues/1803)


And the list of Pull Requests without directly linked issues:

- [#1596](https://github.com/FIWARE/context.Orion-LD/pull/1596)
- [#1601](https://github.com/FIWARE/context.Orion-LD/pull/1601)
- [#1640](https://github.com/FIWARE/context.Orion-LD/pull/1640)
- [#1660](https://github.com/FIWARE/context.Orion-LD/pull/1660)
- [#1661](https://github.com/FIWARE/context.Orion-LD/pull/1661)
- [#1662](https://github.com/FIWARE/context.Orion-LD/pull/1662)
- [#1736](https://github.com/FIWARE/context.Orion-LD/pull/1736)
- [#1746](https://github.com/FIWARE/context.Orion-LD/pull/1746)
- [#1747](https://github.com/FIWARE/context.Orion-LD/pull/1747)
- [#1752](https://github.com/FIWARE/context.Orion-LD/pull/1752)
- [#1763](https://github.com/FIWARE/context.Orion-LD/pull/1763)
- [#1767](https://github.com/FIWARE/context.Orion-LD/pull/1763)