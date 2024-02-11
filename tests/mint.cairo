use core::traits::TryInto;
use snforge_std::{declare, start_prank, stop_prank, CheatTarget, ContractClassTrait};

use core::debug::PrintTrait;
use grails::grails::{IGrailsDispatcher, IGrailsDispatcherTrait};
use grails::mint::{IMintDispatcher, IMintDispatcherTrait};
use starknet::{ContractAddress, get_contract_address, get_block_timestamp};

fn alice() -> ContractAddress {
    0x02851967aa0652dcef0bcc441a5b77d182107a2a7e48a59a31b81626bc4b071a.try_into().unwrap()
}

fn bob() -> ContractAddress {
    0x06e30ddd7b02df2f2ef6725329f7d344caecb50205d178d511427e0f6cd79374.try_into().unwrap()
}

fn eth() -> ContractAddress {
    0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7.try_into().unwrap()
}

fn deploy() -> (IGrailsDispatcher, IMintDispatcher) {
    let contract = declare('Grails');
    let mut params = ArrayTrait::<felt252>::new();
    params.append('Grails ERC404');
    params.append('GRAILS');
    10_000_u256.serialize(ref params);
    get_contract_address().serialize(ref params);
    let grails = contract.deploy(@params).unwrap();

    let contract = declare('Mint');
    let mut params = ArrayTrait::<felt252>::new();
    eth().serialize(ref params);
    grails.serialize(ref params);
    1707696000_u64.serialize(ref params); // monday 12th
    get_contract_address().serialize(ref params);
    let mint = contract.deploy(@params).unwrap();

    (
        IGrailsDispatcher { contract_address: grails },
        IMintDispatcher { contract_address: mint }
    )
}

#[test]
#[fork("goerli")]
fn constructor() {
    let (_, mint) = deploy();
    assert(mint.startTime() == 1707696000_u64, 'invalid start time');
}

#[test]
#[fork("goerli")]
fn seedAllocations() {
    let (grails, mint) = deploy();
    grails.setWhitelist(mint.contract_address, true);
    grails.transfer(alice(), 1_000000000000000000);
    assert(grails.erc20BalanceOf(alice()) == 1_000000000000000000, 'invalid alice erc20 balance');
    assert(grails.erc721BalanceOf(alice()) == 1, 'invalid alice erc721 balance');
}
