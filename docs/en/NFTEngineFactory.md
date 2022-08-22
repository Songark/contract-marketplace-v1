# NFTEngineFactory

> NFTEngineFactory is used to create marketplace engines with different administrators.

## 1.Contents
Name: NFT Marketplace Engine Factory for PlayEstates
<p>
<!-- START doctoc -->
<!-- END doctoc -->

## 2.Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| nftEngines | mapping(address => address) |

## 3.Modifiers

## 4.Functions

### createNFTEngine
Inherit from INFTEngineFactory

> create a marketplace engine, and then emit the event NFTEngineCreated with created engine's address


*Declaration:*
```solidity
function createNFTEngine(
address admin,
address treasury
) external
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`admin` | address | address of administrator who can manage the created marketplace engine
|`treasury` | address | address of treasury for getting fee


### upgradeNFTEngine



*Declaration:*
```solidity
function upgradeNFTEngine(
) external
```




### getNftEngineByAdmin
Inherit from INFTEngineFactory

> get a marketplace engine's address from administrator's address


*Declaration:*
```solidity
function getNftEngineByAdmin(
address admin
) external returns
(address)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`admin` | address | address of administrator who can manage the created marketplace engine

*Returns:*
| Arg | Description |
| --- | --- |
|`nftEngine` | marketplace engine's address owned by admin

## 5.Events
