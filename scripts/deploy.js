import { shortString, uint256 } from 'starknet'
import { deployContract, getClassHashFromFile } from './utils.js'

const DEPLOYER = "0x7820b89733f802708f8eb768b59615f986205adc6eb6917c38b7771f7801caa"
const GRAILS = "0x10b0c9068e2c65e60ca03391ec744f20bb44efdcba009783648a176df2282f6"

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
    const calldata = [GRAILS, DEPLOYER].join(' ')
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
