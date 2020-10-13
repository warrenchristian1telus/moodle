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
## ! Make sure Docker Desktop is running !
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

#### OpenShift CodeReadyContainers
## ! Make sure Docker Desktop is running !
## before running, insure you "docker pull php:7.2-apache" or whatever source image you're using in the Dockerfile
# crc setup (use for local network settings - seems to need to run after every restart)
# crc start (/stop)

#### OpenShift Console
# * Copy login command from production openshift console
# oc login --token=XXXX --server=https://XXXX.com:6443
# oc status
# oc create imagestream moodle (create th eimage stream to use for install)
##
# oc describe network.config/cluster


#### Help

# oc new-app -L # List all available apps

## Error: ImagePrunerDegraded: Job has reached the specified backoff limit
# oc describe co image-registry
# oc patch imagepruner.imageregistry/cluster --patch '{"spec":{"suspend":true}}' --type=merge    (FAILED)
# oc -n openshift-image-registry delete jobs --all

#### Template
## Instantiating a new Template:

## Note: crc delete # to clear everything

### Add image to docker hub (from previously created local docker image)

### docker tag local-image:tagname new-repo:tagname
# docker tag mysql:5.7 warrenchristian1/moodle:mysql

### Prepare ImageStream
# docker login https://registry.redhat.io
# New App from RedHat mysql-persistent image
# oc new-app -e MYSQL_USER=moodle -e MYSQL_PASSWORD="password" -e MYSQL_DATABASE=moodle -e MYSQL_USER=moodle -e MYSQL_ROOT_PASSWORD="root password" -e MYSQL_SERVICE_HOST=mysql -e MYSQL_SERVICE_PORT=3307 mysql-persistent
 
### Install Pipeline
# oc apply -f openshift/app/moodle-pipeline-local.yaml --dry-run

#################
## MySQL Template
# oc process -f openshift/app/mysql-persistent-template.json -p APP_NAME=moodle -p DB_HOST_NAME=mysql -p DB_MEMORY_LIMIT=1Gi -p DB_VOLUME_CAPACITY=1Gi -p PROJECT_NAMESPACE=local -p DB_SERVICE_NAME=moodle-mysql -p DB_HOST=mysql -p DB_NAME=moodle -p DB_USER=moodle -p DB_BUILD_IMAGE="mysql:5.7" -p DB_PORT=3307 -p DB_PASSWORD=password -p MYSQL_TAG=5.7 | oc create -f -

# oc new-app openshift/app/mysql-persistent-template.json -p APP_NAME=moodle -p DB_HOST_NAME=mysql -p DB_MEMORY_LIMIT=1Gi -p DB_VOLUME_CAPACITY=1Gi -p PROJECT_NAMESPACE=local -p DB_SERVICE_NAME=moodle-mysql -p DB_HOST=mysql -p DB_NAME=moodle -p DB_USER=moodle -p MYSQL_VERSION=5.7 -p DB_PORT=3307 -p DB_PASSWORD=password -p MYSQL_TAG=5.7 --dry-run=client

##################
## Moodle Template
# oc process -f openshift/app/moodle-persistent-template.json -p APP_NAME=moodle -p SITE_URL=http://localhost:8080 -p DB_HOST_NAME=mysql -p MOODLE_MEMORY_LIMIT=1Gi -p PROJECT_NAMESPACE=local -p DB_SERVICE_NAME=moodle-aro-mysql -p MOODLE_VOLUME_CAPACITY=5Gi -p DB_NAME=moodle -p DB_USER=moodle -p HTTP_PORT=8080 -p DB_PORT=3307 -p DB_PASSWORD=password | oc create -f -

# oc new-app openshift/app/moodle-persistent-template.json -p APP_NAME=moodle -p SITE_URL=http://localhost:8080 -p DB_HOST_NAME=mysql -p MOODLE_MEMORY_LIMIT=1Gi -p PROJECT_NAMESPACE=local -p DB_SERVICE_NAME=moodle-aro-mysql -p MOODLE_VOLUME_CAPACITY=5Gi -p DB_NAME=moodle -p DB_USER=moodle -p HTTP_PORT=8080 -p DB_PORT=3307 -p DB_PASSWORD=password --dry-run=client

## Moodle & MySQL Template (not working yet)
# oc new-app openshift/app/moodle-mysql-persistent-template.json -p APP_NAME=moodle -p DB_HOST_NAME=mysql -p DB_MEMORY_LIMIT=1Gi -p DB_VOLUME_CAPACITY=1Gi -p PROJECT_NAMESPACE=local -p DB_SERVICE_NAME=moodle-aro-mysql -p MOODLE_VOLUME_CAPACITY=5Gi -p DB_HOST=mysql -p DB_NAME=moodle -p DB_USER=moodle -p DB_BUILD_IMAGE="mysql:5.7" -p HTTP_PORT=8080 -p DB_PORT=3307 -p DB_PASSWORD=password --dry-run=client


###########
## Apply "processed" file (MySQL processed + Moodle processed)
# oc apply -f openshift/app/moodle-mysql-persistent-list.json

# oc expose svc/moodle

## Adding a database as a template
## Use this if, instead of instantiating a service right away, you want to load the template into an OpenShift project so that it can be used later.
# oc create -f /openshift/app/mysql-persistent-template.json

