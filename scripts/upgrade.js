import { getClassHashFromFile, upgradeContract } from './utils.js'

const CONTRACT = 'ekuboStrategy.cairo'
const CONTRACT_ADDRESS = '0x03703e0e79e9e0ec01e858ac00dd3502c4d658b5f4ce719294972b6e9f5c6898'

const upgrade = async (env) => {
    const classHash = await getClassHashFromFile(CONTRACT)
    const contractAddress = CONTRACT_ADDRESS
    const transactionHash = await upgradeContract({ classHash, contractAddress, env })
    console.log(`Upgraded contract ${contractAddress} (tx: ${transactionHash})`)
}

const main = async () => {
    const [env] = process.argv.slice(2)

    if (env !== 'dev' && env !== 'prod') {
      throw { message: 'env needed' }
    }

    await upgrade(env)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
