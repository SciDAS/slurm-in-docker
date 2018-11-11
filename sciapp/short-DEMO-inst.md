**Short Demo Instructions**

GFS Cluster is up and configured.

**Start Client**

Start client: Navigate to ```$SLURM_IN_DOCKER_PATH/gfs-client/client```

Connect with ```docker-compose up```

New terminal - run ```docker exec -ti client /bin/bash```


**Generate and Submit SciApp**

Go to ```http://129.114.109.10``` to access DC/OS and show usage.

New terminal - Navigate to ```$SLURM_IN_DOCKER_PATH/sciapp```

Run ```./generate.sh slurm 6 12 24576 4096 "192.5.87.104:glusterfs"```

Submit with ```curl -X POST -d @slurm.json http://129.114.108.45:9191/appliance```

Show DC/OS usage.


**SSH into SciApp**

Go to ```http://129.114.108.45:9191/appliance/slurm/ui``` and copy external IP

Navigate to ```~/.ssh````

Run ```ssh-keyscan -H -p 20022 -t rsa $EXT_IP  >> ~/.ssh/known_hosts``` with correct external IP.

Print private key in client with ```cat /mnt/gv0/.secret/root_ssh_controller/id_rsa``` and paste into file ```demoKey``` with ```nano demoKey``` then ```chmod 700 demoKey```

Add with ```ssh-add demoKey```

SSH into SciApp with ```ssh -i authorized_keys -p 20022 root@$EXT_IP```


**Test SciApp**

Run ```sinfo -lN``` and ```srun -N 6 hostname``` to test Slurm.

Run ```module avail``` to test LMods.


**Run GEMmaker**

Switch to worker user with ```su - worker``` 

Add the Screen module ```module add screen```

Start Screen with ```screen``` and navigate to ```/home/worker/GEMmaker-demo```

Add Java and Nextflow with ```module add java nextflow```

Run GEMmaker with ```nextflow run main.nf -profile slurm -resume```

Add Python3 module with ```module add python3```

After all cached steps have executed, generate GEM with ```python3 ./scripts/create_GEM.py --source ./ --type TPM --prefix my_project```

Look at GEM with ```head my_project.GEM.TPM.txt```


**IRODS**

If you want to show iRODS connectivity, add the icommands with ```module add irods-icommands```

Run ```iinit```, enter in your redentials.

Test with ```ils``` 


**Shutdown**

Deprovision the cluster with ```curl -X DELETE http://129.114.108.45:9191/appliance/slurm```





