import { declareContract } from './utils.js'

const declareData = async (env) => {
    const { classHash, transactionHash: declareTx } = await declareContract('Data', env)
    console.log(`Contract declared with class_hash: ${classHash} (tx: ${declareTx})`)
}

const declareEkuboStrategy = async (env) => {
    const { classHash, transactionHash: declareTx } = await declareContract('EkuboStrategy', env)
    console.log(`Contract declared with class_hash: ${classHash} (tx: ${declareTx})`)
}

const declareLPCompoundStrategy = async (env) => {
    const { classHash, transactionHash: declareTx } = await declareContract('LPCompoundStrategy', env)
    console.log(`Contract declared with class_hash: ${classHash} (tx: ${declareTx})`)
}

const declareSithswapStrategy = async (env) => {
    const { classHash, transactionHash: declareTx } = await declareContract('SithswapStrategy', env)
    console.log(`Contract declared with class_hash: ${classHash} (tx: ${declareTx})`)
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
            return await declareData(env)
        case 'ekubo':
            return await declareEkuboStrategy(env)
        case 'lp':
            return await declareLPCompoundStrategy(env)
        case 'sithswap':
            return await declareSithswapStrategy(env)
    }
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
