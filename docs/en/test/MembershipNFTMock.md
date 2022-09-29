# MembershipNFTMock



## 1.Contents

<!-- START doctoc -->
<!-- END doctoc -->

## 2.Variables

| Arg | Type | Description |
| --- | --- | --- |
SUPPLY_PER_TYPE | uint256 | 
tierImageURI | string | 
tierAnimationURL | string | 
typeNames | string[] | 

## 3.Modifiers
### validTokenType



*Declaration:*
```solidity
modifier validTokenType
```



## 4.Functions

### constructor



*Declaration:*
```solidity
function constructor(
) public ERC721Psi
```
*Modifiers:*
| Modifier |
| --- |
| ERC721Psi |




### mint



*Declaration:*
```solidity
function mint(
) external onlyOwner validTokenType
```
*Modifiers:*
| Modifier |
| --- |
| onlyOwner |
| validTokenType |




### burn



*Declaration:*
```solidity
function burn(
) external onlyOwner
```
*Modifiers:*
| Modifier |
| --- |
| onlyOwner |




### setImageURI



*Declaration:*
```solidity
function setImageURI(
) public onlyOwner
```
*Modifiers:*
| Modifier |
| --- |
| onlyOwner |




### setAnimationURI



*Declaration:*
```solidity
function setAnimationURI(
) public onlyOwner
```
*Modifiers:*
| Modifier |
| --- |
| onlyOwner |




### tokenURI



*Declaration:*
```solidity
function tokenURI(
) public returns
(string)
```




### totalSupply



*Declaration:*
```solidity
function totalSupply(
) public returns
(uint256)
```




### getMintedPerType



*Declaration:*
```solidity
function getMintedPerType(
) public onlyOwner returns
(uint256)
```
*Modifiers:*
| Modifier |
| --- |
| onlyOwner |




### _burn



*Declaration:*
```solidity
function _burn(
) internal
```




### _burned



*Declaration:*
```solidity
function _burned(
) internal returns
(uint256 burned)
```




### _exists



*Declaration:*
```solidity
function _exists(
) internal returns
(bool)
```




## 5.Events

## 6.Structs
### `TokenMeta`
uint256 tokenId
enum MembershipNFTMock.TokenType tokenType

## 7.Enums
### `TokenType`


