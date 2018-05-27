module.exports = {
  networks: {
        development: {
	        host: "localhost",
	        port: 8545,
	        network_id: "2018", // Match any network id
            gas: 4600000
        }
    },
	mocha: {
    reporter: 'eth-gas-reporter',
	    reporterOptions : {
	      currency: 'CHF',
	      gasPrice: 21
	    }
	},
	solc: {
	    optimizer: {
	        enabled: true,
	        runs: 200
	    }
	}
};
