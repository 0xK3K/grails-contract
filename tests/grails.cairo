use alexandria_storage::list::ListTrait;
use grails::grails::Grails::InternalTrait;
use core::traits::TryInto;
use snforge_std::{declare, start_prank, stop_prank, CheatTarget, ContractClassTrait};

use core::debug::PrintTrait;
use grails::grails::Grails::mintedContractMemberStateTrait;
use grails::grails::Grails::storedERC721IdsContractMemberStateTrait;
use grails::grails::{Grails, IGrails, IGrailsDispatcher, IGrailsDispatcherTrait};
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
    let grails = deploy();
    assert(grails.name() == 'Grails ERC404', 'invalid name');
    assert(grails.symbol() == 'GRAILS', 'invalid symbol');
    assert(grails.erc20TotalSupply() == 10_000_000000000000000000, 'invalid erc20 total supply');
    assert(grails.erc721TotalSupply() == 0, 'invalid erc721 total supply');
    assert(grails.totalSupply() == 10_000_000000000000000000, 'invalid total supply');
    assert(
        grails.balanceOf(get_contract_address()) == 10_000_000000000000000000,
        'invalid owner balance'
    );
}

#[test]
fn multiTransfer() {
    let grails = deploy();
    grails.transfer(alice(), 100_000000000000000000);
    grails.transfer(bob(), 100_000000000000000000);
    let iterations = 100_u256;
    let mut k = 0_u256;
    start_prank(CheatTarget::All, alice());
    while k < iterations {
        grails.transfer(bob(), 1_000000000000000000);
        k += 1;
    };
    stop_prank(CheatTarget::All);
    assert(grails.erc20BalanceOf(alice()) == 0, 'invalid alice erc20 balance');
    assert(grails.erc721BalanceOf(alice()) == 0, 'invalid alice erc721 balance');
    assert(grails.erc20BalanceOf(bob()) == 200_000000000000000000, 'invalid bob erc20 balance');
    assert(grails.erc721BalanceOf(bob()) == 200, 'invalid bob erc721 balance');
    let iterations = 5_u256;
    let mut k = 0_u256;
    start_prank(CheatTarget::All, bob());
    while k < iterations {
        grails.transfer(alice(), 40_000000000000000000);
        k += 1;
    };
    stop_prank(CheatTarget::All);
    assert(grails.erc20BalanceOf(alice()) == 200_000000000000000000, 'invalid alice erc20 balance');
    assert(grails.erc721BalanceOf(alice()) == 200, 'invalid alice erc721 balance');
    assert(grails.erc20BalanceOf(bob()) == 0, 'invalid bob erc20 balance');
    assert(grails.erc721BalanceOf(bob()) == 0, 'invalid bob erc721 balance');
}

#[test]
fn transferFractions() {
    let grails = deploy();
    grails.transfer(alice(), 1_182299000000000000);
    grails.transfer(bob(), 817701000000000000);
    assert(grails.erc20BalanceOf(alice()) == 1_182299000000000000, 'invalid alice erc20 balance');
    assert(grails.erc721BalanceOf(alice()) == 1, 'invalid alice erc721 balance');
    assert(grails.erc20BalanceOf(bob()) == 817701000000000000, 'invalid bob erc20 balance');
    assert(grails.erc721BalanceOf(bob()) == 0, 'invalid bob erc721 balance');
    start_prank(CheatTarget::All, alice());
    grails.transfer(bob(), 1_182299000000000000);
    stop_prank(CheatTarget::All);
    assert(grails.erc20BalanceOf(alice()) == 0, 'invalid alice erc20 balance');
    assert(grails.erc721BalanceOf(alice()) == 0, 'invalid alice erc721 balance');
    assert(grails.erc20BalanceOf(bob()) == 2_000000000000000000, 'invalid bob erc20 balance');
    assert(grails.erc721BalanceOf(bob()) == 2, 'invalid bob erc721 balance');
}

#[test]
fn transfer() {
    let grails = deploy();
    grails.transfer(alice(), 1_000000000000000000);
    assert(grails.balanceOf(alice()) == 1_000000000000000000, 'invalid init balance');
    assert(grails.ownerOf(0x1) == alice(), 'invalid id');
    grails.transfer(alice(), 100_000000000000000000);
    assert(grails.ownerOf(0x64) == alice(), 'invalid id');
    assert(grails.balanceOf(alice()) == 101_000000000000000000, 'invalid total balance');
    start_prank(CheatTarget::All, alice());
    grails.transfer(bob(), 70_000000000000000000);
    stop_prank(CheatTarget::All);
    assert(grails.balanceOf(alice()) == 31_000000000000000000, 'invalid alice balance');
    assert(grails.balanceOf(bob()) == 70_000000000000000000, 'invalid bob balance');
    assert(grails.ownerOf(0x64) == bob(), 'invalid id');
}

#[test]
fn __gas_transfer() {
    let grails = deploy();
    grails.transfer(alice(), 1_000000000000000000);
}

#[test]
fn _mintERC20() {
    let mut state = Grails::contract_state_for_testing();
    state._mintERC20(alice(), 93_000000000000000000, false);
    state._mintERC20(alice(), 7_000000000000000000, true);
    state._mintERC20(bob(), 1_000000000000000000, true);
    assert(state.erc20BalanceOf(alice()) == 100_000000000000000000, 'invalid alice erc20 balance');
    assert(state.erc721BalanceOf(alice()) == 7, 'invalid alice erc721 balance');
    assert(state.erc20BalanceOf(bob()) == 1_000000000000000000, 'invalid bob erc20 balance');
    assert(state.erc721BalanceOf(bob()) == 1, 'invalid bob erc721 balance');
    assert(state.minted.read() == 8, 'invalid minted amount');
}

