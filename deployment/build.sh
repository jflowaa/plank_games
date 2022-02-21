#!/usr/bin/bash

export MIX_ENV=prod
mix deps.get --only $MIX_ENV
mix deps.compile
mix assets.deploy
mix compile
mix release --overwrite
