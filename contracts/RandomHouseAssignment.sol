// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
*@author @Jonas-sebera
* This contract will be responsible 
* for randomly assigning Hogwarts houses to users. 
*/

import { HogwartsNFT } from "./HogwartsNFT.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract RandomHouseAssignment is VRFConsumerBaseV2 {

    //state variables
    HogwartsNFT public nftContract; //an instance of HogwartsNFT contract
    VRFCoordinatorV2Interface private i_vrfCoordinator;
    uint64 private i_subscriptionId;
    bytes32 private i_keyHash;
    uint32 private i_callbackGasLimit;
    
    mapping(uint256 => address) private s_requestIdToSender;
    mapping(address => string) private s_nameToSender;
    
    //Emit event when requestedNft
    /**
    * it includes the requestId and requester 
    * address as indexed parameters for easy retrieval. 
    */

    event NftRequested(uint256 indexed requestId, address requester);
    
    //Initialize contract with various parameters
    constructor(
        address _nftContract,
        address vrfCoordinatorV2Address,
        uint64 subId,
        bytes32 keyHash,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2Address) {
        nftContract = HogwartsNFT(_nftContract);
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2Address);
        i_subscriptionId = subId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
    }
     
     /**
     * this allows a user to request a Hogwarts-themed NFT. */
    function requestNFT(string memory name) public {
        //inittiate a equest to the Chainlink VRF service to generate random words
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            3,//number of random words to request
            i_callbackGasLimit,
            1 //userProvidedSeed
        );

        s_requestIdToSender[requestId] = msg.sender;
        s_nameToSender[msg.sender] = name;

        //emit event when nft is requested
        emit NftRequested(requestId, msg.sender);
    }


    /**
    * This function, fulfillRandomWords, 
    * is an internal override that handles 
    * the fulfillment of random words 
    * generated by Chainlink's VRF service. 
    */
    
    function fulFillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address nftOwner = s_requestIdToSender[requestId];
        string memory name = s_nameToSender[nftOwner];
        uint256 house = randomWords[0] % 4;
        nftContract.mintNFT(nftOwner, house, name);
    }





}