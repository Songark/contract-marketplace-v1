# CustomNFTMock



## 1.Contents

<!-- START doctoc -->
<!-- END doctoc -->

## 2.Variables

## 3.Modifiers
### onlyMarketplace



*Declaration:*
```solidity
modifier onlyMarketplace
```



## 4.Functions

### constructor



*Declaration:*
```solidity
function constructor(
) public ERC721
```
*Modifiers:*
| Modifier |
| --- |
| ERC721 |




### safeMint



*Declaration:*
```solidity
function safeMint(
) external onlyOwner
```
*Modifiers:*
| Modifier |
| --- |
| onlyOwner |




### setTokenURI



*Declaration:*
```solidity
function setTokenURI(
) public
```




### setMarketplace



*Declaration:*
```solidity
function setMarketplace(
) public onlyOwner
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




### tokenURI



*Declaration:*
```solidity
function tokenURI(
) public returns
(string)
```




## 5.Events

## 6.Structs

## 7.Enums
