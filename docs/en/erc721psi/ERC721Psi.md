# ERC721Psi

> ERC721Psi is an ERC721 compilant implementation designed for scalable and gas-efficient 
on-chain application with built-in randomized metadata generation. 
Inspired by AzukiZen's awesome ERC721A, ERC721Psi also provides batch minting at a fixed gas cost.

## 1.Contents
Name: Updated contract of ERC721 for saving gas cost
<p>
<!-- START doctoc -->
<!-- END doctoc -->

## 2.Variables

| Arg | Type | Description |
| --- | --- | --- |
_owners | mapping(uint256 => address) | 
_minted | uint256 | 

## 3.Modifiers

## 4.Functions

### constructor

> Initializes the contract by setting a `name` and a `symbol` to the token collection.

*Declaration:*
```solidity
function constructor(
) public
```




### supportsInterface

> See {IERC165-supportsInterface}.

*Declaration:*
```solidity
function supportsInterface(
) public returns
(bool)
```




### balanceOf

> See {IERC721-balanceOf}.

*Declaration:*
```solidity
function balanceOf(
) public returns
(uint256)
```




### ownerOf

> See {IERC721-ownerOf}.

*Declaration:*
```solidity
function ownerOf(
) public returns
(address)
```




### _ownerAndBatchHeadOf



*Declaration:*
```solidity
function _ownerAndBatchHeadOf(
) internal returns
(address owner, uint256 tokenIdBatchHead)
```




### name

> See {IERC721Metadata-name}.

*Declaration:*
```solidity
function name(
) public returns
(string)
```




### symbol

> See {IERC721Metadata-symbol}.

*Declaration:*
```solidity
function symbol(
) public returns
(string)
```




### tokenURI

> See {IERC721Metadata-tokenURI}.

*Declaration:*
```solidity
function tokenURI(
) public returns
(string)
```




### _baseURI

> Base URI for computing {tokenURI}. If set, the resulting URI for each
token will be the concatenation of the `baseURI` and the `tokenId`. Empty
by default, can be overriden in child contracts.

*Declaration:*
```solidity
function _baseURI(
) internal returns
(string)
```




### approve

> See {IERC721-approve}.

*Declaration:*
```solidity
function approve(
) public
```




### getApproved

> See {IERC721-getApproved}.

*Declaration:*
```solidity
function getApproved(
) public returns
(address)
```




### setApprovalForAll

> See {IERC721-setApprovalForAll}.

*Declaration:*
```solidity
function setApprovalForAll(
) public
```




### isApprovedForAll

> See {IERC721-isApprovedForAll}.

*Declaration:*
```solidity
function isApprovedForAll(
) public returns
(bool)
```




### transferFrom

> See {IERC721-transferFrom}.

*Declaration:*
```solidity
function transferFrom(
) public
```




### safeTransferFrom

> See {IERC721-safeTransferFrom}.

*Declaration:*
```solidity
function safeTransferFrom(
) public
```




### safeTransferFrom

> See {IERC721-safeTransferFrom}.

*Declaration:*
```solidity
function safeTransferFrom(
) public
```




### _safeTransfer

> Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
are aware of the ERC721 protocol to prevent tokens from being forever locked.

`_data` is additional data, it has no specified format and it is sent in call to `to`.

This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
implement alternative mechanisms to perform token transfer, such as signature-based.

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `tokenId` token must exist and be owned by `from`.
- If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

Emits a {Transfer} event.

*Declaration:*
```solidity
function _safeTransfer(
) internal
```




### _exists

> Returns whether `tokenId` exists.

Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.

Tokens start existing when they are minted (`_mint`).

*Declaration:*
```solidity
function _exists(
) internal returns
(bool)
```




### _isApprovedOrOwner

> Returns whether `spender` is allowed to manage `tokenId`.

Requirements:

- `tokenId` must exist.

*Declaration:*
```solidity
function _isApprovedOrOwner(
) internal returns
(bool)
```




### _safeMint

> Safely mints `quantity` tokens and transfers them to `to`.

Requirements:

- If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
- `quantity` must be greater than 0.

Emits a {Transfer} event.

*Declaration:*
```solidity
function _safeMint(
) internal
```




### _safeMint



*Declaration:*
```solidity
function _safeMint(
) internal
```




### _mint



*Declaration:*
```solidity
function _mint(
) internal
```




### _transfer

> Transfers `tokenId` from `from` to `to`.
 As opposed to {transferFrom}, this imposes no restrictions on msg.sender.

Requirements:

- `to` cannot be the zero address.
- `tokenId` token must be owned by `from`.

Emits a {Transfer} event.

*Declaration:*
```solidity
function _transfer(
) internal
```




### _approve

> Approve `to` to operate on `tokenId`

Emits a {Approval} event.

*Declaration:*
```solidity
function _approve(
) internal
```




### _startTokenId



*Declaration:*
```solidity
function _startTokenId(
) internal returns
(uint256)
```




### _getBatchHead



*Declaration:*
```solidity
function _getBatchHead(
) internal returns
(uint256 tokenIdBatchHead)
```




### totalSupply

> See {IERC721Enumerable-totalSupply}.

*Declaration:*
```solidity
function totalSupply(
) public returns
(uint256)
```




### tokenByIndex

> See {IERC721Enumerable-tokenByIndex}.

*Declaration:*
```solidity
function tokenByIndex(
) public returns
(uint256)
```




### tokenOfOwnerByIndex

> See {IERC721Enumerable-tokenOfOwnerByIndex}.

*Declaration:*
```solidity
function tokenOfOwnerByIndex(
) public returns
(uint256 tokenId)
```




### _beforeTokenTransfers

> Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.

startTokenId - the first token id to be transferred
quantity - the amount to be transferred

Calling conditions:

- When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
transferred to `to`.
- When `from` is zero, `tokenId` will be minted for `to`.

*Declaration:*
```solidity
function _beforeTokenTransfers(
) internal
```




### _afterTokenTransfers

> Hook that is called after a set of serially-ordered token ids have been transferred. This includes
minting.

startTokenId - the first token id to be transferred
quantity - the amount to be transferred

Calling conditions:

- when `from` and `to` are both non-zero.
- `from` and `to` are never both zero.

*Declaration:*
```solidity
function _afterTokenTransfers(
) internal
```




## 5.Events

## 6.Structs

## 7.Enums
