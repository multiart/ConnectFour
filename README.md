# ConnectFour

ConnectFour - smartcontract and dApp example

This repository contains a Solidity smart contract ConnectFour that can be compiled, tested, and deployed using both Ape and Foundry frameworks.

## Development Frameworks

### Ape
[Ape](https://github.com/ApeWorX/ape) is a Python-based development framework and smart contract tool that provides a suite of tools for Ethereum development.

### Foundry
[Foundry](https://github.com/foundry-rs/foundry) is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.

## Getting Started

### Prerequisites
- Install Ape: `pip install eth-ape`
- Install Foundry: `curl -L https://foundry.paradigm.xyz | bash`
- Install Yarn: `npm install -g yarn`


### Building
```bash
# Using Ape
yarn build-with-ape

# Using Foundry
yarn build-with-foundry
```


### Testing
```bash
# Using Ape
yarn test-with-ape

# Using Foundry
yarn test-with-foundry
```

### Deploying

## Project Structure
```
├── contracts/       # Smart contract source files
├── test/          # Test files
├── scripts/        # Deployment scripts
└── README.md
```

## License
[MIT](https://mit-license.org)
