# PlankGames

Something I've been writing to learn Elixir, OTP, Phoenix, and its deployment patterns. The concept of this project is to play board games with other people. The UI is driven via Phoenix's LiveView. Also took this time to get familiar with Tailwind.

Site is hosted at: [plank.games](https://plank.games)

> DigitalOcean, five dollar droplet

## Known Issues

- There's a lot of inefficiencies in the codebase
  - Yahtzee is currently full of them
- I think there might be a diagonal solving issue on connect four
- Yahtzee scoring logic isn't complete

## How to Run

Preferred method of running locally is via your local runtime

### Local Runtime

To start:

```bash
mix deps.get
iex -S mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser

### Minikube (Kubernetes)

> Haven't touched this in awhile. Only initially did it to feel out Elixir/Phoenix on Kubernetes and clustering. Also probably doesn't work anymore

You'll need to have Minikube and Docker/Podman installed. Once installed you can start Minikube and set it up with:

```bash
minikube start
minikube addons enable ingress
```

To allow for domain resolving to Minikube's IP:

```bash
echo "$(minikube ip)  plank.games" >> /etc/hosts
```

Then run the application via:

```bash
kubectl apply -k deployment/overlays/local
```

TODO: instructions for ksync
