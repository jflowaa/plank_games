#!/bin/bash

echo yes | mix phx.gen.release --docker
cd ..
tar -cvzf plank_games.tar.gz -X plank_games/deployment/exclude.txt plank_games
scp plank_games.tar.gz root@digital-ocean:/root
ssh digital-ocean << EOF
rm -rf plank_games/
tar -xvf plank_games.tar.gz
cd plank_games/
docker build . -t plank-games --build-arg MIX_ENV="prod"
docker-compose -f deployment/docker-compose.yaml down
docker-compose -f deployment/docker-compose.yaml up -d
EOF
