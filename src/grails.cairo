// class_hash: 0x6bb314eb252b756bf5dc8e0bb3d94db30cb0fba59ea5f31c3818c075e88256

#[starknet::interface]
trait IGrails<TState> {
    fn allowance(
        self: @TState, owner: starknet::ContractAddress, spender: starknet::ContractAddress
    ) -> u256;
    fn approve(ref self: TState, spender: starknet::ContractAddress, amountOrId: u256) -> bool;
    fn balance_of(self: @TState, account: starknet::ContractAddress) -> u256;
    fn balanceOf(self: @TState, account: starknet::ContractAddress) -> u256;
    fn baseTokenURI(self: @TState) -> Array<felt252>;
    fn decimals(self: @TState) -> u8;
    fn erc20BalanceOf(self: @TState, account: starknet::ContractAddress) -> u256;
    fn erc20TotalSupply(self: @TState) -> u256;
    fn erc721TokensBankedInQueue(self: @TState) -> u256;
    fn erc721BalanceOf(self: @TState, account: starknet::ContractAddress) -> u256;
    fn erc721TotalSupply(self: @TState) -> u256;
    fn getApproved(self: @TState, tokenId: u256) -> starknet::ContractAddress;
    fn isApprovedForAll(
        self: @TState, owner: starknet::ContractAddress, operator: starknet::ContractAddress
    ) -> bool;
    fn owned(self: @TState, owner: starknet::ContractAddress) -> Array<u256>;
    fn ownerOf(self: @TState, id: u256) -> starknet::ContractAddress;
    fn name(self: @TState) -> felt252;
    fn safe_transfer_from(
        ref self: TState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        amount_or_id: u256,
        data: Span<felt252>
    );
    fn safeTransferFrom(
        ref self: TState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        amountOrId: u256,
        data: Span<felt252>
    );
    fn setApprovalForAll(ref self: TState, operator: starknet::ContractAddress, approved: bool);
    fn setTokenURI(ref self: TState, baseTokenURI: ByteArray);
    fn setWhitelist(ref self: TState, target: starknet::ContractAddress, state: bool);
    fn symbol(self: @TState) -> felt252;
    fn token_uri(self: @TState, token_id: u256) -> Array<felt252>;
    fn tokenURI(self: @TState, tokenId: u256) -> Array<felt252>;
    fn total_supply(self: @TState) -> u256;
    fn totalSupply(self: @TState) -> u256;
    fn transfer(ref self: TState, to: starknet::ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        amount_or_id: u256
    ) -> bool;
    fn transferFrom(
        ref self: TState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        amountOrId: u256
    ) -> bool;
    fn units(self: @TState) -> u256;
    fn whitelist(self: @TState, address: starknet::ContractAddress) -> bool;
}

