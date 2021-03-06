mkdir drives 2> /dev/null
mkdir system 2> /dev/null

if [ -z $1 ]; then
	echo 'USAGE: sh init.sh [NUM_NODES]'
	exit
fi

# Export ENV variables
export $(sed -e 's/:[^:\/\/]/=/g;s/$//g;s/ *=/=/g' env.yml)

# Start memcache
cd cache && sh start-cache.sh

# Start nodes
cd ../app
priv_key=rsa_1024_priv.pem
pub_key=rsa_1024_pub.pem
openssl genrsa -out $priv_key 1024
openssl rsa -pubout -in $priv_key -out $pub_key

s=''
for i in `seq 1 $1`
do
	sh start-node-pro.sh $i
	container=$(docker ps -lq)
	
	# Ensure required permissions
	docker exec $container chown www-data:www-data private/drives
	docker exec $container chown www-data:www-data private/system
	docker exec $container chown www-data:www-data /var/www/$priv_key
	docker exec $container chown www-data:www-data /var/www/$pub_key
	docker exec $container chown www-data:www-data log/production.log

	new_ip_addr=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $container)
	echo "Started node with ip addr: $new_ip_addr"
	s="$s\tserver $new_ip_addr fail_timeout=30;\n"
done

# Start backup
#echo "Starting backup..."
#cd ../backup && sh start-backup.sh

# Start load balancer
cd ../load-balancer
sed -e "s/__MARKER__/$s/" template.conf > default.conf
sh start-load-balancer.sh

# Start sentinel
cd ../sentinel
sh start-sentinel.sh
