#/bin/bash

docker-compose stop
docker-compose rm -f
docker volume rm slurmindocker_home slurmindocker_secret
docker network rm slurmindocker_slurm
