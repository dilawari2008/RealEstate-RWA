# RealEstate RWA

## Overview

The contract treats an RWA (like real estate) as an NFT.
Creates N tokens to fractionalize the NFT.
Starts over with handing out the tokens to the NFT owner after locking up the NFT in the contract.
The NFT owner can then sell their tokens on the open market or on the contract itself.
Buyers need to pay a 2% fee to the contract.
The contract allows for rent payment.
The contract represents a DAO of the token holders.
The DAO can vote on the following:
- Rent payment
60% Vote Share is required for decisions to be made.
The token holders get share of the rent payment.
The NFT gets unlocked when the DAO decides with a 100% vote.

There are 3 contracts:
- RWA NFT
- RWA Token
- RWA DAO

The RWA contract is the main contract that handles the RWA NFT.
The RWA Token contract is the contract that handles the tokenization of the RWA.
The RWA DAO contract is the contract that handles the DAO of the token holders.