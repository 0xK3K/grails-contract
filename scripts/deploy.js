import { shortString } from 'starknet'
import { deployContract, getClassHashFromFile } from './utils.js'

const DEPLOYER = "0x7820b89733f802708f8eb768b59615f986205adc6eb6917c38b7771f7801caa"

const deployData = async (env) => {
    const classHash = await getClassHashFromFile('data.cairo')
    const { contractAddress, transactionHash: deployTx } = await deployContract({ classHash, env })
    console.log(`Contract deployed at contract_address: ${contractAddress} (tx: ${deployTx})`)
}

const deployEkuboStrategy = async (env) => {
    const classHash = await getClassHashFromFile('ekuboStrategy.cairo')
    const owner = DEPLOYER
    const manager = '0x06e30ddd7b02df2f2ef6725329f7d344caecb50205d178d511427e0f6cd79374'
    const name = shortString.encodeShortString('USDC/WBTC Auto')
    const symbol = shortString.encodeShortString('STG-S USDC/WBTC Auto')
    const pool = '0x073fa8432bf59f8ed535f29acfd89a7020758bda7be509e00dfed8a9fde12ddc'
    const poolKey = [
        '0x005a643907b9a4bc6a55e9069c4fd5fd1f5c79a22470690f75556c4736e34426',
        '0x012d537dc323c439dc65c976fad242d5610d27cfb5f31689a0a319b8be7f3d56',
        '0x20c49ba5e353f80000000000000000',
        '0x3e8',
        '0x0'
    ]
    const bounds = ['0xa9308', '0x0', '0xcb5e8', '0x0']
    const calldata = [owner, manager, name, symbol, pool, ...poolKey, ...bounds].join(' ')
    const { contractAddress, transactionHash: deployTx } = await deployContract({ classHash, calldata, env })
    console.log(`Contract deployed at contract_address: ${contractAddress} (tx: ${deployTx})`)
}

const deployLPCompoundStrategy = async (env) => {
    const classHash = await getClassHashFromFile('lpCompoundStrategy.cairo')
    const owner = DEPLOYER
    const name = shortString.encodeShortString('USDC/WBTC VLP #2')
    const symbol = shortString.encodeShortString('STG-S USDC/WBTC VLP #2')
    const asset = "0x02ca3d758eafe0b2dcffe44a020e0a9f40361727150515cf0a39aec6d17f8e20"
    const calldata = [owner, name, symbol, asset].join(' ')
    const { contractAddress, transactionHash: deployTx } = await deployContract({ classHash, calldata, env })
    console.log(`Contract deployed at contract_address: ${contractAddress} (tx: ${deployTx})`)
}

const deploySithswapStrategy = async (env) => {
    const classHash = await getClassHashFromFile('sithswapStrategy.cairo')
    const owner = DEPLOYER
    const name = shortString.encodeShortString('USDC/WBTC VLP #2')
    const symbol = shortString.encodeShortString('STG-S USDC/WBTC VLP #2')
    const asset = "0x02ca3d758eafe0b2dcffe44a020e0a9f40361727150515cf0a39aec6d17f8e20"
    const calldata = [owner, name, symbol, asset].join(' ')
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
        case 'data':
            return await deployData(env)
        case 'ekubo':
            return await deployEkuboStrategy(env)
        case 'lp':
            return await deployLPCompoundStrategy(env)
        case 'sithswap':
            return await deploySithswapStrategy(env)
    }
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
