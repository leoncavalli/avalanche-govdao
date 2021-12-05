const HDWalletProvider = require("@truffle/hdwallet-provider");
const Web3 = require("web3")
const express = require("express")
const app = express()
const http_port = 3006
// `

const Platform = require("./truffle/build/contracts/Platform.json")
const Proposal = require("./truffle/build/contracts/Proposal.json")
var communities
var PlatformContract

const privateKeys = [
  "0x56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027",
  "0x7b4198529994b0dc604278c99d153cfd069d594753d471171a1d102a10438e07",
  "0x15614556be13730e9e8d6eacc1603143e7b96987429df8726384c2ec4502ef6e",
  "0x31b571bf6894a248831ff937bb49f7754509fe93bbd2517c9c73c4144c0e97dc",
  "0x6934bef917e01692b789da754a0eae31a8536eb465e7bff752ea291dad88c675",
  "0xe700bdbdbc279b808b1ec45f8c2370e4616d3a02c336e68d85d4668e08f53cff",
  "0xbbc2865b76ba28016bc2255c7504d000e046ae01934b04c694592a6276988630",
  "0xcdbfd34f687ced8c6968854f8a99ae47712c4f4183b78dcc4a903d1bfe8cbf60",
  "0x86f78c5416151fe3546dece84fda4b4b1e36089f2dbc48496faf3a950f16157c",
  "0x750839e9dbbd2a0910efe40f50b2f3b2f2f59f5580bb4b83bd8c1201cf9a010a",
];

const init = async() => {
  const web3 = new Web3(`http://127.0.0.1:9650/ext/bc/C/rpc`);

  PlatformContract = new web3.eth.Contract(Platform.abi, "0x9Cbe4e4d620CD504F0490B6BD46752D9A1Ccc752")  

  PlatformContract.events.e1155Created()
    .on("data", function(event) {
      console.log(event.returnValues)
    })
    .on("error", console.error);
}
// 0xBdC0050c6b6Ec6e42129a65176E4b98E4689660c

// init()

app.set('view engine', 'ejs')
app.use("/", express.static("public")); 

app.use(express.json()) // for parsing application/json
app.use(express.urlencoded({ extended: true })) // for parsing application/x-www-form-urlencoded

app.get("/", (req, res) => {
  communities = require("./public/db/community.json")
  res.render("index", {communities, Platform, ProposalBuild: Proposal})
})

app.get("/community/:id", (req,res) => {
  communities = require("./public/db/community.json")
  let community = communities[req.params.id]
  res.render("community", {Platform, ProposalBuild: Proposal, community, comId: req.params.id})
})

app.get("/create/:id", (req,res) => {
  res.render("create", {Platform, ProposalBuild: Proposal, comId: req.params.id})
})

app.get("/wallet", (req,res) => {
  res.render("wallet", {Platform, ProposalBuild: Proposal})
})

app.get("/communityDetail/:id", (req,res) => {
  communities = require("./public/db/community.json")
  let community = communities[req.params.id]

  if(community) {
    res.send(JSON.stringify(community))
  } else {
    res.send(JSON.stringify({}))
  }
})

app.get("/proposal/:id", (req,res) => {
  res.render("proposal", {Platform, Proposal, ProposalBuild: Proposal, address: req.params.id})
})

app.listen(http_port, () => {
    console.log(`server is running on port ${http_port}`)
})