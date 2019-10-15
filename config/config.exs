use Mix.Config
config :libcluster,
 topologies: [
   example: [
     # The selected clustering strategy. Required.
     strategy: Cluster.Strategy.Epmd,
     # Configuration for the provided strategy. Optional.
     config: [hosts: [:"a@MacBook-Pro-de-EDUARDO.local", :"b@MacBook-Pro-de-EDUARDO.local"]],
   ]
 ]