require("@nomicfoundation/hardhat-toolbox");
const privateKey = require("../privateKey/IFO.json").key;
module.exports = {
    networks: {
        ganache: {
            url: "http://127.0.0.1:7545",
        },
        rinkeby: {
            // url: "https://rinkeby.infura.io/v3/c7bae63096c74b3dad54ad7ae275df0c",
            url: "https://rinkeby.infura.io/v3/c7bae63096c74b3dad54ad7ae275df0c",

            accounts: [privateKey],
            // gas: 2100000,
            // gasPrice: 8000000000,
            saveDeployments: true,
        },
    },
    solidity: {
        compilers: [
            {
                version: "0.8.7",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
            {
                version: "0.8.4",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
            {
                version: "0.8.1",
            },
            {
                version: "0.8.0",
            },
            {
                version: "0.7.6",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
            {
                version: "0.7.0",
            },
            {
                version: "0.6.12",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
            {
                version: "0.6.6",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
            {
                version: "0.5.16",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
            {
                version: "0.5.0",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
            {
                version: "0.4.18",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    mocha: {
        timeout: 200000,
    },
};
