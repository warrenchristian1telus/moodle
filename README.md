##
##  Build and Deploy Moodle
#### in Apache, PHP, MySQL environment
#### with Composer
#### managed via GitHub Repo

####
#
#  Initial Deploy
#
## Build Docker Image, login, run Composer Installation
### ! Make sure Docker Desktop is running !
#### docker-compose up -d --build

### docker-compose ps (find container name)
### docker exec -it container_name bash (login to container using name)
### chown -R www-data:www-data /app/web
### complete install at: http://localhost:8181

### !! CLEANUP !! Delete all containers and images, to get a clean start
#### docker-compose down
#### docker-compose stop
#### docker system prune
#### docker container prune
#### docker volume prune

## OpenShift CodeReadyContainers
### ! Make sure Docker Desktop is running !
#### before running, insure you "docker pull php:7.2-apache" or whatever source image you're using in the Dockerfile
#### crc setup (use for local network settings - seems to need to run after every restart)
#### crc start (/stop)

## OpenShift Login (Get CLI login command from Console)
#### crc console
#### oc login --token=XXXX --server=https://XXXX.com:6443

## Login to Docker
#### docker login https://registry.redhat.io

### Add image to docker hub (from previously created local docker image)
#### docker tag local-image:tagname new-repo:tagname
#### docker tag mysql:5.7 your_repo/moodle:mysql

## New App from RedHat mysql-persistent image
#### oc new-app -e MYSQL_USER=moodle -e MYSQL_PASSWORD="password" -e MYSQL_DATABASE=moodle -e MYSQL_USER=moodle -e MYSQL_ROOT_PASSWORD="root password" -e MYSQL_SERVICE_HOST=mysql -e MYSQL_SERVICE_PORT=3307 mysql-persistent

### Build MySQL App
#### oc new-app openshift/app/mysql-persistent-template.json -p APP_NAME=moodle -p DB_HOST_NAME=mysql -p DB_MEMORY_LIMIT=1Gi -p DB_VOLUME_CAPACITY=1Gi -p PROJECT_NAMESPACE=local -p DB_SERVICE_NAME=moodle-mysql -p DB_HOST=mysql -p DB_NAME=moodle -p DB_USER=moodle -p MYSQL_VERSION=5.7 -p DB_PORT=3307 -p DB_PASSWORD=password -p MYSQL_TAG=5.7 --dry-run=client

## Moodle Template
### Build/push Docker Image
##### docker login -u username -p password
### Tag image
##### docker build -t your_repo/moodle:app-docker .
##### docker push your_repo/moodle:app

#### docker pull mysql/mysql-server:5.7
#### docker run --name moodle-mysql --restart on-failure -d mysql/mysql-server:5.7

## Authorize OpenShift to use Docker Registry
#### oc create secret new-dockercfg docker-pull-secret --docker-server=docker.io --docker-username=your_account --docker-password=password --docker-email=your.email@some.com
#### oc secrets link default docker-pull-secret --for=pull
#### oc tag docker.io/warrenchristian1/moodle:mysql moodle:mysql

## Import docker image
#### oc import-image moodle-mysql --from docker.io/warrenchristian1/moodle:mysql --confirm --dry-run

## Build Moodle App
#### oc new-app openshift/app/moodle-persistent-template.json -p APP_NAME=moodle -p SITE_URL=http://localhost:8080 -p DB_HOST_NAME=mysql -p MOODLE_MEMORY_LIMIT=1Gi -p PROJECT_NAMESPACE=local -p DB_SERVICE_NAME=moodle-aro-mysql -p MOODLE_VOLUME_CAPACITY=5Gi -p DB_NAME=moodle -p DB_USER=moodle -p HTTP_PORT=8080 -p DB_PORT=3307 -p DB_PASSWORD=password --dry-run=client
