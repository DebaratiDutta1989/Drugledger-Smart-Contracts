//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

contract Owned {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not allowed");
        _;
    }
}

contract Registration is Owned{

    mapping(address=>bool) manufacturers;
    mapping(address=>bool) distributors;
    mapping(address=>bool) retailers;
    mapping(address=>bool) healthproviders;

    event ManufacturerRegistered(address manufactuer);
    event DistributorRegistered(address distributor);
    event RetailerRegistered(address retailer);
    event HealthProviderRegistered(address healthProvider);

    function registerManufacturer(address m) public onlyOwner{
    require(!manufacturers[m] && !distributors[m] && !retailers[m] && !healthproviders[m], "Address already used");   
    manufacturers[m]=true;
    emit ManufacturerRegistered(m);
  }
    
    function registerDistributor(address d) public onlyOwner{
    require(!manufacturers[d] && !distributors[d] && !retailers[d] && !healthproviders[d], "Address already used");
    distributors[d]=true;
    emit DistributorRegistered(d);
  }

    function registerRetailer(address r) public onlyOwner{
    require(!manufacturers[r] && !distributors[r] && !retailers[r] && !healthproviders[r], "Address already used");
    retailers[r]=true;
    emit RetailerRegistered(r);
  }
    
  function registerProvider(address p) public onlyOwner{
    require(!manufacturers[p] && !distributors[p] && !retailers[p] && !healthproviders[p], "Address already used");
    healthproviders[p]=true;
    emit HealthProviderRegistered(p);
  }

  function manufacturerExists(address m) public view returns(bool){
    return manufacturers[m];
  }

  function distributorExists(address d) public view returns(bool){
    return distributors[d];
  }

  function retailerExists(address r) public view returns(bool){
    return retailers[r];
  }
    
  function HPExists(address h) public view returns(bool){
    return healthproviders[h];
  }
    
  function isOwner(address payable o) public view returns(bool){
    return (o==owner);
  }
}

contract Deliver is Owned{
    Registration registrationContract;
    uint public contractAddresses;
    enum status{
        Registered,
        Manufactured,
        Distributed,
        Retailed,
        Delivered
    }

    struct product{
      uint productID;
      string factory;
      string name;
      uint price;
      uint expiryDate;
      status productStatus;
    }

    modifier onlyManufacturer{
      require(registrationContract.manufacturerExists(msg.sender), "Sender not authorized.");
      _;
    }

    struct order{
    address manufacturer;
    uint productID;
    uint quantity;
    uint price;
    uint time;
    status orderStatus;
    }
    
    mapping(uint=>order) public contracts;
    mapping(uint=>product) public drugs;
    event ProductRegistered(uint contractAddress, uint productID, string factoryName, string drugName, uint price, uint expiryDate);
    event ProductManufactured (uint contractAddress, uint productID, uint quantity, address manufacturer);
    event ProductDistributed(uint contractAddress, uint amount);
    event ProductRetailed(uint contractAddress, uint amount);
    event ProductDelivered(uint contractAddress, uint amount);
    
    constructor(address registrationAddress) public {
    registrationContract=Registration(registrationAddress);
    contractAddresses=uint(keccak256(abi.encodePacked(msg.sender,block.timestamp,address(this))));
  }
 
  function registerDrug(uint productID, string memory factoryName, string memory drugName, uint price, uint expiryDate) public onlyManufacturer{
    contractAddresses++;
    drugs[contractAddresses]=product(productID, factoryName, drugName, price, expiryDate, status.Registered);
    emit ProductRegistered(contractAddresses, productID, factoryName, drugName, price, expiryDate);
  }

  function newOrder(address manufacturer, uint productID, uint quantity, uint amount) public payable onlyOwner {
    require(contracts[contractAddresses].orderStatus==status.Registered, "Product not available for sale.");
    require(registrationContract.manufacturerExists(manufacturer), "Manufacturer address not recognized.");
    require(contracts[contractAddresses].price<=msg.value, "Not enough fund");
    contracts[contractAddresses]=order(manufacturer,productID,quantity,amount,block.timestamp,status.Manufactured);
    emit ProductManufactured(contractAddresses, productID, quantity, manufacturer);
  }

  function distribute(address manufacturer, address distributor, uint amount) public onlyOwner{
    require(contracts[contractAddresses].orderStatus==status.Manufactured, "Product not available for sale.");
    require(registrationContract.manufacturerExists(manufacturer), "Saler address not recognized.");
    require(registrationContract.distributorExists(distributor), "Buyer address not recognized.");
    contracts[contractAddresses].price=amount;
    contracts[contractAddresses].orderStatus=status.Distributed;
    emit ProductDistributed(contractAddresses, amount);
  }

  function retail(address distributor, address retailer, uint amount) public onlyOwner{
    require(contracts[contractAddresses].orderStatus==status.Distributed, "Product not available for sale.");
    require(registrationContract.distributorExists(distributor), "Saler address not recognized.");
    require(registrationContract.retailerExists(retailer), "Buyer address not recognized.");
    contracts[contractAddresses].price=amount;
    contracts[contractAddresses].orderStatus=status.Retailed;
    emit ProductRetailed(contractAddresses, amount);
  }

  function hprovider(address retailer, address provider, uint amount) public onlyOwner{
    require(contracts[contractAddresses].orderStatus==status.Retailed, "Product not available for sale.");
    require(registrationContract.retailerExists(retailer), "Saler address not recognized.");
    require(registrationContract.HPExists(provider), "Buyer address not recognized.");
    contracts[contractAddresses].price=amount;
    contracts[contractAddresses].orderStatus=status.Delivered;
    emit ProductDelivered(contractAddresses, amount);
  }
}