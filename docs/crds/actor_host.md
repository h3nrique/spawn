# Actor Host Resource

Actor Host resource is used to deploy custom actor systems on Spawn. User can specify custom actor system image, ports, environment variables, resources, etc. Spawn will use this information to deploy the actor system on the Spawn cluster.

Spawn will also deploy sidecar with the actor system. Sidecar is used to manage the actor system lifecycle and to provide actor system with Spawn specific features (e.g. persistence, cluster management, etc).

Sidecar is deployed as a separate container in the same pod where the actor system is running. Actor system can communicate with the sidecar over localhost. Sidecar is listening on the port 9001 by default.

## Basic CRD Example:

```yaml
---
apiVersion: spawn-eigr.io/v1
kind: ActorHost
metadata:
  name: my-app
  namespace: default
  annotations:
    spawn-eigr.io/actor-system: spawn-system
spec:
  host:
    image: eigr/my-app:latest
```

## CRD Attributes

| CRD Attribute                                                             | Description                                        | Mandatory | Default Value         | Possible Values |
| ------------------------------------------------------------------------- | ---------------------------------------------------| --------- | --------------------- | --------------- |
| .metadata.annotations.spawn-eigr.io/actors-global-backpressure-max-demand | [See  1](#1-actors-global-backpressure-max-demand) | No        | -1                    |                 |
| .metadata.annotations.spawn-eigr.io/actors-global-backpressure-min-demand | [See  2](#2-actors-global-backpressure-min-demand) | No        | -1                    |                 |
| .metadata.annotations.spawn-eigr.io/actors-global-backpressure-enabled    | [See  3](#3-actors-global-backpressure-enabled)    | No        | true                  |                 |
| .metadata.annotations.spawn-eigr.io/actor-system                          | [See  4](#4-actor-system)                          | Yes       | spawn-system          |                 |
| .metadata.annotations.spawn-eigr.io/app-host                              | [See  5](#5-app-host)                              | No        | 0.0.0.0               |                 |
| .metadata.annotations.spawn-eigr.io/app-port                              | [See  6](#6-app-port)                              | No        | 8090                  |                 |
| .metadata.annotations.spawn-eigr.io/cluster-poling-interval               | [See  7](#7-cluster-poling-interval)               | No        | 3000                  |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-address                       | [See  8](#8-sidecar-address)                       | No        | 0.0.0.0               |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-crdt-sync-interval            | [See  9](#9-sidecar-crdt-sync-interval)            | No        | 2                     |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-crdt-ship-interval            | [See 10](#10-sidecar-crdt-ship-interval)           | No        | 2                     |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-crdt-ship-debounce            | [See 11](#11-sidecar-crdt-ship-debounce)           | No        | 2                     |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-delayed-invokes               | [See 12](#12-sidecar-delayed-invokes)              | No        | true                  |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-http-pool-count               | [See 13](#13-sidecar-http-pool-count)              | No        | 8                     |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-http-pool-size                | [See 14](#14-sidecar-http-pool-size)               | No        | 30                    |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-http-pool-max-idle-timeout    | [See 15](#15-sidecar-http-pool-max-idle-timeout)   | No        | 1000                  |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-http-port                     | [See 16](#16-sidecar-http-port)                    | No        | 9001                  |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-image-tag                     | [See 17](#17-sidecar-image-tag)                    | No        | latest                |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-logger-level                  | [See 18](#18-sidecar-logger-level)                 | No        | info                  | info, debug     |
| .metadata.annotations.spawn-eigr.io/sidecar-metrics-disabled              | [See 19](#19-sidecar-metrics-disabled)             | No        | false                 |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-metrics-port                  | [See 20](#20-sidecar-metrics-port)                 | No        | 9001                  |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-metrics-log-console           | [See 21](#21-sidecar-metrics-log-console)          | No        | true                  |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-mode                          | [See 22](#22-sidecar-mode)                         | No        | sidecar               | sidecar, daemon |
| .metadata.annotations.spawn-eigr.io/sidecar-pubsub-adapter                | [See 23](#23-sidecar-pubsub-adapter)               | No        | native                |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-pubsub-nats-hosts             | [See 24](#24-sidecar-pubsub-nats-hosts)            | No        | nats://127.0.0.1:4222 |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-state-handoff-sync-interval   | [See 25](#25-sidecar-state-handoff-sync-interval)  | No        | 60                    |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-uds-enabled                   | [See 26](#26-sidecar-uds-enabled)                  | No        | false                 |                 |
| .metadata.annotations.spawn-eigr.io/sidecar-uds-socket-path               | [See 27](#27-sidecar-uds-socket-path)              | No        | /var/run/spawn.sock   |                 |
| .metadata.annotations.spawn-eigr.io/supervisors-state-handoff-controller  | [See 28](#28-supervisors-state-handoff-controller) | No        | persistent            |                 |
| .metadata.name                                                            | [See 29](#29-metadataname)                         | Yes       |                       |                 |
| .metadata.namespace                                                       | [See 30](#30-metadatanamespace)                    | No        | default               |                 |
| .spec.autoscaler.max                                                      | [See 31](#31-specautoscalermax)                    | No        | length(nodes) * 2     |                 |
| .spec.autoscaler.min                                                      | [See 32](#32-specautoscalermin)                    | No        | 1                     |                 |
| .spec.host.affinity                                                       | [See 33](#33-spechostaffinity)                     | No        |                       |                 |
| .spec.host.embedded                                                       | [See 34](#34-spechostembedded)                     | No        | false                 |                 |
| .spec.host.env                                                            | [See 35](#35-spechostenv)                          | No        |                       |                 |
| .spec.host.image                                                          | [See 36](#36-spechostimage)                        | Yes       |                       |                 |
| .spec.host.ports                                                          | [See 37](#37-spechostports)                        | No        |                       |                 |
| .spec.host.resources                                                      | [See 38](#38-spechostresources)                    | No        |                       |                 |
| .spec.host.volumeMounts                                                   | [See 39](#39-spechostvolumemounts)                 | No        |                       |                 |
| .spec.replicas                                                            | [See 40](#40-specreplicas)                         | No        | 1                     |                 |
| .spec.terminationGracePeriodSeconds                                       | [See 41](#41-specterminationgraceperiodseconds)    | No        | 405                   |                 |
| .spec.volumes                                                             | [See 42](#42-specvolumes)                          | No        |                       |                 |


### 1. actors-global-backpressure-max-demand
TODO

### 2. actors-global-backpressure-min-demand
TODO

### 3. actors-global-backpressure-enabled
TODO

### 4. actor-system
TODO

### 5. app-host
TODO

### 6. app-port
TODO

### 7. cluster-poling-interval
TODO

### 8. sidecar-address
TODO

### 9. sidecar-crdt-sync-interval
TODO

### 10. sidecar-crdt-ship-interval
TODO

### 11. sidecar-crdt-ship-debounce
TODO

### 12. sidecar-delayed-invokes
TODO

### 13. sidecar-http-pool-count
TODO

### 14. sidecar-http-pool-size
TODO

### 15. sidecar-http-pool-max-idle-timeout
TODO

### 16. sidecar-http-port
TODO

### 17. sidecar-image-tag
TODO

### 18. sidecar-logger-level
TODO

### 19. sidecar-metrics-disabled
TODO

### 20. sidecar-metrics-port
TODO

### 21. sidecar-metrics-log-console
TODO

### 22. sidecar-mode 
TODO

### 23. sidecar-pubsub-adapter
TODO

### 24. sidecar-pubsub-nats-hosts
TODO

### 25. sidecar-state-handoff-sync-interval
TODO

### 26. sidecar-uds-enabled
TODO

### 27. sidecar-uds-socket-path
TODO

### 28. supervisors-state-handoff-controller
TODO

### 29. metadata.name
TODO

### 30. metadata.namespace
TODO

### 31. spec.autoscaler.max
TODO

### 32. spec.autoscaler.min
TODO

### 33. spec.host.affinity 
TODO

### 34. spec.host.embedded 
TODO

### 35. spec.host.env
TODO

### 36. spec.host.image
TODO

### 37. spec.host.ports 
TODO

### 38. spec.host.resources 
TODO

### 39. spec.host.volumeMounts
TODO

### 40. spec.replicas
TODO

### 41. spec.terminationGracePeriodSeconds 
TODO

### 42. spec.volumes
TODO

[Next: Activator Resource](activator.md)

[Previous: Actor System Resource](actor_system.md)
