use snforge_std::{
    declare, start_prank, stop_prank, start_warp, stop_warp, CheatTarget, ContractClassTrait
};

use grails::locker::{Bounds, PoolKey, i129_new};
use grails::locker::{IGrailsLockerDispatcher, IGrailsLockerDispatcherTrait};
use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
use starknet::{ContractAddress, get_block_number, get_block_timestamp, get_contract_address};

fn eth() -> ContractAddress {
    0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7.try_into().unwrap()
}

fn grailsContract() -> ContractAddress {
    0x02a819b93cc69b45ee5d1a1bfc16954c16f6d35c3873a06c97b95c009bfe502b.try_into().unwrap()
}

fn nauhcner() -> ContractAddress {
    0x48727f0291a251ae941afe91b0a40d65fa45fb3db32dabf1348ccd88391e602.try_into().unwrap()
}

fn positionNFT() -> ContractAddress {
    0x07b696af58c967c1b14c9dde0ace001720635a660a8e90c565ea459345318b30.try_into().unwrap()
}

fn nftDispatcher() -> IERC721Dispatcher {
    (IERC721Dispatcher { contract_address: positionNFT() })
}

fn deploy() -> IGrailsLockerDispatcher {
    let contract = declare('GrailsLocker');
    let contract_address = contract.deploy(@ArrayTrait::<felt252>::new()).unwrap();
    IGrailsLockerDispatcher { contract_address }
}

fn lock() -> IGrailsLockerDispatcher {
    let locker = deploy();
    let poolKey = PoolKey {
        token0: grailsContract(),
        token1: eth(),
        fee: 0x028f5c28f5c28f5c28f5c28f5c28f5c2,
        tick_spacing: 0x4d5a,
        extension: 0x0.try_into().unwrap()
    };
    start_prank(CheatTarget::All, nauhcner());
    nftDispatcher().set_approval_for_all(locker.contract_address, true);
    let unlockTimestamp = get_block_timestamp() + 1000;
    locker
        .lock(
            0x05e59f,
            unlockTimestamp,
            poolKey,
            Bounds { lower: i129_new(0x35c894, true), upper: i129_new(0x09108c, true) },
            nauhcner()
        );
    locker
        .lock(
            0x05eb40,
            unlockTimestamp,
            poolKey,
            Bounds { lower: i129_new(0x287d1c, true), upper: i129_new(0x4666ea, false) },
            nauhcner()
        );
    stop_prank(CheatTarget::All);
    locker
}

// #[test]
// #[fork("mainnet")]
fn collectFees() {
    let locker = lock();
    start_prank(CheatTarget::One(locker.contract_address), nauhcner());
    stop_prank(CheatTarget::One(locker.contract_address));
}

// #[test]
// #[fork("mainnet")]
// #[should_panic(expected: ('Unauthorized',))]
fn collectFeesUnauthorized() {
    let locker = lock();
    locker.collectFees(0x05e59f);
    locker.collectFees(0x05eb40);
}

// #[test]
// #[fork("mainnet")]
fn testLock() {
    assert(nftDispatcher().owner_of(0x05e59f) == nauhcner(), 'invalid 0x05e59f initial owner');
    assert(nftDispatcher().owner_of(0x05eb40) == nauhcner(), 'invalid 0x05eb40 initial owner');
    let locker = lock();
    assert(
        nftDispatcher().owner_of(0x05e59f) == locker.contract_address,
        'invalid 0x05e59f final owner'
    );
    assert(
        nftDispatcher().owner_of(0x05eb40) == locker.contract_address,
        'invalid 0x05eb40 final owner'
    );
    assert(locker.operator(0x05e59f) == nauhcner(), 'invalid 0x05e59f operator');
    assert(locker.operator(0x05eb40) == nauhcner(), 'invalid 0x05eb40 operator');
}

// #[test]
// #[fork("mainnet")]
fn transferOperator() {
    let locker = lock();
    start_prank(CheatTarget::All, nauhcner());
    locker.transferOperator(0x05e59f, get_contract_address());
    stop_prank(CheatTarget::All);
    locker.collectFees(0x05e59f);
    locker.transferOperator(0x05e59f, nauhcner());
}

// #[test]
// #[fork("mainnet")]
// #[should_panic(expected: ('Unauthorized',))]
fn transferOperatorUnauthorized() {
    let locker = lock();
    locker.transferOperator(0x05e59f, get_contract_address());
}

// #[test]
// #[fork("mainnet")]
fn unlock() {
    let locker = lock();
    start_warp(CheatTarget::All, get_block_timestamp() + 1000);
    start_prank(CheatTarget::One(locker.contract_address), nauhcner());
    locker.collectFees(0x05e59f);
    locker.collectFees(0x05eb40);
    locker.unlock(0x05e59f);
    locker.unlock(0x05eb40);
    stop_prank(CheatTarget::One(locker.contract_address));
    stop_warp(CheatTarget::All);
}

// #[test]
// #[fork("mainnet")]
// #[should_panic(expected: ('Position is still locked',))]
fn unlockStillLocked() {
    let locker = lock();
    start_prank(CheatTarget::One(locker.contract_address), nauhcner());
    locker.unlock(0x05e59f);
    stop_prank(CheatTarget::One(locker.contract_address));
}
