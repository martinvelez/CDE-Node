docker start CDE-cache
docker start CDE-node-1
docker start CDE-node-2
docker start CDE-load-balancer
docker start nginx-proxy
docker start CDE-sentinel
sh migrate.sh
