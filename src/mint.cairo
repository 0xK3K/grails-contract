// class_hash: 0x380faafb5562b1b746c54ebef1652473e8a62844fa70ef9c8a4f218580173be

#[starknet::interface]
trait IMint<TState> {
    fn allocation(self: @TState, owner: starknet::ContractAddress) -> u256;
    fn collect(ref self: TState);
    fn mint(ref self: TState) -> bool;
    fn seedAllocations(ref self: TState);
    fn startTime(self: @TState) -> u64;
    fn unitPrice(self: @TState) -> u256;
}

#[starknet::contract]
mod Mint {
    use grails::grails::{IGrailsDispatcher, IGrailsDispatcherTrait};
    use openzeppelin::{
        access::ownable::OwnableComponent,
        token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait},
        upgrades::{UpgradeableComponent, interface::IUpgradeable}
    };
    use starknet::{
        ClassHash, ContractAddress, get_block_timestamp, get_caller_address, get_contract_address
    };

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        allocations: LegacyMap<ContractAddress, u256>,
        eth: ContractAddress,
        grails: ContractAddress,
        startTime: u64,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
    }

    mod Errors {
        const ALLOCATION_CLAIMED: felt252 = 'Allocation claimed';
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        eth: ContractAddress,
        grails: ContractAddress,
        startTime: u64,
        owner: ContractAddress
    ) {
        self.ownable.initializer(owner);
        self.eth.write(eth);
        self.grails.write(grails);
        self.startTime.write(startTime);
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    impl Mint of super::IMint<ContractState> {
        fn allocation(self: @ContractState, owner: ContractAddress) -> u256 {
            self.allocations.read(owner)
        }

        fn collect(ref self: ContractState) {
            self.ownable.assert_only_owner();
            let dispatcher = ERC20ABIDispatcher { contract_address: self.eth.read() };
            let balance = dispatcher.balanceOf(get_contract_address());
            dispatcher.transfer(self.ownable.owner(), balance);
        }

        fn mint(ref self: ContractState) -> bool {
            let caller = get_caller_address();
            let timestamp = get_block_timestamp();

            let allocation = self.allocations.read(caller);
            if (allocation > 0) {
                self.allocations.write(caller, allocation - 1);
                let eth = ERC20ABIDispatcher { contract_address: self.eth.read() };
                eth.transferFrom(caller, get_contract_address(), self.unitPrice());
                let grails = IGrailsDispatcher { contract_address: self.grails.read() };
                grails.transfer(caller, 1_000_000_000_000_000_000)
            } else {
                assert(timestamp >= self.startTime.read(), 'Mint not started');
                let eth = ERC20ABIDispatcher { contract_address: self.eth.read() };
                eth.transferFrom(caller, get_contract_address(), self.unitPrice());
                let grails = IGrailsDispatcher { contract_address: self.grails.read() };
                grails.transfer(caller, 1_000_000_000_000_000_000)
            }
        }

        fn seedAllocations(ref self: ContractState) {
            self.ownable.assert_only_owner();
            let addresses = array![
                0x2851967aa0652dcef0bcc441a5b77d182107a2a7e48a59a31b81626bc4b071a,
                0x06e30ddd7b02df2f2ef6725329f7d344caecb50205d178d511427e0f6cd79374
            ];
            let length = addresses.len();
            let mut k = 0;
            while k < length {
                let address = *addresses.at(k);
                self.allocations.write(address.try_into().unwrap(), 100);
                k += 1;
            }
        }

        fn startTime(self: @ContractState) -> u64 {
            self.startTime.read()
        }

        fn unitPrice(self: @ContractState) -> u256 {
            10_000_000_000_000_000 // 0.01 ether
        }
    }
}
