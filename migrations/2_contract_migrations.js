var Index           = artifacts.require("./Index.sol");
var Admin 			= artifacts.require('./Admin.sol');
var Registry        = artifacts.require("./Registry.sol");
var RegistryStorage = artifacts.require('./RegistryStorage.sol');
var Token           = artifacts.require('./Token.sol');
var TokenStorage    = artifacts.require('./TokenStorage.sol');
var Loan            = artifacts.require('./Loan.sol');
var LoanStorage     = artifacts.require('./LoanStorage.sol')

module.exports = function (deployer) {
	var index,admin,token,tokenS,loan,loanS,registry,registryS;
	deployer.deploy(Index)
	.then((value)=>{
		return Index.deployed();
	})
	.then((instance)=>{
		index = instance;
		deployer.deploy(Registry,index.address);
		deployer.deploy(Token,index.address);
		deployer.deploy(TokenStorage,index.address);
		deployer.deploy(LoanStorage,index.address);
		deployer.deploy(Loan,index.address);
		return deployer.deploy(Admin,index.address);
	})
	.then((value)=>{
		return Admin.deployed()
	})
	.then((instance)=>{
		admin = instance;
		return deployer.deploy(RegistryStorage,index.address,admin.address);
	})
	.then((value)=>{
		return Registry.deployed()
	})
	.then((instance)=>{
		registry = instance;
		return RegistryStorage.deployed();
	})
	.then((instance)=>{
		registryS = instance;
		return Loan.deployed();
	})
	.then((instance)=>{
		loan = instance;
		return LoanStorage.deployed();
	})
	.then((instance)=>{
		loanS = instance;
		return Token.deployed();
	})
	.then((instance)=>{
		token = instance;
		return TokenStorage.deployed();
	})
	.then((instance)=>{
		tokenS = instance;
		index.updateContract('token',token.address);
		index.updateContract('tokenS',tokenS.address);
		index.updateContract('loan',loan.address);
		index.updateContract('loanS',loanS.address);
		index.updateContract('registry',registry.address);
		return index.updateContract('registryS',registryS.address);
	})
	.then((value)=>{
		return index.transferOwnership(admin.address);
	})
	.catch((value)=>{
		//console.log("Done");
	})

}
