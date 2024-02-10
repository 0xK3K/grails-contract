#[starknet::interface]
trait IGrails<TState> {
    fn allowance(
        self: @TState, owner: starknet::ContractAddress, spender: starknet::ContractAddress
    ) -> u256;
    fn approve(ref self: TState, spender: starknet::ContractAddress, amountOrId: u256) -> bool;
    fn balance_of(self: @TState, account: starknet::ContractAddress) -> u256;
    fn balanceOf(self: @TState, account: starknet::ContractAddress) -> u256;
    fn baseTokenURI(self: @TState) -> felt252;
    fn decimals(self: @TState) -> u8;
    fn getApproved(self: @TState, amount: u256) -> starknet::ContractAddress;
    fn isApprovedForAll(
        self: @TState, owner: starknet::ContractAddress, spender: starknet::ContractAddress
    ) -> bool;
    fn minted(self: @TState) -> u256;
    fn name(self: @TState) -> felt252;
    fn owned(self: @TState, owner: starknet::ContractAddress) -> Array<u256>;
    fn ownerOf(self: @TState, id: u256) -> starknet::ContractAddress;
    fn setApprovalForAll(ref self: TState, operator: starknet::ContractAddress, approved: bool);
    fn setDataURI(ref self: TState, dataURI: felt252);
    fn setTokenURI(ref self: TState, baseTokenURI: felt252);
    fn setWhitelist(ref self: TState, target: starknet::ContractAddress, state: bool);
    fn symbol(self: @TState) -> felt252;
    fn tokenURI(self: @TState, id: u256) -> felt252;
    fn total_supply(self: @TState) -> u256;
    fn totalSupply(self: @TState) -> u256;
    fn transfer(ref self: TState, to: starknet::ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        amountOrId: u256
    );
    fn transferFrom(
        ref self: TState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        amountOrId: u256
    );
    fn whitelist(self: @TState, address: starknet::ContractAddress) -> bool;
}

