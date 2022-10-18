// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat")

async function main() {
  const contract = await ethers.getContractFactory(
    "CeloDepositAndWithdrawUpgradeable"
  )
  const contractAddr = await upgrades.deployProxy(contract)
  await contractAddr.deployed()
  console.log("contract deployed at", contractAddr)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})

// 0xacaec1bb810cddf12c2067cb092850922d197135 -- this address
// 0xddde0db54c2c56437b95af530ce18d2a6ca06fdb  -- implementation contract