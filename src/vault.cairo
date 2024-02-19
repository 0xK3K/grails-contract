// class_hash: 0x434d945df68b4787aa8dfd1c85d9d9e4a50a060ac8eba382983fc3a5040130d

#[starknet::interface]
trait IVault<TState> {
    fn ownerOf(self: @TState, id: u256) -> starknet::ContractAddress;
    fn retrieve(ref self: TState, id: u256);
    fn store(ref self: TState, id: u256);
    fn stored(self: @TState, owner: starknet::ContractAddress) -> Array<u256>;
}

#[starknet::contract]
mod Vault {
    use alexandria_storage::list::{List, ListTrait};
    use grails::grails::{IGrailsDispatcher, IGrailsDispatcherTrait};
    use integer::BoundedU256;
    use openzeppelin::account;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::dual_src5::{DualCaseSRC5, DualCaseSRC5Trait};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc20;
    use openzeppelin::token::erc721::dual721_receiver::{
        DualCaseERC721Receiver, DualCaseERC721ReceiverTrait
    };
    use openzeppelin::token::erc721::interface;
    use openzeppelin::upgrades::{UpgradeableComponent, interface::IUpgradeable};
    use starknet::{
        ClassHash, ContractAddress, contract_address_const, get_caller_address, get_contract_address
    };

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        grails: IGrailsDispatcher,
        ownerOf: LegacyMap<u256, ContractAddress>,
        stored: LegacyMap<(ContractAddress, u32), u256>,
        storedIndex: LegacyMap<u256, u32>,
        storedLength: LegacyMap<ContractAddress, u32>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Retrieve: Retrieve,
        Store: Store,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    struct Retrieve {
        #[key]
        owner: ContractAddress,
        #[key]
        id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Store {
        #[key]
        owner: ContractAddress,
        #[key]
        id: u256
    }

    mod Errors {
        const UNAUTHORIZED: felt252 = 'Unauthorized';
    }

    #[constructor]
    fn constructor(ref self: ContractState, grails: ContractAddress, owner: ContractAddress) {
        self.ownable.initializer(owner);
        self.grails.write(IGrailsDispatcher { contract_address: grails });
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    impl Vault of super::IVault<ContractState> {
        fn ownerOf(self: @ContractState, id: u256) -> ContractAddress {
            self.ownerOf.read(id)
        }

        fn retrieve(ref self: ContractState, id: u256) {
            let caller = get_caller_address();
            assert(self.ownerOf.read(id) == caller, Errors::UNAUTHORIZED);

            let length = self.storedLength.read(caller) - 1;
            let updatedId = self.stored.read((caller, length));
            if (updatedId != id) {
                let updatedIndex = self.storedIndex.read(id);
                self.stored.write((caller, updatedIndex), updatedId);
                self.storedIndex.write(updatedId, updatedIndex);
            }
            self.storedLength.write(caller, length);

            let grails = self.grails.read();
            grails.transferFrom(get_contract_address(), caller, id);
            self.emit(Retrieve { owner: caller, id });
        }

        fn store(ref self: ContractState, id: u256) {
            let caller = get_caller_address();
            let grails = self.grails.read();
            grails.transferFrom(caller, get_contract_address(), id);

            let length = self.storedLength.read(caller);
            self.stored.write((caller, length), id);
            self.storedIndex.write(id, length);
            self.storedLength.write(caller, length + 1);
            self.ownerOf.write(id, caller);

            self.emit(Store { owner: caller, id });
        }

        fn stored(self: @ContractState, owner: ContractAddress) -> Array<u256> {
            let mut stored = ArrayTrait::<u256>::new();
            let mut k = 0;
            let length = self.storedLength.read(owner).into();
            while k < length {
                stored.append(self.stored.read((owner, k)));
                k += 1;
            };
            stored
        }
    }
}
