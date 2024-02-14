use core::array::ArrayTrait;
use snforge_std::{declare, start_prank, stop_prank, CheatTarget, ContractClassTrait};

use grails::grails::{IGrailsDispatcher, IGrailsDispatcherTrait};
use grails::vault::{IVaultDispatcher, IVaultDispatcherTrait};
use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
use starknet::{ContractAddress, get_block_number, get_block_timestamp, get_contract_address};

fn grailsContract() -> ContractAddress {
    0x02a819b93cc69b45ee5d1a1bfc16954c16f6d35c3873a06c97b95c009bfe502b.try_into().unwrap()
}

fn nauhcner() -> ContractAddress {
    0x48727f0291a251ae941afe91b0a40d65fa45fb3db32dabf1348ccd88391e602.try_into().unwrap()
}

fn deploy() -> IVaultDispatcher {
    let contract = declare('Vault');
    let mut params = ArrayTrait::<felt252>::new();
    grailsContract().serialize(ref params);
    get_contract_address().serialize(ref params);
    let contract_address = contract.deploy(@params).unwrap();
    IVaultDispatcher { contract_address }
}

fn store() -> IVaultDispatcher {
    let vault = deploy();
    start_prank(CheatTarget::All, nauhcner());
    (IGrailsDispatcher{ contract_address: grailsContract() }).setApprovalForAll(vault.contract_address, true);
    vault.store(1);
    stop_prank(CheatTarget::All);
    vault
}

#[test]
#[fork("mainnet")]
fn testRetrieve() {
    let vault = store();
    start_prank(CheatTarget::One(vault.contract_address), nauhcner());
    vault.retrieve(1);
    stop_prank(CheatTarget::One(vault.contract_address));
    start_prank(CheatTarget::All, nauhcner());
    (IGrailsDispatcher{ contract_address: grailsContract() }).setApprovalForAll(vault.contract_address, true);
    vault.store(18);
    vault.store(56);
    vault.store(59);
    stop_prank(CheatTarget::All);
    start_prank(CheatTarget::One(vault.contract_address), nauhcner());
    vault.retrieve(18);
    vault.retrieve(56);
    vault.retrieve(59);
    stop_prank(CheatTarget::One(vault.contract_address));
    let grailsDispatcher = (IGrailsDispatcher{ contract_address: grailsContract() });
    assert(grailsDispatcher.ownerOf(1) == nauhcner(), 'invalid #1 owner');
    assert(grailsDispatcher.ownerOf(18) == nauhcner(), 'invalid #18 owner');
    assert(grailsDispatcher.ownerOf(56) == nauhcner(), 'invalid #56 owner');
    assert(grailsDispatcher.ownerOf(59) == nauhcner(), 'invalid #59 owner');
}

#[test]
#[fork("mainnet")]
#[should_panic(expected: ('Unauthorized', ))]
fn testRetrieveUnauthorized() {
    let vault = store();
    vault.retrieve(1);
}

#[test]
#[fork("mainnet")]
fn testStore() {
    let vault = store();
    assert(vault.ownerOf(1) == nauhcner(), 'invalid owner');
    assert(vault.stored(nauhcner()).len() == 1, 'invalid stored amount');
}

#[test]
#[fork("mainnet")]
fn testStoreMultiple() {
    let vault = store();
    start_prank(CheatTarget::All, nauhcner());
    let grailsDispatcher = (IGrailsDispatcher{ contract_address: grailsContract() });
    grailsDispatcher.setApprovalForAll(vault.contract_address, true);
    vault.store(18);
    vault.store(56);
    vault.store(59);
    stop_prank(CheatTarget::All);
    assert(grailsDispatcher.ownerOf(18) == vault.contract_address, 'invalid #18 owner');
    assert(grailsDispatcher.ownerOf(56) == vault.contract_address, 'invalid #56 owner');
    assert(grailsDispatcher.ownerOf(59) == vault.contract_address, 'invalid #59 owner');
    assert(vault.ownerOf(18) == nauhcner(), 'invalid #18 vault owner');
    assert(vault.ownerOf(56) == nauhcner(), 'invalid #56 vault owner');
    assert(vault.ownerOf(59) == nauhcner(), 'invalid #59 vault owner');
    assert(vault.stored(nauhcner()).len() == 4, 'invalid stored amount');
}
