# Slurm in Docker - Toil/CWL support

***Non-funtional work-in-progress

Support for workflows compatible with the Toil workflow manager, including those written in CWL.

## Usage

Deploy the cluster: ```# docker-compose up -d```

Log into the controller node: ```# docker exec -ti controller /bin/bash```

Create "worker" user: 
```
# sacctmgr -i add account worker description="worker account" Organization=Slurm-in-Docker
# sacctmgr -i create user worker account=worker adminlevel=None
```

Log in to controller as "worker": ```$ docker exec -ti -u worker controller /bin/bash```

Issue a test: "$ srun -N 2 hostname"

If successful, create ```example.cwl```: 
```
cwlVersion: v1.0
class: CommandLineTool
baseCommand: echo
stdout: output.txt
inputs:
  message:
    type: string
    inputBinding:
      position: 1
outputs:
  output:
    type: stdout
```

Create ```example-job.yaml```: 
```
message: Hello World!
```

Export ```TOIL_SLURM_ARGS``` environment variable: ```export TOIL_SLURM_ARGS="-t 1:00:00 -q docker"```

Submit CWL workflow: 
```toil-cwl-runner --batchSystem slurm --disableCaching --defaultCores 1 --defaultMemory 100 example.cwl example-job.yaml```
