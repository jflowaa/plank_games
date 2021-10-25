#! /bin/bash

echo "Installing Hex and Rebar"
mix local.hex --force
mix local.rebar --force

echo "Staring server"

mix phx.server