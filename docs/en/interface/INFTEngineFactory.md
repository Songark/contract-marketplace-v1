# INFTEngineFactory



## 1.Contents
Name: Interface for the NFT Marketplace Factory
<p>
<!-- START doctoc -->
<!-- END doctoc -->

## 2.Variables

## 3.Modifiers

## 4.Functions

### createNFTEngine
check more details about parameters and return value, in {NFTEngineFactory::createNFTEngine}
> create a marketplace engine, and then emit the event NFTEngineCreated with created engine's address


*Declaration:*
```solidity
function createNFTEngine(
) external
```




### getNftEngineByAdmin
check more details about parameters and return value, in {NFTEngineFactory::getNftEngineByAdmin}
> get a marketplace engine's address from administrator's address


*Declaration:*
```solidity
function getNftEngineByAdmin(
) external returns
(address)
```




## 5.Events
### NFTEngineCreated

> when a marketplace engine is created successfully, this event would be emit.



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nftEngine` | address | :white_check_mark: | address of new created marketplace engine

## 6.Structs

## 7.Enums