#[starknet::contract]
mod Grails {
    use integer::BoundedU256;
    use openzeppelin::{
        access::ownable::OwnableComponent, token::erc20,
        upgrades::{UpgradeableComponent, interface::IUpgradeable}
    };
    use starknet::{ClassHash, ContractAddress, contract_address_const, get_caller_address};
    use starknet::storage_access;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        allowance: LegacyMap<(ContractAddress, ContractAddress), u256>,
        balances: LegacyMap<ContractAddress, u256>,
        baseTokenURI: felt252,
        dataURI: felt252,
        getApproved: LegacyMap<u256, ContractAddress>,
        isApprovedForAll: LegacyMap<(ContractAddress, ContractAddress), bool>,
        minted: u256,
        name: felt252,
        owned: LegacyMap<(ContractAddress, usize), u256>,
        ownedIndex: LegacyMap<u256, usize>,
        ownedLength: LegacyMap<ContractAddress, usize>,
        ownerOf: LegacyMap<u256, ContractAddress>,
        symbol: felt252,
        totalSupply: u256,
        whitelist: LegacyMap<ContractAddress, bool>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Approval: Approval,
        ApprovalForAll: ApprovalForAll,
        ERC20Transfer: ERC20Transfer,
        ERC721Approval: ERC721Approval,
        Transfer: Transfer,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        spender: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        #[key]
        owner: ContractAddress,
        #[key]
        operator: ContractAddress,
        approved: bool,
    }

    #[derive(Drop, starknet::Event)]
    struct ERC20Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct ERC721Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        spender: ContractAddress,
        id: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        id: u256,
    }

    mod Errors {
        const ALREADY_EXISTS: felt252 = 'Already exists';
        const INVALID_ACCOUNT: felt252 = 'Invalid account';
        const INVALID_RECIPIENT: felt252 = 'Invalid recipient';
        const INVALID_SENDER: felt252 = 'Invalid sender';
        const UNSAFE_RECIPIENT: felt252 = 'Unsafe recipient';
        const UNAUTHORIZED: felt252 = 'Unauthorized caller';
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        totalNativeSupply: u256,
        owner: ContractAddress
    ) {
        self.name.write(name);
        self.ownable.initializer(owner);
        self.symbol.write(symbol);
        let totalSupply = totalNativeSupply * InternalImpl::_getUnit();
        self.totalSupply.write(totalSupply);
        self.balances.write(owner, totalSupply);
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    impl Grails of super::IGrails<ContractState> {
        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.allowance.read((owner, spender))
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amountOrId: u256) -> bool {
            let caller = get_caller_address();
            if (amountOrId <= self.minted.read() && amountOrId > 0) {
                let owner = self.ownerOf.read(amountOrId);
                assert(
                    caller == owner && self.isApprovedForAll.read((owner, caller)),
                    Errors::UNAUTHORIZED
                );
                self.getApproved.write(amountOrId, spender);
                self.emit(Approval { owner, spender, amount: amountOrId });
            } else {
                self.allowance.write((caller, spender), amountOrId);
                self.emit(Approval { owner: caller, spender, amount: amountOrId });
            }

            true
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            assert(!account.is_zero(), Errors::INVALID_ACCOUNT);
            self.balances.read(account)
        }

        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            assert(!account.is_zero(), Errors::INVALID_ACCOUNT);
            self.balances.read(account)
        }

        fn baseTokenURI(self: @ContractState) -> felt252 {
            self.baseTokenURI.read()
        }

        fn decimals(self: @ContractState) -> u8 {
            18
        }

        fn getApproved(self: @ContractState, amount: u256) -> ContractAddress {
            self.getApproved.read(amount)
        }

        fn isApprovedForAll(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> bool {
            self.isApprovedForAll.read((owner, spender))
        }

        fn minted(self: @ContractState) -> u256 {
            self.minted.read()
        }

        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        fn owned(self: @ContractState, owner: ContractAddress) -> Array<u256> {
            let length = self.ownedLength.read(owner);
            let mut owned = ArrayTrait::<u256>::new();
            let mut k = 0;
            while k < length {
                owned.append(self.owned.read((owner, k)));
                k += 1;
            };
            owned
        }

        fn ownerOf(self: @ContractState, id: u256) -> ContractAddress {
            self.ownerOf.read(id)
        }

        fn setApprovalForAll(ref self: ContractState, operator: ContractAddress, approved: bool) {
            let caller = get_caller_address();
            self.isApprovedForAll.write((caller, operator), approved);
            self.emit(ApprovalForAll { owner: caller, operator, approved });
        }

        fn setDataURI(ref self: ContractState, dataURI: felt252) {
            OwnableInternalImpl::assert_only_owner(@self.ownable);
            self.dataURI.write(dataURI);
        }

        fn setTokenURI(ref self: ContractState, baseTokenURI: felt252) {
            OwnableInternalImpl::assert_only_owner(@self.ownable);
            self.baseTokenURI.write(baseTokenURI);
        }

        fn setWhitelist(ref self: ContractState, target: ContractAddress, state: bool) {
            OwnableInternalImpl::assert_only_owner(@self.ownable);
            self.whitelist.write(target, state);
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        fn tokenURI(self: @ContractState, id: u256) -> felt252 {
            ''
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.totalSupply.read()
        }

        fn totalSupply(self: @ContractState) -> u256 {
            self.totalSupply.read()
        }

        fn transfer(ref self: ContractState, to: ContractAddress, amount: u256) -> bool {
            InternalImpl::_transfer(ref self, get_caller_address(), to, amount)
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, amountOrId: u256
        ) {
            self.transferFrom(from, to, amountOrId);
        }

        fn transferFrom(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, amountOrId: u256
        ) {
            let caller = get_caller_address();
            if (amountOrId <= self.minted.read()) {
                assert(from == self.ownerOf.read(amountOrId), Errors::INVALID_SENDER);
                assert(to.is_non_zero(), Errors::INVALID_RECIPIENT);
                assert(
                    caller == from
                        && self.isApprovedForAll.read((from, caller))
                        && caller == self.getApproved.read(amountOrId),
                    Errors::UNAUTHORIZED
                );
                let unit = InternalImpl::_getUnit();
                self.balances.write(from, self.balances.read(from) - unit);
                self.balances.write(to, self.balances.read(to) + unit);
                self.getApproved.write(amountOrId, contract_address_const::<0>());

                // update from owned items
                let index = self.ownedIndex.read(amountOrId);
                let length = self.ownedLength.read(from);
                self.owned.write((from, index), self.owned.read((from, length - 1)));
                self.ownedLength.write(from, length - 1);

                // update to owned items
                let length = self.ownedLength.read(to);
                self.owned.write((to, length), amountOrId);
                self.ownedIndex.write(amountOrId, length);
                self.ownedLength.write(to, length + 1);
                self.ownerOf.write(amountOrId, to);

                self.emit(Transfer { from, to, id: amountOrId });
                self.emit(ERC20Transfer { from, to, amount: InternalImpl::_getUnit() });
            } else {
                let allowed = self.allowance.read((from, caller));
                if (allowed != BoundedU256::max()) {
                    self.allowance.write((from, caller), allowed - amountOrId);
                }

                InternalImpl::_transfer(ref self, from, to, amountOrId);
            }
        }

        fn whitelist(self: @ContractState, address: ContractAddress) -> bool {
            self.whitelist.read(address)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _getUnit() -> u256 {
            1_000_000_000_000_000_000
        }

        fn _transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256
        ) -> bool {
            let unit = InternalImpl::_getUnit();
            let balanceBeforeSender = self.balances.read(from);
            let balanceBeforeReceiver = self.balances.read(to);
            self.balances.write(from, balanceBeforeSender - amount);
            self.balances.write(to, balanceBeforeReceiver + amount);

            // Skip burn for certain addresses to save gas
            if (!self.whitelist.read(from)) {
                assert(from.is_non_zero(), Errors::INVALID_SENDER);

                let tokensToBurn: usize = ((balanceBeforeSender / unit)
                    - (self.balanceOf(from) / unit))
                    .try_into()
                    .unwrap();
                let length = self.ownedLength.read(from);
                let mut k = 0;
                while k < tokensToBurn {
                    let id: u256 = self.owned.read((from, length - k - 1));
                    self.getApproved.write(id, contract_address_const::<0>());
                    self.ownerOf.write(id, contract_address_const::<0>());
                    self.ownedIndex.write(id, 0);

                    self.emit(Transfer { from, to: contract_address_const::<0>(), id });
                    k += 1;
                };

                self.ownedLength.write(from, length - tokensToBurn);
            }

            // Skip minting for certain addresses to save gas
            if (!self.whitelist.read(to)) {
                assert(to.is_non_zero(), Errors::INVALID_RECIPIENT);

                let tokensToMint: usize = ((self.balanceOf(to) / unit)
                    - (balanceBeforeReceiver / unit))
                    .try_into()
                    .unwrap();
                let length = self.ownedLength.read(to);
                let mut minted = self.minted.read();
                let mut k = 0;
                while k < tokensToMint {
                    minted += 1;
                    let id = minted;
                    assert(self.ownerOf(id).is_zero(), Errors::ALREADY_EXISTS);
                    self.owned.write((from, length + k), id);
                    self.ownedIndex.write(id, length + k);
                    self.ownerOf.write(id, to);

                    self.emit(Transfer { from: contract_address_const::<0>(), to, id });
                    k += 1;
                };

                self.minted.write(minted);
                self.ownedLength.write(to, length + tokensToMint);
            }

            self.emit(ERC20Transfer { from, to, amount });
            true
        }
    }
}
