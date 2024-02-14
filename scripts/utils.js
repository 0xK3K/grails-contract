import fs from 'fs'
import { exec } from 'child_process'

export const getClassHashFromFile = async (file) => {
    const path = `/Users/k3k/Projects/grails/contracts/src/${file}`
    const data = fs.readFileSync(path, 'utf-8')
    const firstLine = data.split('\n')[0]
    return firstLine.match(/0x([a-fA-F0-9]+)/)[0]
}

export const declareContract = (contractName, env) => {
    return new Promise(function (resolve, reject) {
        exec(`sncast --profile ${env} declare --package grails --contract-name ${contractName}`, (_, stdout, stderr) => {
            if (stderr) {
                console.log(stderr)
                reject(stderr)
            } else {
                const match = stdout.match(/class_hash: (0x[0-9a-fA-F]+)\ntransaction_hash: (0x[0-9a-fA-F]+)/)
                resolve({ classHash: match[1], transactionHash: match[2] })
            }
        })
    })
}

export const deployContract = ({ classHash, calldata, env }) => {
    let command = `sncast --profile ${env} deploy --class-hash ${classHash}`
    if (calldata) {
        command += ` --constructor-calldata ${calldata}`
    }

    return new Promise(function (resolve, reject) {
        exec(command, (_, stdout, stderr) => {
            if (stderr) {
                console.log(stderr)
                reject(stderr)
            } else {
                const match = stdout.match(/contract_address: (0x[0-9a-fA-F]+)\ntransaction_hash: (0x[0-9a-fA-F]+)/)
                resolve({ contractAddress: match[1], transactionHash: match[2] })
            }
        })
    })
}

export const upgradeContract = ({ classHash, contractAddress, env }) => {
    return new Promise(function (resolve, reject) {
        exec(`sncast --profile ${env} invoke --contract-address ${contractAddress} --function upgrade --calldata ${classHash}`, (_, stdout, stderr) => {
            if (stderr) {
                console.log(stderr)
                reject(stderr)
            } else {
                const match = stdout.match(/command: invoke\ntransaction_hash: (0x[0-9a-fA-F]+)/)
                resolve(match[1])
            }
        })
    })
}
