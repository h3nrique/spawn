defmodule Sidecar.Grpc.Generators.ReflectionServerGenerator do
  @moduledoc """
  Module for generating a gRPC reflection server module.

  This module implements the `ProtobufGenerate.Plugin` behaviour to generate a gRPC reflection server
  module that includes specified gRPC services for reflection purposes.

  """
  @behaviour ProtobufGenerate.Plugin

  alias Protobuf.Protoc.Generator.Util

  @impl true
  def template do
    """
    defmodule Sidecar.GRPC.Reflection.Server do

      defmodule V1 do
        use GrpcReflection.Server, version: :v1, services: [
          <%= for service_name <- @services do %>
            <%= service_name %>.Service,
          <% end %>
        ]
      end

      defmodule V1Alpha do
        use GrpcReflection.Server, version: :v1alpha, services: [
          <%= for service_name <- @services do %>
            <%= service_name %>.Service,
          <% end %>
        ]
      end
    end
    """
  end

  @impl true
  def generate(ctx, %Google.Protobuf.FileDescriptorProto{name: name, service: svcs} = _desc) do
    current_services = :persistent_term.get(:grpc_reflection_services, [])

    {_name,
     [
       services: services
     ]} = result = do_generate(ctx, name, svcs, current_services)

    :persistent_term.put(:grpc_reflection_services, services)

    result
  end

  defp do_generate(_ctx, name, nil, current_services) do
    {name,
     [
       services: current_services
     ]}
  end

  defp do_generate(_ctx, name, [], current_services) do
    {name,
     [
       services: current_services
     ]}
  end

  defp do_generate(ctx, _name, svcs, current_services) do
    services =
      svcs
      |> Enum.map(fn svc -> Util.mod_name(ctx, [Macro.camelize(svc.name)]) end)
      |> Kernel.++(current_services)

    {List.first(services),
     [
       services: services
     ]}
  end
end
