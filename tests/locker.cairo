use snforge_std::{start_prank, stop_prank, CheatTarget};

use grails::locker::{IGrailsLockerDispatcher, IGrailsLockerDispatcherTrait};
use starknet::{ContractAddress, get_block_number, get_block_timestamp, get_contract_address};

fn nauhcner() -> ContractAddress {
    0x48727f0291a251ae941afe91b0a40d65fa45fb3db32dabf1348ccd88391e602.try_into().unwrap()
}

fn locker() -> IGrailsLockerDispatcher {
    let contract_address = 0x0104ca0f63ca8e5501c7b7e4e618b2e227955ced12c808e274973a9e82681d12.try_into().unwrap();
    IGrailsLockerDispatcher { contract_address }
}

#[test]
#[fork("mainnet")]
fn checkFees() {
    let locker = locker();
    start_prank(CheatTarget::One(locker.contract_address), nauhcner());
    let (a, b) = locker.collectFees(0x5e59f);
    println!("{} {}", a, b);
    let (a, b) = locker.collectFees(0x5eb40);
    println!("{} {}", a, b);
    stop_prank(CheatTarget::One(locker.contract_address));
}
