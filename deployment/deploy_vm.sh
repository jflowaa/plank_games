#!/usr/bin/bash

tar -cvzf plank_games.tar.gz -X deployment/exclude.txt ../plank_games
scp plank_games.tar.gz root@plank-games:/var/www/html
