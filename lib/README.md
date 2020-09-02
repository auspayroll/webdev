# Webdev2

To start your Phoenix server:

  * Setup the project with `mix setup`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

# Building the image

docker-compose build . # builds from docker-compose.yml

# the image name is webdev_prod

#once the image is built, 

docker save -o production_image.tar.gz webdev_prod 

# copy the docker image to server

scp production_image simon@45.79.238.203:~

# unzip the image and load into docker 

docker load -i production_image.tar
rm production_image.tar

#check loaded
docker image ls

# copy and set .env environment variables
scp .env simon@45.79.238.203:~

# start the container
docker start -d -p 4000:4000 wevdev_prod 
docker run --publish 80:4000 --detach --name mars webdev_prod 
docker ps -a #check mars is running




# README 
