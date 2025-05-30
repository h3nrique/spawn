# Elixir Projections

A projection actor is a specialized actor that creates views or queries based on the state of one or more sourceable actors. These actors use Protobuf definitions to specify:

* Source actors.
* Query options for views.
* Retention and ordering strategies.

## Defining Sourceable Actors

[Sourceable actors](../../projections.md#introduction) are regular actors with the additional `sourceable: true` attribute. Below is an example:

1. Define the actor’s Protobuf schema:

```protobuf
syntax = "proto3";

package inventory;

import "spawn/actors/extensions.proto";
import "google/api/annotations.proto";

message WarehouseProductState {
  string product_id = 1 [(spawn.actors.actor_id) = true]; // Unique ID
  string warehouse_id = 2;       // Deposit ID
  string name = 3;               // Product name
  int32 quantity = 4;            // Quantity in stock
}

message ProductUpdate {
  string product_id = 1; // Unique ID matching deposit and product
  string warehouse_id = 2;       // Deposit ID
  int32 quantity = 3;            // New quantity
  string name = 4;               // Product name
}

service WarehouseProductActor {
  // Setting the actor as sourceable
  option (spawn.actors.actor) = {
    kind: UNNAMED
    stateful: true
    state_type: ".inventory.WarehouseProductState",
    // here we are indicating that the state of this actor 
    // can be captured by any projection actor that is interested
    sourceable: true
  };

  // RPC to update the status of a product in the warehouse
  rpc UpdateProduct(.inventory.ProductUpdate) returns (.google.protobuf.Empty) {
    option (google.api.http) = {
      post: "/v1/products"
      body: "*"
    };
  }
}
```

2. Implement the sourceable actor:

```elixir
defmodule MyAppxample.Actors.WarehouseProductActor do
  use SpawnSdk.Actor, name: "WarehouseProductActor"

  alias Inventory.{WarehouseProductState, ProductUpdate}
  alias Google.Protobuf.Empty

  action("UpdateProduct", fn %Context{} = ctx, %ProductUpdate{} = update ->
    # Process the update and change the product state
    new_state = %WarehouseProductState{
      product_id: update.product_id,
      name: update.name,
      quantity: update.quantity,
      warehouse_id: update.warehouse_id
    }

    Value.of()
    |> Value.state(new_state)
    |> Value.noreply!()
  end)
end
```

## Creating Projection Actors

Projection actors also are defined using **Protobuf**. A typical Protobuf file for a projection actor includes attributes to specify:

* `kind`: Defines the actor as a projection.
* `subjects`: Lists ***sourceable actors*** and their respective ***actions***.
* `spawn.actors.view`: Specifies query configuration for creating views.

### Defining Projection

1. Define input, output, and state types:

```protobuf
syntax = "proto3";

package inventory;

import "spawn/actors/extensions.proto";

message ProductInventory {
  string product_id = 1 [(spawn.actors.actor_id) = true]; // Product ID
  string name = 2 [(spawn.actors.searchable) = true];     // Product name
  string warehouse_id = 3 [(spawn.actors.searchable) = true]; // Warehouse ID
  int32 quantity = 4;                                     // Quantity in stock
}

message ProductQuery {
  string product_id = 1; // Product ID
}

message WarehouseQuery {
  string warehouse_id = 1; // Warehouse ID
}

message GeneralInventoryResponse {
  repeated ProductInventory inventory = 1; // Consolidated list of products
}

```

***__NOTE__***: The `[(spawn.actors.searchable) = true]` option tells the Spawn proxy to index this field, so that searches for this attribute are optimized.

2. Define the actor’s properties and actions:

```protobuf
syntax = "proto3";

package inventory;

import "spawn/actors/extensions.proto";
// others omit import for brevity...

service InventoryProjectionActor {
  option (spawn.actors.actor) = {
    kind: PROJECTION
    stateful: true
    state_type: ".inventory.ProductInventory"
    subjects: [
      { actor: "WarehouseProductActor", source_action: "UpdateProduct", action: "Consolidate" }
    ]
  };

  rpc QueryProduct(.inventory.ProductQuery) returns (.inventory.GeneralInventoryResponse) {
    option (spawn.actors.view) = {
      query: "SELECT product_id, name, warehouse_id, SUM(quantity) FROM projection_actor WHERE product_id = :product_id GROUP BY product_id, name, warehouse_id"
      map_to: "inventory"
    };
  }

  rpc QueryWarehouse(.inventory.WarehouseQuery) returns (.inventory.GeneralInventoryResponse) {
    option (spawn.actors.view) = {
      query: "SELECT product_id, name, warehouse_id, quantity FROM projection_actor WHERE warehouse_id = :warehouse_id"
      map_to: "inventory"
    };
  }

  rpc QueryAllProducts(.google.protobuf.Empty) returns (.inventory.GeneralInventoryResponse) {
    option (spawn.actors.view) = {
      query: "SELECT product_id, name, warehouse_id, quantity FROM projection_actor"
      map_to: "inventory",
      page_size: "100"
    };
  }
}
```

### Key Attributes:

* `subjects`: Specifies the sourceable actor and the action used to generate data for the projection. 
              It also specifies which projection actor action will be responsible for handling this request.

* `spawn.actors.view`: Defines the SQL-like query for creating views.

* `map_to`: Specifies the target field in response (`.inventory.GeneralInventoryResponse`) where query results will be mapped.

* `page_size`: The number of records that will be added to the declared list attribute in `map_to`. 

## Implementing Projection Actors

After defining the Protobuf, implement the projection actor using the Spawn Elixir SDK. For example:

```elixir
defmodule MyAppxample.Actors.InventoryProjectionActor do
  use SpawnSdk.Actor, name: "InventoryProjectionActor"

  alias Inventory.{WarehouseState, ProductInventory}

  action("Consolidate", fn %Context{} = ctx, %WarehouseState{} = product ->
    Value.of()
    |> Value.state(%ProductInventory{
      product_id: product.product_id, # This will effectively upsert the permanent storage by updating the quantity of each product by its product_id
      name: update.name,
      warehouse_id: update.warehouse_id,
      quantity: update.quantity
    })
  end)
end
```

## Invoking Projection Actor's Views

Projection actors support custom queries defined in the Protobuf. Examples include:

* `QueryProduct`: Retrieve consolidated stock for a specific product.
* `QueryAllProducts`: Retrieve the consolidated stock for all products.

Once deployed, a projection actor can be invoked like any other actor. Use the query attributes defined in the Protobuf to fetch desired data like:

```elixir
alias Inventory.{ProductQuery, GeneralInventoryResponse}
alias Inventory.InventoryProjectionActor, as: InventoryClient

{:ok, %GeneralInventoryResponse{inventory: inventories} = _response} = InventoryClient.query_product(%ProductQuery{product_id: "some_id"}, metadata: %{"page" => 
"1", "page_size" => "50"})
```

[Next: SDKS](../../sdks.md)

[Previous: Workflows](workflows.md)