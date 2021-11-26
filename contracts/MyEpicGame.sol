// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// Helper we wrote to encode in Base64
import "./libraries/Base64.sol";

import "hardhat/console.sol";

// Our contract inherits from ERC721, which is the standard NFT contract!
contract MyEpicGame is ERC721, VRFConsumerBase {
    struct CharacterAttributes {
        uint256 characterIndex;
        string name;
        string imageURI;
        uint256 hp;
        uint256 hpMod;
        uint256 maxHp;
        uint256 attackDamage;
        uint256 attackDamageMod;
        uint256 criticalChance;
    }

    // The tokenId is the NFTs unique identifier, it's just a number that goes
    // 0, 1, 2, 3, etc.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    CharacterAttributes[] defaultCharacters;

    // We create a mapping from the nft's tokenId => that NFTs attributes.
    mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

    // Array of all minted nfts
    // CharacterAttributes[] public allMintedCharacterAttributes;

    //Array of all addresses with NFT
    address[] public nftHolderAddresses;

    mapping(bytes32 => address) chainlinkTransactions;

    struct BigBoss {
        string name;
        string imageURI;
        uint256 hp;
        uint256 maxHp;
        uint256 attackDamage;
    }

    BigBoss public bigBoss;

    // A mapping from an address => the NFTs tokenId. Gives me an ez way
    // to store the owner of the NFT and reference it later.
    mapping(address => uint256) public nftHolders;

    // Chainlink variables
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    event CharacterNFTMinted(
        address sender,
        uint256 tokenId,
        uint256 characterIndex
    );
    event AttackComplete(uint256 newBossHp, uint256 newPlayerHp);

    constructor(
        string[] memory characterNames,
        string[] memory characterImageURIs,
        uint256[] memory characterHp,
        uint256[] memory characterHpMod,
        uint256[] memory characterAttackDmg,
        uint256[] memory characterAttackDmgMod,
        uint256[] memory characterCriticalChance,
        string memory bossName, // These new variables would be passed in via run.js or deploy.js.
        string memory bossImageURI,
        uint256 bossHp,
        uint256 bossAttackDamage
    )
        // Below, you can also see I added some special identifier symbols for our NFT.
        // This is the name and symbol for our token, ex Ethereum and ETH. I just call mine
        // Heroes and HERO. Remember, an NFT is just a token!

        ERC721("jelkfjlseo3o49u3roiw3", "woir3")
        // Chainlink constructor hardcoded to Rinkeby
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B,
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709
        )
    {
        // ERC721("Don't Hug Me I'm Scared", "DHMIS") Replace for production

        //Chainlink variables hardcoded for Rinkeby
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18; //0.1 Link;

        // Initialize the boss. Save it to our global "bigBoss" state variable.
        bigBoss = BigBoss({
            name: bossName,
            imageURI: bossImageURI,
            hp: bossHp,
            maxHp: bossHp,
            attackDamage: bossAttackDamage
        });

        console.log(
            "Done initializing boss %s w/ HP %s, img %s",
            bigBoss.name,
            bigBoss.hp,
            bigBoss.imageURI
        );
        for (uint256 i = 0; i < characterNames.length; i += 1) {
            defaultCharacters.push(
                CharacterAttributes({
                    characterIndex: i,
                    name: characterNames[i],
                    imageURI: characterImageURIs[i],
                    hp: characterHp[i],
                    hpMod: characterHpMod[i],
                    maxHp: characterHp[i],
                    attackDamage: characterAttackDmg[i],
                    attackDamageMod: characterAttackDmgMod[i],
                    criticalChance: characterCriticalChance[i]
                })
            );

            CharacterAttributes memory c = defaultCharacters[i];

            // Hardhat's use of console.log() allows up to 4 parameters in any order of following types: uint, string, bool, address
            console.log(
                "Done initializing %s w/ HP %s, img %s",
                c.name,
                c.hp,
                c.imageURI
            );
        }

        // I increment tokenIds here so that my first NFT has an ID of 1.
        // More on this in the lesson!
        _tokenIds.increment();
    }

    // Users would be able to hit this function and get their NFT based on the
    // characterId they send in!
    function mintCharacterNFT(uint256 _characterIndex) external {
        // Get current tokenId (starts at 1 since we incremented in the constructor).
        uint256 newItemId = _tokenIds.current();

        // The magical function! Assigns the tokenId to the caller's wallet address.
        _safeMint(msg.sender, newItemId);
        uint256 randomNumber = (uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        ) % 100) + 1;

        //Adjust character traits using random number
        uint256 _hp = defaultCharacters[_characterIndex].hp +
            (defaultCharacters[_characterIndex].hpMod * randomNumber) /
            100;
        uint256 _attackDamage = defaultCharacters[_characterIndex]
            .attackDamage +
            (defaultCharacters[_characterIndex].attackDamageMod *
                randomNumber) /
            100;
        // We map the tokenId => their character attributes. More on this in
        // the lesson below.
        nftHolderAttributes[newItemId] = CharacterAttributes({
            characterIndex: _characterIndex,
            name: defaultCharacters[_characterIndex].name,
            imageURI: defaultCharacters[_characterIndex].imageURI,
            hp: _hp,
            hpMod: defaultCharacters[_characterIndex].hpMod,
            maxHp: defaultCharacters[_characterIndex].maxHp,
            attackDamage: _attackDamage,
            attackDamageMod: defaultCharacters[_characterIndex].attackDamageMod,
            criticalChance: defaultCharacters[_characterIndex].criticalChance
        });
        console.log(
            "hp mod: %s, attack mod: %s, random number %s",
            nftHolderAttributes[newItemId].hpMod,
            nftHolderAttributes[newItemId].attackDamageMod,
            randomNumber
        );

        nftHolderAddresses.push(msg.sender);

        console.log(
            "Minted NFT w/ tokenId %s and characterIndex %s",
            newItemId,
            _characterIndex
        );

        // Keep an easy way to see who owns what NFT.
        nftHolders[msg.sender] = newItemId;

        // Increment the tokenId for the next person that uses it.
        _tokenIds.increment();

        emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        CharacterAttributes memory charAttributes = nftHolderAttributes[
            _tokenId
        ];

        string memory strHp = Strings.toString(charAttributes.hp);
        string memory strMaxHp = Strings.toString(charAttributes.maxHp);
        string memory strAttackDamage = Strings.toString(
            charAttributes.attackDamage
        );
        string memory strCriticalChance = Strings.toString(
            charAttributes.criticalChance
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        charAttributes.name,
                        " -- NFT #: ",
                        Strings.toString(_tokenId),
                        '", "description": "An epic NFT", "image": "ipfs://',
                        charAttributes.imageURI,
                        '", "attributes": [ { "trait_type": "Health Points", "value": ',
                        strHp,
                        ', "max_value":',
                        strMaxHp,
                        '}, { "trait_type": "Attack Damage", "value": ',
                        strAttackDamage,
                        '}, { "trait_type": "Critical Chance", "value": ',
                        strCriticalChance,
                        "} ]}"
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function attackBoss() public {
        // Get the state of the player's NFT.
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[
            nftTokenIdOfPlayer
        ];
        uint256 randomNumber = (uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        ) % 100) + 1;

        // uint256 randomNumber = (_randomNumber % 100) + 1;
        console.log(
            "The player's critical chance is %s and the random number returned was %s",
            player.criticalChance,
            randomNumber
        );
        uint256 criticalHit = randomNumber < player.criticalChance ? 2 : 1;
        console.log(
            "\nPlayer w/ character %s about to attack. Has %s HP and %s AD",
            player.name,
            player.hp,
            player.attackDamage
        );
        console.log(
            "Boss %s has %s HP and %s AD",
            bigBoss.name,
            bigBoss.hp,
            bigBoss.attackDamage
        );
        // Make sure the player has more than 0 HP.
        require(player.hp > 0, "Error: character must have HP to attack boss.");

        // Make sure the boss has more than 0 HP.
        require(bigBoss.hp > 0, "Error: boss must have HP to attack boss.");

        // Allow player to attack boss.
        if (bigBoss.hp < player.attackDamage * criticalHit) {
            bigBoss.hp = 0;
        } else {
            bigBoss.hp = bigBoss.hp - player.attackDamage * criticalHit;
        }
        // Allow boss to attack player.
        if (player.hp < bigBoss.attackDamage) {
            player.hp = 0;
        } else {
            player.hp = player.hp - bigBoss.attackDamage;
        }

        // Console for ease.
        string memory playerAttackMessage = criticalHit > 1
            ? "Player attacked boss. Critical Hit! New boss hp: %s"
            : "Player attacked boss. New boss hp: %s";
        console.log(playerAttackMessage, bigBoss.hp);
        console.log("Boss attacked player. New player hp: %s\n", player.hp);

        emit AttackComplete(bigBoss.hp, player.hp);
    }

    function checkIfUserHasNFT()
        public
        view
        returns (CharacterAttributes memory)
    {
        // Get the tokenId of the user's character NFT
        uint256 userNftTokenId = nftHolders[msg.sender];
        // If the user has a tokenId in the map, return their character.
        if (userNftTokenId > 0) {
            return nftHolderAttributes[userNftTokenId];
        }
        // Else, return an empty character.
        else {
            CharacterAttributes memory emptyStruct;
            return emptyStruct;
        }
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        // attackBoss(_atkAddress, randomness);
    }

    // Get functions
    function getAllDefaultCharacters()
        public
        view
        returns (CharacterAttributes[] memory)
    {
        return defaultCharacters;
    }

    function getBigBoss() public view returns (BigBoss memory) {
        return bigBoss;
    }

    function getAllNftHolderAddresses() public view returns (address[] memory) {
        return nftHolderAddresses;
    }

    function getOneTokenByAddress(address _address)
        public
        view
        returns (CharacterAttributes memory)
    {
        uint256 userNftTokenId = nftHolders[_address];
        return nftHolderAttributes[userNftTokenId];
    }
}
