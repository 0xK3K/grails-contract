import { shortString } from 'starknet'
import { deployContract, getClassHashFromFile } from './utils.js'

const DEPLOYER = "0xdc01d249345f08ec0267647980e08848e1fc491d1ea648aae09ac076d27c7e"
const GRAILS = "0x2a819b93cc69b45ee5d1a1bfc16954c16f6d35c3873a06c97b95c009bfe502b"

const deployGrails = async (env) => {
    const classHash = await getClassHashFromFile('grails.cairo')
    const name = shortString.encodeShortString('Grails ERC404')
    const symbol = shortString.encodeShortString('GRAILS')
    const totalNativeSupply = [10_000, 0]
    const calldata = [name, symbol, ...totalNativeSupply, DEPLOYER].join(' ')
    const { contractAddress, transactionHash: deployTx } = await deployContract({ classHash, calldata, env })
    console.log(`Contract deployed at contract_address: ${contractAddress} (tx: ${deployTx})`)
}

const deployLocker = async (env) => {
    const classHash = await getClassHashFromFile('locker.cairo')
    const { contractAddress, transactionHash: deployTx } = await deployContract({ classHash, env })
    console.log(`Contract deployed at contract_address: ${contractAddress} (tx: ${deployTx})`)
}

const deployVault = async (env) => {
    const classHash = await getClassHashFromFile('vault.cairo')
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
        case 'Locker':
            return await deployLocker(env)
        case 'vault':
            return await deployVault(env)
    }
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
