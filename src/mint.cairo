// class_hash: 0x636f7f16114ce2503f36076c85a8e3399f34cf3cb9f162023c1f64472a0401b

#[starknet::interface]
trait IMint<TState> {
    fn allocation(self: @TState, owner: starknet::ContractAddress) -> u256;
    fn collect(ref self: TState);
    fn mint(ref self: TState, amount: u256) -> bool;
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
    use starknet::{ClassHash, ContractAddress, get_caller_address, get_contract_address};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        allocations: LegacyMap<ContractAddress, u256>,
        grails: ContractAddress,
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
    fn constructor(ref self: ContractState, grails: ContractAddress, owner: ContractAddress) {
        self.ownable.initializer(owner);
        self.grails.write(grails);
        self
            .allocations
            .write(
                0x02851967aa0652dcef0bcc441a5b77d182107a2a7e48a59a31b81626bc4b071a
                    .try_into()
                    .unwrap(),
                1000
            );
        self
            .allocations
            .write(
                0x06e30ddd7b02df2f2ef6725329f7d344caecb50205d178d511427e0f6cd79374
                    .try_into()
                    .unwrap(),
                1000
            );
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
            let dispatcher = ERC20ABIDispatcher {
                contract_address: 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
                    .try_into()
                    .unwrap()
            };
            let balance = dispatcher.balanceOf(get_contract_address());
            dispatcher.transfer(self.ownable.owner(), balance);
        }

        fn mint(ref self: ContractState, amount: u256) -> bool {
            let caller = get_caller_address();
            let allocation = self.allocations.read(caller);
            assert(amount <= allocation, Errors::ALLOCATION_CLAIMED);

            let cost = self.unitPrice() * amount;
            let eth = ERC20ABIDispatcher {
                contract_address: 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
                    .try_into()
                    .unwrap()
            };
            eth.transferFrom(caller, get_contract_address(), cost);
            self.allocations.write(caller, allocation - amount);

            let grails = IGrailsDispatcher { contract_address: self.grails.read() };
            grails.transfer(caller, amount * 1_000_000_000_000_000_000)
        }

        fn unitPrice(self: @ContractState) -> u256 {
            4_0000000000000000 // 0.04 ether
        }
    }
}
