import { declareContract } from './utils.js'

const main = async () => {
    const [env, contract] = process.argv.slice(2)

    if (env !== 'dev' && env !== 'prod') {
        throw { message: 'env needed' }
    }

    if (!contract) {
        throw { message: 'specify contract' }
    }

    const { classHash, transactionHash: declareTx } = await declareContract(contract, env)
    console.log(`Contract declared with class_hash: ${classHash} (tx: ${declareTx})`)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
