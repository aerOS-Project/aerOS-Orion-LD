# aerOS persistent storage of NGSI-LD entities: testing procedure

1. An aerOS continuum with, at least, 2 federated instances of Orion-LD (by creating the proper CSRs)

2. Deploy the Docker compose file, which deploys 4 containers:

    - An extra instance of Orion-LD and its related MongoDB (the "persistence" broker)
    - TimescaleDB
    - FIWARE Mintaka

3. Create in the new Orion-LD (the "persistence" broker, this will be its unique purpose) the needed CSRs pointing to the other Orion-LDs of the continuum (it is needed one registration pointing to each existing broker)

4. Create a NGSI-LD Subscription per entity type (e.g. InfrastructureElement, Domain, ...) in the "persistence" broker, which must use the "/ngsi-ld/ex/v1/notify" endpoint of this broker as the notification endpoint of the subscription. In this subscription you have to specify the 

5. Check if the continuum data is being persisted by sending some temporal query requests to Mintaka.