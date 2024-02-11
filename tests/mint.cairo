use core::traits::TryInto;
use snforge_std::{declare, start_prank, stop_prank, start_warp, CheatTarget, ContractClassTrait};

use core::debug::PrintTrait;
use grails::grails::{IGrailsDispatcher, IGrailsDispatcherTrait};
use grails::mint::{IMintDispatcher, IMintDispatcherTrait};
use integer::BoundedU256;
use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
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

fn ethDispatcher() -> ERC20ABIDispatcher {
    ERC20ABIDispatcher { contract_address: eth() }
}

fn deploy() -> (IGrailsDispatcher, IMintDispatcher) {
    let grails = IGrailsDispatcher {
        contract_address: 0x42b03ae37c7a9fb79e21664d9372b632a683c878b020b72aa5af6bbebac2121
            .try_into()
            .unwrap()
    };

    let contract = declare('Mint');
    let mut params = ArrayTrait::<felt252>::new();
    eth().serialize(ref params);
    grails.serialize(ref params);
    1707706800_u64.serialize(ref params); // monday 12th
    get_contract_address().serialize(ref params);
    let mint = contract.deploy(@params).unwrap();

    (grails, IMintDispatcher { contract_address: mint })
}

#[test]
#[fork("goerli")]
fn constructor() {
    let (_, mint) = deploy();
    assert(mint.startTime() == 1707696000_u64, 'invalid start time');
}

//#[test]
//#[fork("goerli")]
//#[should_panic(expected: ('Allocation claimed', ))]
fn mint() {
    let (grails, mint) = deploy();
    grails.setWhitelist(mint.contract_address, true);
    grails.transfer(mint.contract_address, 1000_000000000000000000);
    assert(
        grails.erc20BalanceOf(mint.contract_address) == 1000_000000000000000000,
        'invalid mint erc20 balance'
    );
    assert(grails.erc721BalanceOf(mint.contract_address) == 0, 'invalid mint erc721 balance');
    //start_warp(CheatTarget::All, mint.startTime());
    start_prank(CheatTarget::All, alice());
    ethDispatcher().approve(mint.contract_address, BoundedU256::max());
    mint.mint();
    stop_prank(CheatTarget::All);
}

#[test]
#[fork("goerli")]
fn mintWithAllocation() {
    let (grails, mint) = deploy();
    mint.seedAllocations();
    grails.setWhitelist(mint.contract_address, true);
    grails.transfer(mint.contract_address, 1000_000000000000000000);
    assert(
        grails.erc20BalanceOf(mint.contract_address) == 1000_000000000000000000,
        'invalid mint erc20 balance'
    );
    assert(grails.erc721BalanceOf(mint.contract_address) == 0, 'invalid mint erc721 balance');
    start_prank(CheatTarget::All, alice());
    ethDispatcher().approve(mint.contract_address, BoundedU256::max());
    mint.mint();
    stop_prank(CheatTarget::All);
    assert(mint.allocation(alice()) == 0, 'invalid alice allocation');
}

#[test]
#[fork("goerli")]
#[should_panic(expected: ('Mint not started',))]
fn mintPanicNotStarted() {
    let (grails, mint) = deploy();
    grails.setWhitelist(mint.contract_address, true);
    grails.transfer(mint.contract_address, 1000_000000000000000000);
    start_prank(CheatTarget::All, alice());
    ethDispatcher().approve(mint.contract_address, BoundedU256::max());
    mint.mint();
    stop_prank(CheatTarget::All);
}

#[test]
#[fork("goerli")]
fn seedAllocations() {
    let (_, mint) = deploy();
    mint.seedAllocations();
    assert(mint.allocation(alice()) == 1, 'invalid alice allocation');
    assert(mint.allocation(bob()) == 1, 'invalid bob allocation');
}

#[test]
#[fork("goerli")]
#[should_panic(expected: ('Caller is not the owner',))]
fn seedAllocationsPanic() {
    let (_, mint) = deploy();
    start_prank(CheatTarget::All, alice());
    mint.seedAllocations();
    stop_prank(CheatTarget::All);
}
