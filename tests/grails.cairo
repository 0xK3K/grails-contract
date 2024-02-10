use snforge_std::{declare, start_prank, stop_prank, CheatTarget, ContractClassTrait};

use grails::grails::{IGrailsDispatcher, IGrailsDispatcherTrait};
use starknet::{ContractAddress, get_contract_address};

fn alice() -> ContractAddress {
    0x02851967aa0652dcef0bcc441a5b77d182107a2a7e48a59a31b81626bc4b071a.try_into().unwrap()
}

fn bob() -> ContractAddress {
    0x06e30ddd7b02df2f2ef6725329f7d344caecb50205d178d511427e0f6cd79374.try_into().unwrap()
}

fn deploy() -> IGrailsDispatcher {
    let contract = declare('Grails');
    let mut params = ArrayTrait::<felt252>::new();
    params.append('Grails ERC404');
    params.append('GRAILS');
    10_000_u256.serialize(ref params);
    get_contract_address().serialize(ref params);
    let contract_address = contract.deploy(@params).unwrap();
    IGrailsDispatcher { contract_address }
}

#[test]
fn constructor() {
    let dispatcher = deploy();
    assert(dispatcher.name() == 'Grails ERC404', 'invalid name');
    assert(dispatcher.symbol() == 'GRAILS', 'invalid symbol');
    assert(
        dispatcher.erc20TotalSupply() == 10_000_000000000000000000, 'invalid erc20 total supply'
    );
    assert(dispatcher.erc721TotalSupply() == 0, 'invalid erc721 total supply');
    assert(dispatcher.totalSupply() == 10_000_000000000000000000, 'invalid total supply');
    assert(
        dispatcher.balanceOf(get_contract_address()) == 10_000_000000000000000000,
        'invalid owner balance'
    );
}

#[test]
fn erc20Transfer() {
    let dispatcher = deploy();
    dispatcher.setWhitelist(get_contract_address(), true);
    dispatcher.transfer(alice(), 1_000000000000000000);
    assert(dispatcher.balanceOf(alice()) == 1_000000000000000000, 'invalid init balance');
    dispatcher.transfer(alice(), 100_000000000000000000);
    assert(dispatcher.balanceOf(alice()) == 101_000000000000000000, 'invalid total balance');
    start_prank(CheatTarget::All, alice());
    dispatcher.transfer(bob(), 70_000000000000000000);
    stop_prank(CheatTarget::All);
    assert(dispatcher.balanceOf(alice()) == 31_000000000000000000, 'invalid alice balance');
    assert(dispatcher.balanceOf(bob()) == 70_000000000000000000, 'invalid bob balance');
}

#[test]
fn erc721Transfer() {
    let dispatcher = deploy();
    dispatcher.setWhitelist(get_contract_address(), true);
    dispatcher.transfer(alice(), 1_000000000000000000);
    assert(dispatcher.balanceOf(alice()) == 1_000000000000000000, 'invalid balance');
    assert(dispatcher.ownerOf(0x1) == alice(), 'invalid id');
    dispatcher.transfer(alice(), 100_000000000000000000);
    assert(dispatcher.balanceOf(alice()) == 101_000000000000000000, 'invalid balance');
    assert(dispatcher.owned(alice()).len() == 101, 'invalid owned length');
    assert(dispatcher.ownerOf(0x64) == alice(), 'invalid id');
}
