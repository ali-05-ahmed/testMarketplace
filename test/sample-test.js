const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFT", function () {
  let Auction
  let auction

  let NftMarketplace
  let nftMarketplace

  let Nft;
  let nft

  let [_, person1, person2] = [1, 1, 1]


  it("Should deploy NFT , Auction and Marketplace contracts ", async function () {
    [_, person1, person2] = await ethers.getSigners()

    Auction = await ethers.getContractFactory("Auction");
    auction = await Auction.deploy(person2.address);
    await auction.deployed();

    NftMarketplace = await ethers.getContractFactory("NftMarketplace");
    nftMarketplace = await upgrades.deployProxy(NftMarketplace, [auction.address], { initializer: 'initialize' });
    await nftMarketplace.deployed();

    Nft = await ethers.getContractFactory("Nft");
    nft = await Nft.deploy(nftMarketplace.address);
    await nft.deployed();

  });
  it("Should create two nfts ", async function () {
    let setNftTx = await nft.createToken("jjghhj");

    // wait until the transaction is mined
    await setNftTx.wait();

    setNftTx = await nft.connect(person1).createToken("saddsasda");

    // wait until the transaction is mined
    await setNftTx.wait();
    // console.log(await greeter.ownerOf(1))
    expect(await nft.ownerOf(1)).to.equal(_.address);
    expect(await nft.ownerOf(2)).to.equal(person1.address);
    let total = await nft.totalSupply();
    total = await ethers.BigNumber.from(total).toString()
    console.log(total)
    expect(total).to.equal('2')
    console.log(await nft.getNftDetails(1).owners);
    console.log(await nft.tokenURI(1))
    //console.log(await ethers.BigNumber.from(Promise.resolve(nft.totalSupply())))
    //  console.log(await ethers.BigNumber.from(nft.totalSupply()))

  });
  it("Should create one Market item and start auction  ", async function () {
    const createMTTx = await nftMarketplace.createMarketItem(
      nft.address,
      1,
      10,
      true,
      60);

    // wait until the transaction is mined
    await createMTTx.wait();

    expect(await nft.ownerOf(1)).to.equal(nftMarketplace.address);
    expect(await auction.getSeller(1, nft.address)).to.equal(_.address);
    let timeleft = await auction.auctionTimeLeft(1, nft.address)
    timeleft = await ethers.BigNumber.from(timeleft).toString()
    console.log(timeleft)
    console.log('before');
    //  await new Promise(resolve => setTimeout(resolve, 10000)); // 3 sec

    console.log('after');

  });
  it("Should create one Market item without auction  ", async function () {
    const createMTTx = await nftMarketplace.connect(person1).createMarketItem(
      nft.address,
      2,
      10,
      false,
      60);

    // wait until the transaction is mined
    await createMTTx.wait();

    expect(await nft.ownerOf(2)).to.equal(nftMarketplace.address);

  });


  it("Should buy one Market item   ", async function () {
    //let _value = await ethers.utils.parseUnits('10', 'wei')
    let _value = await nftMarketplace.connect(person2).getNftPrice(1)
    _value = _value.toString()
    console.log("wei :", _value.toString())
    const saleMTTx = await nftMarketplace.connect(person2).createMarketSale(
      nft.address,
      2, { value: _value });
    const balance = await person1.getBalance();
    console.log(balance.toString())
    // wait until the transaction is mined
    await saleMTTx.wait();



  });

});
