<h1 align="center">LensCompetitions 🌱</h1>

<h2 align="center">On-chain competition framework for Lens Protocol</h2>

## Getting Started

This project uses [Foundry](https://getfoundry.sh).

1. Clone and run `cp .env.example .env`.
2. In a terminal, run:

```bash
forge install
forge test
```

### Deploy to Anvil

1. In one terminal run:
```bash
./script/node.sh
```
2. In another terminal run:
```bash
forge script LocalScript --fork-url local --broadcast
```

3. The addresses of the deployed contracts are printed at the start of the log outputs.

### ABIs

Provided the memester frontend is in `../frontend` relative to this repo, you can use the below script to update all ABIs:
```bash
./script/abis.sh
```

### Recommendation

We recommend installing the accompanying pre-commit hook to automatically run `forge fmt` and `forge snapshot` on commit:

```bash
cp hooks/pre-commit .git/hooks/pre-commit
```

## Usage

This powers the on-chain meme competitions for https://memester.xyz but has been built to be as extensible as possible for other Lens applications.
