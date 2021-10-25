# PlankGames

Something I've been writing to learn Elixir, OTP, and Phoenix. The concept of this project is to play board games with other people. The UI is driven via Phoenix's LiveView.

Tic Tac Toe is the only game implemented.

Site is hosted at: [plank.games](https://plank.games)

## How to Run

There are a few ways to run this. You can run it locally via your runtime or on [Minikube](https://minikube.sigs.k8s.io/docs/).

### Local Runtime

To start:

- Install dependencies with `mix deps.get`
- Start Phoenix endpoint with `PORT=4000 iex --name blue@127.0.0.1 -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser

### Minikube (Kubernetes)

> This process can be simplified

You'll need to have Minikube and Docker/Podman installed. Once installed you can start Minikube and set it up with:

```bash
minikube start
minikube addons enable ingress
```

To allow for domain resolving to Minikube's IP:

```bash
echo "$(minikube ip)  plank.games" >> /etc/hosts
```

TODO: instructions for ksync