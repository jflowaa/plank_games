#!/bin/bash

echo yes | mix phx.gen.release --docker
cd ..
tar -cvzf plank_games.tar.gz -X plank_games/deployment/exclude.txt plank_games
scp plank_games.tar.gz root@digital-ocean:/root
ssh digital-ocean << EOF
tar -xvf plank_games.tar.gz
cd plank_games
docker build . -t plank_games --build-arg MIX_ENV="prod" && \
  docker stop plank_games && \
  docker rm plank_games && \
  docker run -d --name plank_games -e RELEASE_COOKIE=$RELEASE_COOKIE -e SECRET_KEY_BASE=$SECRET_KEY_BASE -p 4000:4000 -it plank_games
EOF
