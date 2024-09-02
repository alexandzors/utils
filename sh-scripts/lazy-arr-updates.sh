#/bin/sh
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ABBR=media

echo "Updating all containers in the current directory with the abbreviation of ${ABBR}..."
for container in *.yml ; do
        docker compose -f $container down
        docker compose -f $container pull
        docker compose -f $container up -d
done
if [ $? -eq 0 ]; then
    echo "${GREEN}Updates complete..."
else
    echo "${RED}One or more updates failed..."
    exit 1
fi
echo "Cleaning up old Docker images..."
yes | docker image prune
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Image pruning succeeded.\n ${NC}All containers running."
    docker ps --filter "name=${ABBR}-*"
    exit 0
else
    echo -e "${RED}Image pruning failed.."
    exit 1
fi