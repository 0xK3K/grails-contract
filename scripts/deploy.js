import { shortString, uint256 } from 'starknet'
import { deployContract, getClassHashFromFile } from './utils.js'

const DEPLOYER = "0x7820b89733f802708f8eb768b59615f986205adc6eb6917c38b7771f7801caa"
const GRAILS = ""

const deployGrails = async (env) => {
    const classHash = await getClassHashFromFile('grails.cairo')
    const name = shortString.encodeShortString('Grails ERC404')
    const symbol = shortString.encodeShortString('GRAILS')
    const totalNativeSupply = [10_000, 0]
    const calldata = [name, symbol, ...totalNativeSupply, DEPLOYER].join(' ')
    const { contractAddress, transactionHash: deployTx } = await deployContract({ classHash, calldata, env })
    console.log(`Contract deployed at contract_address: ${contractAddress} (tx: ${deployTx})`)
}

const deployMint = async (env) => {
    const classHash = await getClassHashFromFile('mint.cairo')
    const eth = '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7';
    const startTime = 1707706800;
    const calldata = [eth, GRAILS, startTime, DEPLOYER].join(' ')
    const { contractAddress, transactionHash: deployTx } = await deployContract({ classHash, calldata, env })
    console.log(`Contract deployed at contract_address: ${contractAddress} (tx: ${deployTx})`)
}

const main = async () => {
    const [env, contract] = process.argv.slice(2)

    if (env !== 'dev' && env !== 'prod') {
      throw { message: 'env needed' }
    }

    if (!contract) {
        throw { message: 'specify contract' }
    }

    switch (contract) {
        case 'Grails':
            return await deployGrails(env)
        case 'Mint':
            return await deployMint(env)
    }
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
