use Mix.Config
config :libcluster,
 topologies: [
   example: [
     # The selected clustering strategy. Required.
     strategy: Cluster.Strategy.Epmd,
     # Configuration for the provided strategy. Optional.
     config: [hosts: [:"a@127.0.0.1", :"b@127.0.0.1"]],
   ]
 ]