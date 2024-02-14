import { getClassHashFromFile, upgradeContract } from './utils.js'

const upgradeGrails = async (env) => {
    const classHash = await getClassHashFromFile('grails.cairo')
    const contractAddress = '0x02a819b93cc69b45ee5d1a1bfc16954c16f6d35c3873a06c97b95c009bfe502b'
    const transactionHash = await upgradeContract({ classHash, contractAddress, env })
    console.log(`Upgraded contract ${contractAddress} (tx: ${transactionHash})`)
}

const upgradeVault = async (env) => {
    const classHash = await getClassHashFromFile('vault.cairo')
    const contractAddress = '0x9c8f75b75354193db06bd8e7bb1f23b2e8412ffe5482254fbccec8c2f2da2a'
    const transactionHash = await upgradeContract({ classHash, contractAddress, env })
    console.log(`Upgraded contract ${contractAddress} (tx: ${transactionHash})`)
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
            return await upgradeGrails(env)
        case 'Vault':
            return await upgradeVault(env)
    }
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
