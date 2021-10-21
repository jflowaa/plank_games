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

You'll need to have Minikube and Docker/Podman installed and running. You'll also need the `ingress` addon.

```bash
minikube start
minikube addons enable ingress
```

You'll also want to update your host file to allow for domain resolving to Minikube's IP:

```bash
echo "$(minikube ip)  plank.games" >> /etc/hosts
```

To start:

- While volume mount image isn't setup:
  - Build image of server: `docker build . -f deployment/Dockerfile -t plank-games:v1`
  - Add image to Minikube: `minikube image load plank-games:v1`
  - Update [deployment/base/deployment.yaml](deployment/base/deployment.yaml) with tag used
  - Then apply manifests to cluster: `kubectl apply -k deployment/base/`
- When volume mount image is setup:
  - todo

Now you can vist [plank-games.test](http://plank-games.test) from your browser.

> Configure a way to run under volume mount
