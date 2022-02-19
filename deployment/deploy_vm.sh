#!/usr/bin/bash

tar -cvzf plank_games.tar.gz -X deployment/exclude.txt ../plank_games
scp plank_games.tar.gz root@plank-games:/var/www/html
ssh plank-games "cd /var/www/html && tar -xvf plank_games.tar.gz"
ssh plank-games "cd /var/www/html/plank_games && ./deployment/build.sh"
ssh plank-games "cd /var/www/html/plank_games && _build/prod/rel/plank_games/bin/plank_games stop"
ssh plank-games "cd /var/www/html/plank_games && _build/prod/rel/plank_games/bin/plank_games daemon"
