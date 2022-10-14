# PlayEstatesBrickToken



## 1.Contents

<!-- START doctoc -->
<!-- END doctoc -->

## 2.Variables

| Arg | Type | Description |
| --- | --- | --- |
MINTER_ROLE | bytes32 | 
CONTRACT_ROLE | bytes32 | 
locked | bool | 

## 3.Modifiers

## 4.Functions

### constructor



*Declaration:*
```solidity
function constructor(
) public ERC20
```
*Modifiers:*
| Modifier |
| --- |
| ERC20 |




### mint



*Declaration:*
```solidity
function mint(
) public onlyRole
```
*Modifiers:*
| Modifier |
| --- |
| onlyRole |




### decimals



*Declaration:*
```solidity
function decimals(
) public returns
(uint8)
```




### setGameEngine



*Declaration:*
```solidity
function setGameEngine(
) public onlyRole
```
*Modifiers:*
| Modifier |
| --- |
| onlyRole |




### setMarketplaceEngine



*Declaration:*
```solidity
function setMarketplaceEngine(
) public onlyRole
```
*Modifiers:*
| Modifier |
| --- |
| onlyRole |




### setMintRole



*Declaration:*
```solidity
function setMintRole(
) public onlyRole
```
*Modifiers:*
| Modifier |
| --- |
| onlyRole |




### clearMintRole



*Declaration:*
```solidity
function clearMintRole(
) public onlyRole
```
*Modifiers:*
| Modifier |
| --- |
| onlyRole |




### setLock



*Declaration:*
```solidity
function setLock(
) public onlyRole
```
*Modifiers:*
| Modifier |
| --- |
| onlyRole |




### _beforeTokenTransfer

> Hook that is called before any transfer of tokens. This includes
minting and burning.

Calling conditions:

- when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
will be transferred to `to`.
- when `from` is zero, `amount` tokens will be minted for `to`.
- when `to` is zero, `amount` of ``from``'s tokens will be burned.
- `from` and `to` are never both zero.

To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].

*Declaration:*
```solidity
function _beforeTokenTransfer(
) internal
```




## 5.Events

## 6.Structs

## 7.Enums
