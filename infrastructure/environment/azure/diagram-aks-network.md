graph TD
  subgraph Config
    globals[Global Config]
    local[Local Config]
    env[Environment Config]
  end
  subgraph Network
    vnet[VNet]
    subnets[Subnets]
    nsg[NSGs]
  end
  subgraph AKS
    aks[AKS Cluster]
    nodepools[Node Pools]
  end
  globals -->|defaults, naming| Network
  globals -->|defaults, naming| AKS
  local -->|env/app overrides| Network
  local -->|env/app overrides| AKS
  env -->|resource specifics| Network
  env -->|resource specifics| AKS
  Network -->|subnet ID output| AKS
  vnet --> subnets
  subnets --> nsg
  aks --> nodepools
