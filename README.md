####
##
##  Build and Deploy Moodle
##    in Apache, PHP, MySQL environment
##    with Composer
##    managed via GitHub Repo
##
####
#
#  Initial Deploy
#
#### Build Docker Image, login, run Composer Installation
# docker-compose up -d --build
## docker-compose ps (find container name)
## docker exec -it container_name bash (login to container using name)
## chown -R www-data:www-data /app/web
## complete install at: http://localhost:8181

#### !! CLEANUP !! Delete all containers and images, to get a clean start
## docker-compose down
## docker-compose stop
## docker system prune
## docker container prune
## docker volume prune

# Convert docker-compose to OpenShift (Kubernetes) - https://kompose.io/
# kompose convert
# kompose up
# kompose down


#### OpenShift CodeReadyContainers
# crc setup (use for local network settings - seems to need to run after every restart)
# crc start
#### OpenShift Console
# oc status
# 