#[test]
fn __gas__mintERC20() {
    let mut state = Grails::contract_state_for_testing();
    state._mintERC20(alice(), 1_000000000000000000, false);
}

#[test]
fn _retrieveOrMintERC721() {
    let mut state = Grails::contract_state_for_testing();
    state._retrieveOrMintERC721(alice());
    state._retrieveOrMintERC721(alice());
    assert(state.erc721BalanceOf(alice()) == 2, 'invalid alice erc721 balance');
    state._retrieveOrMintERC721(bob());
    assert(state.erc721BalanceOf(bob()) == 1, 'invalid bob erc721 balance');
    assert(state.minted.read() == 3, 'invalid minted amount');
}

#[test]
fn __gas__retrieveOrMintERC721() {
    let mut state = Grails::contract_state_for_testing();
    state._retrieveOrMintERC721(alice());
}

#[test]
fn _transferERC20() {
    let mut state = Grails::contract_state_for_testing();
    state._transferERC20(0x0.try_into().unwrap(), alice(), 6_000000000000000000);
    state._transferERC20(0x0.try_into().unwrap(), bob(), 3_000000000000000000);
    state._mintERC20(get_contract_address(), 10_000000000000000000, false);
    state._transferERC20(get_contract_address(), bob(), 10_000000000000000000);
    assert(state.erc20BalanceOf(alice()) == 6_000000000000000000, 'invalid alice erc20 balance');
    assert(state.erc20BalanceOf(bob()) == 13_000000000000000000, 'invalid bob erc20 balance');
    assert(state.erc20BalanceOf(get_contract_address()) == 0, 'invalid contract erc20 balance');
    assert(state.erc721BalanceOf(alice()) == 0, 'invalid alice erc721 balance');
    assert(state.erc721BalanceOf(bob()) == 0, 'invalid alice erc721 balance');
    assert(state.erc721BalanceOf(get_contract_address()) == 0, 'invalid contract erc721 balance');
}

#[test]
fn __gas__transferERC20() {
    let mut state = Grails::contract_state_for_testing();
    state._transferERC20(0x0.try_into().unwrap(), alice(), 1_000000000000000000);
}

#[test]
fn _transferERC721() {
    let mut state = Grails::contract_state_for_testing();
    state._retrieveOrMintERC721(alice());
    state._transferERC721(alice(), bob(), 1);
    assert(state.ownerOf(1) == bob(), 'invalid owner of 1');
    assert(state.erc20BalanceOf(alice()) == 0, 'invalid alice erc20 balance');
    assert(state.erc20BalanceOf(bob()) == 0, 'invalid bob erc20 balance');
    assert(state.erc721BalanceOf(alice()) == 0, 'invalid alice erc721 balance');
    assert(state.erc721BalanceOf(bob()) == 1, 'invalid bob erc721 balance');
    state._transferERC721(bob(), get_contract_address(), 1);
    assert(state.ownerOf(1) == get_contract_address(), 'invalid owner of 1');
    assert(state.erc721BalanceOf(bob()) == 0, 'invalid bob erc721 balance');
    assert(state.erc20BalanceOf(get_contract_address()) == 0, 'invalid contract erc20 balance');
    assert(state.erc721BalanceOf(get_contract_address()) == 1, 'invalid contract erc721 balance');
}

#[test]
fn __gas__transferERC721() {
    let mut state = Grails::contract_state_for_testing();
    state._transferERC721(0x0.try_into().unwrap(), alice(), 0);
}

#[test]
fn _transferERC20WithERC721() {
    let mut state = Grails::contract_state_for_testing();
    state._mintERC20(get_contract_address(), 20_000000000000000000, true);
    state._transferERC20WithERC721(get_contract_address(), alice(), 10_000000000000000000);
    state._transferERC20WithERC721(get_contract_address(), bob(), 10_000000000000000000);
    assert(state.erc20BalanceOf(alice()) == 10_000000000000000000, 'invalid alice erc20 balance');
    assert(state.erc20BalanceOf(bob()) == 10_000000000000000000, 'invalid bob erc20 balance');
    assert(state.erc20BalanceOf(get_contract_address()) == 0, 'invalid contract erc20 balance');
    assert(state.erc721BalanceOf(alice()) == 10, 'invalid alice erc721 balance');
    assert(state.erc721BalanceOf(bob()) == 10, 'invalid bob erc721 balance');
    assert(state.erc721BalanceOf(get_contract_address()) == 0, 'invalid contract erc721 balance');
}

#[test]
fn _withdrawAndStoreERC721() {
    let mut state = Grails::contract_state_for_testing();
    state._mintERC20(get_contract_address(), 1_000000000000000000, true);
    state._withdrawAndStoreERC721(get_contract_address());
    assert(state.storedERC721Ids.read().len() == 1, 'invalid queue length');
    assert(state.erc721BalanceOf(get_contract_address()) == 0, 'invalid contract erc721 balance');
}

#[test]
fn __gas__withdrawAndStoreERC721() {
    let mut state = Grails::contract_state_for_testing();
    state._mintERC20(get_contract_address(), 1_000000000000000000, true);
    state._withdrawAndStoreERC721(get_contract_address());
}