#[starknet::contract]
mod Grails {
    use grails::grails::IGrails;
    use core::byte_array::ByteArrayTrait;
    use core::to_byte_array::FormatAsByteArray;
    use alexandria_storage::list::{List, ListTrait};
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
    use starknet::{ClassHash, ContractAddress, contract_address_const, get_caller_address};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5CamelImpl = SRC5Component::SRC5CamelImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        allowance: LegacyMap<(ContractAddress, ContractAddress), u256>,
        balances: LegacyMap<ContractAddress, u256>,
        baseTokenURI: ByteArray,
        getApproved: LegacyMap<u256, ContractAddress>,
        isApprovedForAll: LegacyMap<(ContractAddress, ContractAddress), bool>,
        minted: u256,
        name: felt252,
        owned: LegacyMap<(ContractAddress, u32), u256>,
        ownedIndex: LegacyMap<u256, u32>,
        ownedLength: LegacyMap<ContractAddress, u32>,
        ownerOf: LegacyMap<u256, ContractAddress>,
        storedERC721Ids: List<u256>,
        symbol: felt252,
        totalSupply: u256,
        whitelist: LegacyMap<ContractAddress, bool>,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ApprovalForAll: ApprovalForAll,
        Approval: Approval,
        Transfer: Transfer,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
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
    struct Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        spender: ContractAddress,
        amountOrId: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        amountOrId: u256,
    }

    mod Errors {
        const ALREADY_EXISTS: felt252 = 'Already exists';
        const INVALID_OPERATOR: felt252 = 'Invalid operator';
        const INVALID_RECIPIENT: felt252 = 'Invalid recipient';
        const INVALID_SENDER: felt252 = 'Invalid sender';
        const NOT_FOUND: felt252 = 'Not found';
        const SAFE_TRANSFER_FAILED: felt252 = 'Safe transfer failed';
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
        self.ownable.initializer(owner);
        self.name.write(name);
        self.symbol.write(symbol);
        self.whitelist.write(owner, true);
        InternalImpl::_mintERC20(ref self, owner, totalNativeSupply * self.units(), false);
        let storedERC721IdsAddress = self.storedERC721Ids.address();
        self.storedERC721Ids.write(ListTrait::<u256>::new(0, storedERC721IdsAddress));
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
                let id = amountOrId;
                let owner = self.ownerOf.read(id);
                assert(
                    caller == owner || self.isApprovedForAll.read((owner, caller)),
                    Errors::UNAUTHORIZED
                );
                self.getApproved.write(id, spender);
                self.emit(Approval { owner, spender, amountOrId: id });
            } else {
                let amount = amountOrId;
                self.allowance.write((caller, spender), amount);
                self.emit(Approval { owner: caller, spender, amountOrId: amount });
            }

            true
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            assert(!account.is_zero(), Errors::NOT_FOUND);
            self.balances.read(account)
        }

        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            assert(!account.is_zero(), Errors::NOT_FOUND);
            self.balances.read(account)
        }

        fn baseTokenURI(self: @ContractState) -> Array<felt252> {
            array![
                0x697066733a2f2f62616679626569637a77697a78346e723462356a6c66376e,
                0x687865726e77706464697a367a347965736e7364696270646d623273796f78,
                0x676661712f
            ]
        }

        fn decimals(self: @ContractState) -> u8 {
            18
        }

        fn erc20BalanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.balanceOf(account)
        }

        fn erc20TotalSupply(self: @ContractState) -> u256 {
            self.totalSupply.read()
        }

        fn erc721BalanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.ownedLength.read(account).into()
        }

        fn erc721TokensBankedInQueue(self: @ContractState) -> u256 {
            self.storedERC721Ids.read().len().into()
        }

        fn erc721TotalSupply(self: @ContractState) -> u256 {
            self.minted.read()
        }

        fn getApproved(self: @ContractState, tokenId: u256) -> ContractAddress {
            self.getApproved.read(tokenId)
        }

        fn isApprovedForAll(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.isApprovedForAll.read((owner, operator))
        }

        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        fn owned(self: @ContractState, owner: ContractAddress) -> Array<u256> {
            let mut owned = ArrayTrait::<u256>::new();
            let mut k = 0;
            let length = self.ownedLength.read(owner).into();
            while k < length {
                owned.append(self.owned.read((owner, k)));
                k += 1;
            };
            owned
        }

        fn ownerOf(self: @ContractState, id: u256) -> ContractAddress {
            let owner = self.ownerOf.read(id);
            assert(id > 0 && id <= self.minted.read() && owner.is_non_zero(), Errors::NOT_FOUND);
            owner
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            amount_or_id: u256,
            data: Span<felt252>
        ) {
            self.transferFrom(from, to, amount_or_id);
            assert(
                InternalImpl::_check_on_erc721_received(from, to, amount_or_id, data),
                Errors::SAFE_TRANSFER_FAILED
            );
        }

        fn safeTransferFrom(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            amountOrId: u256,
            data: Span<felt252>
        ) {
            self.transferFrom(from, to, amountOrId);
            assert(
                InternalImpl::_check_on_erc721_received(from, to, amountOrId, data),
                Errors::SAFE_TRANSFER_FAILED
            );
        }

        fn setApprovalForAll(ref self: ContractState, operator: ContractAddress, approved: bool) {
            assert(operator.is_non_zero(), Errors::INVALID_OPERATOR);
            let caller = get_caller_address();
            self.isApprovedForAll.write((caller, operator), approved);
            self.emit(ApprovalForAll { owner: caller, operator, approved });
        }

        fn setTokenURI(ref self: ContractState, baseTokenURI: ByteArray) {
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

        fn token_uri(self: @ContractState, token_id: u256) -> Array<felt252> {
            let s = token_id.format_as_byte_array(10_u256.try_into().unwrap());
            let mut a = ArrayTrait::<felt252>::new();
            s.serialize(ref a);
            array![
                0x697066733a2f2f62616679626569637a77697a78346e723462356a6c66376e,
                0x687865726e77706464697a367a347965736e7364696270646d623273796f78,
                0x676661712f,
                *a.at(1),
                0x2e6a736f6e
            ]
        }

        fn tokenURI(self: @ContractState, tokenId: u256) -> Array<felt252> {
            let s = tokenId.format_as_byte_array(10_u256.try_into().unwrap());
            let mut a = ArrayTrait::<felt252>::new();
            s.serialize(ref a);
            array![
                0x697066733a2f2f62616679626569637a77697a78346e723462356a6c66376e,
                0x687865726e77706464697a367a347965736e7364696270646d623273796f78,
                0x676661712f,
                *a.at(1),
                0x2e6a736f6e
            ]
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.totalSupply.read()
        }

        fn totalSupply(self: @ContractState) -> u256 {
            self.totalSupply.read()
        }

        fn transfer(ref self: ContractState, to: ContractAddress, amount: u256) -> bool {
            assert(to.is_non_zero(), Errors::INVALID_RECIPIENT);
            InternalImpl::_transferERC20WithERC721(ref self, get_caller_address(), to, amount)
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, amount_or_id: u256
        ) -> bool {
            self.transferFrom(from, to, amount_or_id)
        }

        fn transferFrom(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, amountOrId: u256
        ) -> bool {
            assert(from.is_non_zero(), Errors::INVALID_SENDER);
            assert(to.is_non_zero(), Errors::INVALID_RECIPIENT);

            let caller = get_caller_address();
            if (amountOrId <= self.minted.read()) {
                let id = amountOrId;
                assert(from == self.ownerOf.read(id), Errors::UNAUTHORIZED);
                assert(
                    caller == from
                        || self.isApprovedForAll.read((from, caller))
                        || caller == self.getApproved.read(id),
                    Errors::UNAUTHORIZED
                );

                InternalImpl::_transferERC20(ref self, from, to, self.units());
                InternalImpl::_transferERC721(ref self, from, to, id);
            } else {
                let amount = amountOrId;
                let allowed = self.allowance.read((from, caller));
                if (allowed != BoundedU256::max()) {
                    self.allowance.write((from, caller), allowed - amount);
                }

                InternalImpl::_transferERC20WithERC721(ref self, from, to, amount);
            }

            true
        }

        fn units(self: @ContractState) -> u256 {
            1_000_000_000_000_000_000
        }

        fn whitelist(self: @ContractState, address: ContractAddress) -> bool {
            self.whitelist.read(address)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _check_on_erc721_received(
            from: ContractAddress, to: ContractAddress, token_id: u256, data: Span<felt252>
        ) -> bool {
            if (DualCaseSRC5 { contract_address: to }
                .supports_interface(interface::IERC721_RECEIVER_ID)) {
                DualCaseERC721Receiver { contract_address: to }
                    .on_erc721_received(
                        get_caller_address(), from, token_id, data
                    ) == interface::IERC721_RECEIVER_ID
            } else {
                DualCaseSRC5 { contract_address: to }
                    .supports_interface(account::interface::ISRC6_ID)
            }
        }

        fn _mintERC20(
            ref self: ContractState,
            to: ContractAddress,
            amount: u256,
            mintCorrespondingERC721s: bool
        ) {
            assert(to.is_non_zero(), Errors::INVALID_RECIPIENT);
            InternalImpl::_transferERC20(ref self, contract_address_const::<0>(), to, amount);

            if (mintCorrespondingERC721s) {
                let nftsToRetrieveOrMint = amount / self.units();
                let mut k = 0;
                while k < nftsToRetrieveOrMint {
                    InternalImpl::_retrieveOrMintERC721(ref self, to);
                    k += 1;
                }
            }
        }

        fn _retrieveOrMintERC721(ref self: ContractState, to: ContractAddress) {
            assert(to.is_non_zero(), Errors::INVALID_RECIPIENT);
            let mut id = 0;

            if (self.storedERC721Ids.read().is_empty()) {
                let minted = self.minted.read() + 1;
                id = minted;
                self.minted.write(minted);
            } else {
                let mut list = self.storedERC721Ids.read();
                id = list.pop_front().unwrap().unwrap();
            }

            let erc721Owner = self.ownerOf.read(id);
            assert(erc721Owner.is_zero(), Errors::ALREADY_EXISTS);
            InternalImpl::_transferERC721(ref self, erc721Owner, to, id);
        }

        fn _transferERC20(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256
        ) {
            if (from.is_zero()) {
                self.totalSupply.write(self.totalSupply.read() + amount);
            } else {
                self.balances.write(from, self.balances.read(from) - amount);
            }

            self.balances.write(to, self.balances.read(to) + amount);
            self.emit(Transfer { from, to, amountOrId: amount });
        }

        fn _transferERC721(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, id: u256
        ) {
            if (from.is_non_zero()) {
                self.getApproved.write(id, contract_address_const::<0>());
                let length = self.ownedLength.read(from) - 1;
                let updatedId = self.owned.read((from, length));
                if (updatedId != id) {
                    let updatedIndex = self.ownedIndex.read(id);
                    self.owned.write((from, updatedIndex), updatedId);
                    self.ownedIndex.write(updatedId, updatedIndex);
                }
                self.ownedLength.write(from, length);
            }

            if (to.is_non_zero()) {
                let length = self.ownedLength.read(to);
                self.owned.write((to, length), id);
                self.ownedIndex.write(id, length);
                self.ownedLength.write(to, length + 1);
                self.ownerOf.write(id, to);
            } else {
                self.ownerOf.write(id, contract_address_const::<0>());
            }

            self.emit(Transfer { from, to, amountOrId: id });
        }

        fn _transferERC20WithERC721(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256
        ) -> bool {
            let erc20BalanceOfSenderBefore = self.erc20BalanceOf(from);
            let erc20BalanceOfReceiverBefore = self.erc20BalanceOf(to);
            InternalImpl::_transferERC20(ref self, from, to, amount);

            let units = self.units();

            let isFromWhitelisted = self.whitelist.read(from);
            let isToWhitelisted = self.whitelist.read(to);
            if (isFromWhitelisted && !isToWhitelisted) {
                let tokensToRetrieveOrMint = (self.balances.read(to) / units)
                    - (erc20BalanceOfReceiverBefore / units);
                let mut k = 0;
                while k < tokensToRetrieveOrMint {
                    InternalImpl::_retrieveOrMintERC721(ref self, to);
                    k += 1;
                }
            } else if (!isFromWhitelisted && isToWhitelisted) {
                let tokensToWithdrawAndStore = (erc20BalanceOfSenderBefore / units)
                    - (self.balances.read(from) / units);
                let mut k = 0;
                while k < tokensToWithdrawAndStore {
                    InternalImpl::_withdrawAndStoreERC721(ref self, from);
                    k += 1;
                }
            } else if (!isFromWhitelisted && !isToWhitelisted) {
                let nftsToTransfer = amount / units;
                let mut k = 0;
                while k < nftsToTransfer {
                    let id = self.owned.read((from, self.ownedLength.read(from) - 1));
                    InternalImpl::_transferERC721(ref self, from, to, id);
                    k += 1;
                };

                let fractionalAmount = amount % units;
                if ((erc20BalanceOfSenderBefore - fractionalAmount)
                    / units < erc20BalanceOfSenderBefore
                    / units) {
                    InternalImpl::_withdrawAndStoreERC721(ref self, from);
                }

                if ((erc20BalanceOfReceiverBefore + fractionalAmount)
                    / units > erc20BalanceOfReceiverBefore
                    / units) {
                    InternalImpl::_retrieveOrMintERC721(ref self, to);
                }
            }

            true
        }

        fn _withdrawAndStoreERC721(ref self: ContractState, from: ContractAddress) {
            assert(from.is_non_zero(), Errors::INVALID_SENDER);

            let id = self.owned.read((from, self.ownedLength.read(from) - 1));
            InternalImpl::_transferERC721(ref self, from, contract_address_const::<0>(), id);

            let mut list = self.storedERC721Ids.read();
            list.append(id).expect('syscallresult error');
        }
    }
}
