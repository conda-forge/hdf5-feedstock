#!/bin/bash
set -euo pipefail

if [[ "$mpi" == "mpich" ]]; then
    export HYDRA_LAUNCHER=fork
fi

if [[ "$mpi" == "openmpi" ]]; then
  export OMPI_MCA_plm_ssh_agent=false
  export OMPI_MCA_pml=ob1
  export OMPI_MCA_mpi_yield_when_idle=true
  export OMPI_MCA_btl_base_warn_component_unused=false
  export PRTE_MCA_rmaps_default_mapping_policy=:oversubscribe
fi

# pipe stdout, stderr through cat to avoid O_NONBLOCK issues
mpiexec $@ 2>&1 | cat
