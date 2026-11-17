// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";

// Minimal interfaces against the DEPLOYED BuildersV4 / BuildersTreasuryV2 /
// RewardPool proxies on Base. No pin source is imported: every result below is
// deployed-bytecode behaviour on a pinned-block fork.
interface IBuildersV4 {
    function version() external view returns (uint256);
    function buildersTreasury() external view returns (address);
    function rewardPool() external view returns (address);
    function depositToken() external view returns (address);
    function feeConfig() external view returns (address);
    function networkShare() external view returns (uint256);
    function subnets(bytes32) external view returns (string memory, address, uint128, uint128, uint128, uint256, address);
    function subnetsData(bytes32) external view returns (uint128, uint256, uint256, uint256, uint256);
    function allSubnetsData() external view returns (uint256, uint256, uint256, uint256);
    function allSubnetsDataV4() external view returns (uint256, uint256, uint256, uint128);
    function getCurrentSubnetRewards(bytes32) external view returns (uint256);
    function getCurrentSubnetsRewards() external view returns (uint256);
}

interface IBuildersTreasuryV2 {
    function version() external view returns (uint256);
    function rewardToken() external view returns (address);
    function builders() external view returns (address);
    function distributedRewards() external view returns (uint256);
}

interface IRewardPool {
    function rewardPools(uint256) external view returns (uint128, uint128, uint256, uint256, bool);
    function getPeriodRewards(uint256, uint128, uint128) external view returns (uint256);
}

interface IFeeConfig {
    function getFeeAndTreasuryForOperation(address, bytes32) external view returns (uint256, address);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

// MO-C-02 STEP 1 — consolidated measurement at the pinned block.
// Subnet set: 330 candidate IDs = both ID derivations (legacy keccak(name),
// V4 keccak(chainid, name)) of 165 names from (a) the branch repo's deploy
// artifacts (subnets.json migration snapshot + deploy scripts) and (b) public
// sources for post-branch subnets (MorScan subnet, Morpheus Marketplace API,
// Gnars, Mordiem, Protection Fund). Completeness is judged by accounting
// identities, not by the name source: the per-subnet claimable sum must cover
// the contract's own aggregate view (it exceeds it — see record), while the
// deposited sum is a documented LOWER bound (see record for the residual gap).
contract MO_C_02_MeasureTest is Test {
    uint256 constant FORK_BLOCK = 58452000;
    address constant BUILDERS = 0x42BB446eAE6dca7723a9eBdb81EA88aFe77eF4B9;
    address constant TREASURY = 0x9eba628581896ce086cb8f1A513ea6097A8FC561;
    address constant MOR = 0x7431aDa8a591C955a994a21710752EF9b882b8e3;

    IBuildersV4 builders = IBuildersV4(BUILDERS);
    IBuildersTreasuryV2 treasury = IBuildersTreasuryV2(TREASURY);
    bytes32[] ids;
    string[] labels;

    function setUp() public {
        vm.createSelectFork("base", FORK_BLOCK);
                ids.push(0xa54daf91d3ecc0bc7f6bdb02f81c117fd96a759e4dd6fd559b682bd28a4da015); labels.push("NEW:1mB2pH");
        ids.push(0xc773aef8f5c056b0c7a689b9824eb58103a2b9019de4df284b7d5312ecdac11b); labels.push("OLD:1mB2pH");
        ids.push(0xa144c0c7a119b57a4bb67ed106d2a44905551f553c996fd047871eb100ec102b); labels.push("NEW:2hG4yB");
        ids.push(0x010af252d4105fbb6bb3b732227a1145551c2d5d0c9c22a1f92c9f46cb26cf8d); labels.push("OLD:2hG4yB");
        ids.push(0x9c177385ad651b1446343b53465af8230130887dea25c11bd1a879bddebd2ea9); labels.push("NEW:4kGpL8");
        ids.push(0xafcaf9312d2873f0b58a04fcc310db9d71ca402a3a48adfbcb00acc691851908); labels.push("OLD:4kGpL8");
        ids.push(0x15e5117ff74c3033adbe6f60b4db5f0d16fcaf2ad2c184a97948917355450bab); labels.push("NEW:5kP7lT");
        ids.push(0x22b539763344d4e3e3669224df96f6daf05a1badc8abd280c6fb1801007b8402); labels.push("OLD:5kP7lT");
        ids.push(0xbf0b5900b1ce112b7629a06bbd84a5cd4ea184fa2ec8a3b2eb81b1b0cd95ab92); labels.push("NEW:6079");
        ids.push(0x730429d43c917151bf43c3baa677922276bced4eb6718a5cb20a352bcbc0a290); labels.push("OLD:6079");
        ids.push(0xbb4018bb20e17947c473a778ec441ddf159bb8f77de16646523b28e83496efd1); labels.push("NEW:6eB1cH");
        ids.push(0x488115cc259f5751b67c2dc5b315776083e7bec275758d737925e137ed935024); labels.push("OLD:6eB1cH");
        ids.push(0xb4c8eb5eda3bca21f76acde8c9eab49256ac0a1038d8253223e3fab32669abc0); labels.push("NEW:6sN8e4");
        ids.push(0xe80f7558f72bcba6abd7fd5c22c16345ff3efa28e34ffcd07d9147215745ce73); labels.push("OLD:6sN8e4");
        ids.push(0x86443ff2b1f69ce62f89691781ae79359c4c272c7341d8808b4e3c892585977f); labels.push("NEW:7yB1gF");
        ids.push(0x33ab9e55f308ac127f657c85a63fdb0dbc2f83acd15b0a76894e0e2408f9aaab); labels.push("OLD:7yB1gF");
        ids.push(0x50f402ce12aaa749751f080a8e71127498f90e42c153c3c804e5147ecda07082); labels.push("NEW:8lP2kH");
        ids.push(0x031a4cdd21d6ee869ffa1f4f234a30b80b3a4a83fefb8188315498196318adc4); labels.push("OLD:8lP2kH");
        ids.push(0x79a1f15a096ac3869f27a59a1c182903a8b252d0140bb9c12669a7f54027162d); labels.push("NEW:9nRt5e");
        ids.push(0xcdb4f966cd70d7c39660373be9892f59ade1ef08aac338dfcfc7c83b2e6f58fa); labels.push("OLD:9nRt5e");
        ids.push(0x74c8b3d7618f2fec01955575a760869651dbe82f3c3457817e7484b6fa8e73a0); labels.push("NEW:AI Art by Venice");
        ids.push(0x664823f3e70c7f2788e8d393bffbfe1c6cb463d6af29b43933af6cfd7944588f); labels.push("OLD:AI Art by Venice");
        ids.push(0xac70263b75b155d13aa077bed4bb54668706e8b5891d020fcd1cdc604fd1c011); labels.push("NEW:AI art by Venice");
        ids.push(0x4cba0f501b4603ad2e029e8ae5880befcb3e9d13c9e14987117374f2d87ad17b); labels.push("OLD:AI art by Venice");
        ids.push(0xde6135327d299eee66d91a87868c648c68126d56a6abd7798d80f8dbcd03ffb7); labels.push("NEW:AI16Z");
        ids.push(0xc1ecd59a9b43eb728f40009cb3874a209a54233bdc1266193041e5247e0b22ee); labels.push("OLD:AI16Z");
        ids.push(0x7688ef3c97c34200920142fbcf9100534149d346a72fac6f711b1eccac2738d5); labels.push("NEW:AO Arweave");
        ids.push(0xad925e39a087802d56fc2f774262d2c1bf41344e802328d0aa5fc04dddd526db); labels.push("OLD:AO Arweave");
        ids.push(0xe432e57e1657abf83eb85efb89a222ad49c3f13074ab565588afa1905412d2fa); labels.push("NEW:ATX DAO");
        ids.push(0xf18718acbee73105d304ee13f506a5765de4885f1c62a8f5a97089702c40507a); labels.push("OLD:ATX DAO");
        ids.push(0x28b9ce744a53150703a86bba440cb28a95e606c9ba5cb0d13d6d03a9da6192e1); labels.push("NEW:Agent Access");
        ids.push(0x3082ff65dbbc9af673b283c31d546436e07875a57eaffa505ce04de42b279306); labels.push("OLD:Agent Access");
        ids.push(0xa5832b3476773788a6436e565c116942abe01ad572c051e936d3219f9bedc81a); labels.push("NEW:Aigent Z");
        ids.push(0x975822084ade3f1c75ddb0e4f63500d375330fd2110ee528dec27a44d7040f11); labels.push("OLD:Aigent Z");
        ids.push(0xedc8604ac6e9e0a12b22b6bdd71fa6ce68385e7bbe0cef2427992df4415ce473); labels.push("NEW:Aiora Agency");
        ids.push(0x78b78019c2d0782c9790a3ae61a899c857d54e4ae6e012caca7338e477857868); labels.push("OLD:Aiora Agency");
        ids.push(0x34bc78f8f03ff35cbd0f1e38bffd5b288e65154b03b4d18b9a13088d7cbe1cdb); labels.push("NEW:Airvey Advisory");
        ids.push(0x4f42bb9dee66865e920f676995b247c29add563a33a995ea2c90c4e66c10b1f9); labels.push("OLD:Airvey Advisory");
        ids.push(0xbd954529ed8a9e869f7130f017876e52dbe4d6e954e047784473c44de6d2c2c6); labels.push("NEW:Akash");
        ids.push(0x92ec4d95bf8d273481595c40a08ec03642868af7a1ed1a8b64d2372eb6aac33d); labels.push("OLD:Akash");
        ids.push(0x080031f1a47a8e782f5d80001542c851651666fca6b02fc6994368a0d7a56289); labels.push("NEW:Arkeo");
        ids.push(0x966710b4bff7486021f6c272f4c9e332cd35eeef58334cc7fc1c02c71088422a); labels.push("OLD:Arkeo");
        ids.push(0x4cc9cc9a957b5d6423c63c6d1dc4343d12833190acc54c8fffbb223f46f46ad8); labels.push("NEW:Bloq");
        ids.push(0x5c92edba5c98bd16497d97c0f5b37dfb696e9330bd12b06804bc45a6d0a619f0); labels.push("OLD:Bloq");
        ids.push(0x311a85937eef812654c276de875e672762963f34cbe86ec6af85036b751676a0); labels.push("NEW:Builder Register1");
        ids.push(0x525299b81b12c7478c98f0fc95f3b3a6a2c93ff62810c08c733a2727bb8e860b); labels.push("OLD:Builder Register1");
        ids.push(0x3b6150b0073d80fc138ed04da686a532e45b7b9388eb04b5581fa01ea04244c8); labels.push("NEW:BuilderSubnets");
        ids.push(0xe06bc8e9ec643cb4511e21e57bdaf26d4c2c7bdab0f9b49607cdb7a1237f4237); labels.push("OLD:BuilderSubnets");
        ids.push(0xc965347fdef329dd9f5be4037ed37a890c1563c0d5e915364bcb67cb9dc78f00); labels.push("NEW:Builders");
        ids.push(0x4d86a40cbf319e262cf6a25fc9210a5afe650a5124c489ea50f7635fba7cb6ee); labels.push("OLD:Builders");
        ids.push(0x39048f8b6c6b94bde389e6d14aa3f735dd7b3759fb3efbba9a3d66fa3c6a5b60); labels.push("NEW:BuildersTreasury");
        ids.push(0xdd4ad2d29157b774996575db2268fddcc5ce7385ab721fb861282e61644cc9a8); labels.push("OLD:BuildersTreasury");
        ids.push(0x89d1cc0c496eb3c59c51bcead2884d96d612fd53b20655e0ac70d3afaaa5bb2a); labels.push("NEW:CCOVibe");
        ids.push(0xd1c92131e09eb948006132c27c2ba5e12890bcd445fafd135934d92a093a3a02); labels.push("OLD:CCOVibe");
        ids.push(0x912545d1759e6fda2a80bbd6f402db66586cfbf93ed3f8cf35c4fdc72ddbe5e7); labels.push("NEW:CETI");
        ids.push(0xe7aa57528844a44f9c1833db28775663b5d16e09c8075407b07c8973bb05d185); labels.push("OLD:CETI");
        ids.push(0x3378af4ab9be18d3855b348565d0c5f07a4df950bf6d1aa84c83736f8063f691); labels.push("NEW:DAIS");
        ids.push(0xda589917a3e3836aab6bc61103b436b5a3ab440e9b69715a1618f74f9dda5a7b); labels.push("OLD:DAIS");
        ids.push(0x8f62b3ace68b55f1f3b73c9149d5c421196b88f7546e6a0059876c19c98d6b78); labels.push("NEW:DeFAI");
        ids.push(0xd779b953d99618c0159171c3364d60df6f75ab3f2d209bbf684616fb7e928894); labels.push("OLD:DeFAI");
        ids.push(0x09aeb4c40fde9e5f5c562d4ce84f9733ed40e53b2f091c2ea7018723f5c73fea); labels.push("NEW:DecentraNet");
        ids.push(0x0a5ade57dfa9217dd1e955ca68468dfb249430c89c5f41b0c729e04db87a0563); labels.push("OLD:DecentraNet");
        ids.push(0x3390431e7c59ed7cc099c5d91b239c27f710047e533f3d6eba2d59a295332389); labels.push("NEW:Decentranet");
        ids.push(0x78890edda91660f81c09bae3c15928d18ba26bb042d3db4341053b45f01fb469); labels.push("OLD:Decentranet");
        ids.push(0xeb0f0e4caca38a985613b0badeabf17eaa1e95b0a50c861c3e2a89542c0a6b57); labels.push("NEW:Distro Media");
        ids.push(0xc00e9d8d26a19b9af1ecb5e717182a7db3f5d131ddb324df6e996464c2314ed8); labels.push("OLD:Distro Media");
        ids.push(0x52bf5d94bff4f375faf789ccb75cc964158cf68fdd4218ff7d7fdfa7967335a0); labels.push("NEW:FeeConfig");
        ids.push(0x4ba03324f962087ac22769179cb722290dfe51b170eef41efd508c0512d880bc); labels.push("OLD:FeeConfig");
        ids.push(0x412ad0f2d588255a60b77e8db79ff419f5927292a4d5e2bc8f032e387b41a31e); labels.push("NEW:Flock.io");
        ids.push(0x36aea6a8fbd9382c147c110ff07de962300818995b9961a8fea131d5efc1b1db); labels.push("OLD:Flock.io");
        ids.push(0x04bd322ba4c3547cd41a66f19b24b1f4b3aba53e2abe30f70556155a758aa47e); labels.push("NEW:FreeOpsDAO");
        ids.push(0x247ca57d9eb44d1bec4595f50fc7dc6b7ac765c414dc4fb05b5b393e1eada98b); labels.push("OLD:FreeOpsDAO");
        ids.push(0xea860aecbf4eb146c8a95f5581470d6ba417352b839d7e82e9023394b1a4eb0c); labels.push("NEW:Freedom GPT");
        ids.push(0xf510a7f4efbcb090687018eebc97c61d447a833fbd1ba4333b0fc2e4541b5def); labels.push("OLD:Freedom GPT");
        ids.push(0x48757448f78f5874cc3e03a33aded454436df40371a4d395b1cda2c89d25d4f5); labels.push("NEW:FrostByte");
        ids.push(0xd6afb3447b6d684ed910bf2f3d6bc00277032db092cfb211ac4bb66c1f4d077d); labels.push("OLD:FrostByte");
        ids.push(0xe91520ecbdae074e72712d747a0549153a1281e73f67de943466a748e4368876); labels.push("NEW:Frostbyte");
        ids.push(0xa7fafe0dddaeea5789018c11d0c420b718734b6c36a454c4613befb9b0e0f69d); labels.push("OLD:Frostbyte");
        ids.push(0x5ddf805c507b664cd6db6babec19b30157ecb05458e4cc93e82847e685933b18); labels.push("NEW:Gen Layer");
        ids.push(0xc979023bb9bf3b74ae2eca5a210c7297f9e8e604d01a0d6024de07acfa7762fc); labels.push("OLD:Gen Layer");
        ids.push(0xbb36c31454af4b85c2c9ca1ba76aed500e1fc2684f026935b9b7896bd3941996); labels.push("NEW:Gif Studios");
        ids.push(0xb9086e4900331eb895edf4f6db298bd290d48037c663e6243d0386157dc8d0c7); labels.push("OLD:Gif Studios");
        ids.push(0x43a2a04186c40bdbe619e051bac91728b113e4eba3852df83f220f364d206949); labels.push("NEW:Google");
        ids.push(0xf610f88085f5955bccb50431e1315a28335522d87be5000ff334274cc9985741); labels.push("OLD:Google");
        ids.push(0x135f81473dccb36d6ddeb82fe20f3030cede1ff02935df28533af86fe7bbdc6e); labels.push("NEW:Grakl");
        ids.push(0xfde7d8a5de1071db3911b562a5647dedd538ff73d01aaa7862658dec569d0707); labels.push("OLD:Grakl");
        ids.push(0x82481a0f43e3f18487e871247610fe1150ddb67a77004e284a609c72d38b65bd); labels.push("NEW:GridMatter");
        ids.push(0xa9255f549dcfaa5dac61b450252bc0c535624a0a837f66eee503c89fc747f50d); labels.push("OLD:GridMatter");
        ids.push(0xef1a84d027514696576c214697f03f695072c0955b9a543a4b9b4f4785ec8164); labels.push("NEW:GrowMOR");
        ids.push(0xd36cf10a2fc6460f84bc3d69a34da57d8223d46757eef0326aa23bc8f658e56f); labels.push("OLD:GrowMOR");
        ids.push(0x48c79ecbd02d3b8b62332d2cfbe57083f675d2ca667624ec61cde4a8acb60966); labels.push("NEW:Hemi");
        ids.push(0x9a7e67694fac9f58c1e1d2b1791c5badfe0eceadb7f377b04bf2f0b00d56b343); labels.push("OLD:Hemi");
        ids.push(0x276bc625749ea4d69ba86fc73cf8ef9d53f01b519a67b9b131085fd210412a0c); labels.push("NEW:Hyperbolic");
        ids.push(0xff2a83dce744d5c9b6dfe11813d09104cf0d01b7ef1b3ab4bc228b50c0f692d4); labels.push("OLD:Hyperbolic");
        ids.push(0xf7b1680e12ceeaef1be3b03f82cf25ad695a60efc8d3f1c5a6ce5a00461ed7f2); labels.push("NEW:IamAI-Core");
        ids.push(0x4501d4e79230adce800ff26e5d2e2ae061f1e54da8508fe17dd1462388fb8373); labels.push("OLD:IamAI-Core");
        ids.push(0x46d179be67ca2e6692f056d4ddc4aa4aeb4be94f270122e17ab53cd05a04e8ea); labels.push("NEW:Katara");
        ids.push(0xc0aca3a0b3cfab81287943ef4a48e0c2f0441c12beb50fc8c2be3a810bbe0d6c); labels.push("OLD:Katara");
        ids.push(0x32b0308ec45d7fb04bdadb4cc9fb59dec64025661ea5a546088af2c969cd713a); labels.push("NEW:Lifted");
        ids.push(0x4cbaac02f4c2ff6d72454ec7dc0a7ed0cbd06dff9d70001ab0d0e84508dd2efe); labels.push("OLD:Lifted");
        ids.push(0x4f143fa2b34c999210aee2daa16496b5b04bb0e11cb9fb1db0e1a33881fbf13f); labels.push("NEW:Loky");
        ids.push(0x7c60385401910d17dba253bd525a1df56854dbca9493b1323532f5dc26a40c9f); labels.push("OLD:Loky");
        ids.push(0x88697cc433562599d2fc5d57b01c7ce813ad9301bbaa648af649fc388055b75c); labels.push("NEW:LpM2cA");
        ids.push(0xb76f9aad5ab87262515a4bc92ff347b7847ee5d5e0845810be171431e11f073b); labels.push("OLD:LpM2cA");
        ids.push(0xaef4e0070c9884dcbab849655017f9296a80fb9d535b7f53f4e5976b6f1a4e77); labels.push("NEW:Lumerin");
        ids.push(0x01c9c97ce69569af244b25f299f3cc830d98240094d6262b4ad010022d689f73); labels.push("OLD:Lumerin");
        ids.push(0xae51e960a955356ddc3cf41b30b55e2e00ff940f5b1fca28fab49894147cec95); labels.push("NEW:Lumerin MOR Staking");
        ids.push(0xb518addbd1e3abf0abcd7bd0db4af0eef300983a8573cc66f54426f83e024468); labels.push("OLD:Lumerin MOR Staking");
        ids.push(0xe323b868aa18293924fadc1d1dd2391ef9928be02716ce10af14155058d61b81); labels.push("NEW:MOR API Access");
        ids.push(0x6aa0f87703b4fc532743d2560ab8deac31a456360ccb7ad22770103d9061b9f0); labels.push("OLD:MOR API Access");
        ids.push(0x82bbeaccc02027f4bf365c7d6b3e7f25666fc129ed9adfc7635f9f4828f82a85); labels.push("NEW:MOR Builders");
        ids.push(0x8036bbb740074d06db6b7741fcf9f52bd25846b9fc7e0a10c983c51530eaa999); labels.push("OLD:MOR Builders");
        ids.push(0xc30cc70e1f1304fe8586990070ffd2dec07c08f7987870dda6596fd0decca785); labels.push("NEW:MOR LISTINGS");
        ids.push(0x26d54d3de64a94b1ecef7c0e1437858999634e53331a9ceaccfe29f034d65386); labels.push("OLD:MOR LISTINGS");
        ids.push(0x604c1c23400ded47c104c88298c8e6e45ec8700e51590f3881369bb6b4a844c1); labels.push("NEW:MOR Staking");
        ids.push(0x8bb6452786155e48063040d7ae34ce4ea10c426eaf87650b59d8db22ec85ce39); labels.push("OLD:MOR Staking");
        ids.push(0x7d0a85937fc662bcb6f784b05193e795e783e3ddcb64e5b560bc04c609501198); labels.push("NEW:MORLORD");
        ids.push(0xb46506c4174fa5ec7a36fdb4d7a3cd237dd6c60d6b2bcc9e4c1731f9f0e49c6f); labels.push("OLD:MORLORD");
        ids.push(0x064cb2fde056586e0691a6d804a62f31894a9eeacf9dc1167f18b31068c32193); labels.push("NEW:Manifest Network");
        ids.push(0x4c25cd7db02a0d0354010749554d260fec635455aca30f7b4001c222d14d4294); labels.push("OLD:Manifest Network");
        ids.push(0x487ad10f5e5b6e9b3234706cca7b90929e510dedb1316e9c59996ce1b0b49a15); labels.push("NEW:Mor Builders");
        ids.push(0x4b3bbe93cd84e4304f785cbf55be1b9cfc23e73c7869704321f5a906e671930f); labels.push("OLD:Mor Builders");
        ids.push(0x74b78871b8cc8755cac78b3a5b888ef3d4f434aa4117bbeb5ce35324da3e2dd9); labels.push("NEW:Morlord");
        ids.push(0x03fa50361370455816211100c40123006f5f15b53b290735edc0810fd61e77fd); labels.push("OLD:Morlord");
        ids.push(0x657143ee5cceab3794e7768a270cc0f58c2aea83d342bfdb7ebaf4f1ebde51d7); labels.push("NEW:Morlord MOR Staking");
        ids.push(0x7169601aa382123b982cb9055874ed5ccb7223a5500a2b41aedf013653d3f167); labels.push("OLD:Morlord MOR Staking");
        ids.push(0x3f2790ef7f894f15ddb88f9c06a545ff8800468b6a9c1cd529b47efd99ddd17c); labels.push("NEW:Morlord Shared");
        ids.push(0x0b4e662f0a3480ee9117e3c2f0559d3f3295eac04ea52f84c1c5893281f22bb4); labels.push("OLD:Morlord Shared");
        ids.push(0xb4fba9ed0a36924968b2f4132e12147aceaba7c62e760db2ff11b601d8c969a8); labels.push("NEW:Morpheus Node");
        ids.push(0x0365447f7c98fa1070f467f2cc220de7b0b9c17b9664336c10e26ee3182f39d1); labels.push("OLD:Morpheus Node");
        ids.push(0xfda5857fbe797e8f5da478a1b27f0ea8cc47ae1693cb6d107df889c4b6a76b64); labels.push("NEW:MorpheusAI");
        ids.push(0x3f73d9b00b869a0eebb5325b37c807252a1307bd5390ecde1348aa11233703b2); labels.push("OLD:MorpheusAI");
        ids.push(0xfb90feafee66a4fd9f22f41b58f06bd326b7bac1f5edb1123cac5bcbf9cd627d); labels.push("NEW:Morphues Node");
        ids.push(0x50a52d70c4c3b4b77d8fefaa24faf038450a656b9db6bc2e9d897f55ff72e974); labels.push("OLD:Morphues Node");
        ids.push(0x470cc58eaf1d02d9a010139b116b70d0aaef32bcef23708e8f5a3404af68ad97); labels.push("NEW:MySuperAgent");
        ids.push(0x96e624768600a7be0f2a82545d33c137ff3df2f377dc3fdf468308e5b977a72f); labels.push("OLD:MySuperAgent");
        ids.push(0x834530ca210e049ebeb8c4f71c3627f2086726699596498376fc6f525ad665db); labels.push("NEW:Near");
        ids.push(0x25e349b6e220e73d277d80c4e8279b5bfe33b0adafa90193ab1dc763e5ed5e72); labels.push("OLD:Near");
        ids.push(0x4e043793efd7b6abc1ea29a70a0e04ec3d2efc51d971d1ed60fbfc7315d5e8a1); labels.push("NEW:Nounspace");
        ids.push(0x79611d94d04d7c5a4dcfa6733b4c096a918193b453b10688665088f5183723b1); labels.push("OLD:Nounspace");
        ids.push(0x7f62e0f2b574e35a1d7a8fc494ee38ab3e7a599a76d273bcbd5d3487e1c0c955); labels.push("NEW:NounspaceTom");
        ids.push(0x6853bdaac0b14b032091c3495bfe4cf14ba89b86b0859ffdd937f17361befdf1); labels.push("OLD:NounspaceTom");
        ids.push(0xfb54452ebb0c2c92e4ea54329c6df749f384f890a5ce685726997624ce5647f7); labels.push("NEW:OLAS");
        ids.push(0x523f1bb39a49927241fcd48dacab09dd72c218bf1e3a01e3206264fd666f0d79); labels.push("OLD:OLAS");
        ids.push(0x8636f091b395539c04859ab5756f114d7435be9260f5b369a366332b3bb32f33); labels.push("NEW:PALcapital");
        ids.push(0xc8a0087b1d7e5b3a2f18b2d79fd2fbf187802af7370b928ff0e6eacf47341299); labels.push("OLD:PALcapital");
        ids.push(0x8ae27d64457be4aa3ed359ecc0d4c8a854f20864b140e62dcbce243a6d046edc); labels.push("NEW:PALcapital Ecosystem Platform");
        ids.push(0xb5040e011d35dd944d284d4692baf05ec66163d07c023a71eaabd0a930511ad7); labels.push("OLD:PALcapital Ecosystem Platform");
        ids.push(0x5a11522d85c433b88f2cfc32ff54ef191c2f61361e391f2f71cd749abdd3b66c); labels.push("NEW:PALcapital Z");
        ids.push(0x4c2afb6295a12128fa7f9e601a1d77c646229a96dd639e886476a8c216b69844); labels.push("OLD:PALcapital Z");
        ids.push(0xa25c4e40a28eb1f791fb315d1dbe445e8fd735a74bf0f1d90f3698636e57e1d5); labels.push("NEW:Panorama");
        ids.push(0x40aa9fbd2fde2e6a38510ef730aee171c3e81a4c165bccbddefe4c89b55b2a8d); labels.push("OLD:Panorama");
        ids.push(0xeedea65f91c2c0f5c4576a0c0e8bb6c017e8e49e007216d84c55f027d47794cb); labels.push("NEW:Pattern");
        ids.push(0xdcba960308192a0eb3e6dbd97b27b3cc2454e38d06ef78ced76e7378afb2e5dc); labels.push("OLD:Pattern");
        ids.push(0xa456c1c17d69b3aa8da1e0942261f6ef354e00493ab73b54534e250f3060f348); labels.push("NEW:Phala Network");
        ids.push(0x85e3b554619e2fd48a4ad8c8c2744a9d9686463ac02ff83664c717876c313a88); labels.push("OLD:Phala Network");
        ids.push(0xb0edaa27dab0bd7cdf8e4894cb0b57e23c2a9671aad10064bea74319b9f67d0f); labels.push("NEW:PoolingPool");
        ids.push(0x9063e7cc118239ad52f8ac93133fd4b33f819217f2baad93c899bff7bf569fce); labels.push("OLD:PoolingPool");
        ids.push(0xadc958fe820b53f46cb686ba31bebb197f6a0bb141b0f38e70cb08b35fc0ef24); labels.push("NEW:Project Cloud");
        ids.push(0x1fa03df9ba7caac7b490ee9df117fa2b17408d3a6a84037f806b7b89c3f9d938); labels.push("OLD:Project Cloud");
        ids.push(0xb1c29a7d2adfd7daa49c89ba3d78b45c83162ed7de4d25db5995861f9e4bd8e0); labels.push("NEW:Protection and Capital Incentive");
        ids.push(0xfc9d100f7a082467b344c807c5952038c31abe80caefbdeeb884ce252e15351a); labels.push("OLD:Protection and Capital Incentive");
        ids.push(0x73310e5dd23aa0766ea4b899291b2baf117a6c376d5a06fe8c262f518928fe6e); labels.push("NEW:Rainfall");
        ids.push(0xbffe9cb8e4e2ecba926505a06c6ca3717cb2bdbee65797b1134672765899c0b7); labels.push("OLD:Rainfall");
        ids.push(0x818b3868abed4c09695526e2ac68c5e072295cfcc28dc8b7d3d6779a4ffe33b2); labels.push("NEW:Renascence");
        ids.push(0x96342c265828489a728e6278d3c1eab8f53a89809055b5d6495cb2b39bbf16a2); labels.push("OLD:Renascence");
        ids.push(0x8e2aaf3f14b2877b5179b3de15d6567ea688f192bda9c44d23f59a6dac5d2754); labels.push("NEW:SUPERCYCLE");
        ids.push(0xda50f9aa1710272d6c17f84d713b6c8f30b2870c376039e5323852b027a440fa); labels.push("OLD:SUPERCYCLE");
        ids.push(0xc7a5a01914d854a707077c0b6fca20ceb42a21e1ffba7ace527305e7a765c4aa); labels.push("NEW:Sapien AI");
        ids.push(0x42f02b08eadb43dbc23783822aeba31623e22e2c95e608e48590adb48e7856bf); labels.push("OLD:Sapien AI");
        ids.push(0xec04ee0305dfa0cbdaee7f7f799eb62f87ad312d7ef4a1b750957919c221918b); labels.push("NEW:Satori");
        ids.push(0x6d4a00233c2192694cf0dc52e0bdfd73e136bd1338fcfced149989e7fa6bbdab); labels.push("OLD:Satori");
        ids.push(0x268362189cc04b3f1a1af388acf5acc8d90848949825dd07418588ceadb8546c); labels.push("NEW:Shapeshift");
        ids.push(0x7671a13aa6295ad5c6f20200935602ffe4cde338d98bdd43979b3664b65ad4ff); labels.push("OLD:Shapeshift");
        ids.push(0x98e87a86ffc18989cf141174694d96ba3f06e0328cc1793407fedaf5544524e6); labels.push("NEW:Shiza");
        ids.push(0x02c49fbf6a69c0c54f6a9aaad9c4fb25ab46304a391da4fb891e94cd50caf101); labels.push("OLD:Shiza");
        ids.push(0x39ce834e54550b6c0ab48c1c90e39aee53cd66bfc470c17e5499cfc1faa2704b); labels.push("NEW:Snowball Money");
        ids.push(0x6523f7e4f8418318d5361681a4f3d499bce60b3d8118b32d02ef295572304aff); labels.push("OLD:Snowball Money");
        ids.push(0x69cbe13aba173d381ec658f908055f9e3967e5c80c9e0256005fdac2a5c9e104); labels.push("NEW:Staking");
        ids.push(0x1df41cd916959d1163dc8f0671a666ea8a3e434c13e40faef527133b5d167034); labels.push("OLD:Staking");
        ids.push(0xa46ca7cc437465ce746f7364d1e1dcbbeafea777c1623b861a750e8e49828849); labels.push("NEW:Supercycle");
        ids.push(0x70a8b9982ce25814a05d0cbc53e14d6e2ebc073620790482401e19b84f2bad64); labels.push("OLD:Supercycle");
        ids.push(0xe6ef4722c357328c2de4392c2d891a8b69ce9574861c66a85aec9af24ea639c8); labels.push("NEW:Supertech.ai");
        ids.push(0x2bb5cba5aa810086dd76d5a20c06616f9d7229b710078a809c1ad5654ebdb3be); labels.push("OLD:Supertech.ai");
        ids.push(0xdc3af3b6827d6823e7f5adb9fd3cf17dcd334ddc94c1608e22e8fdde0fd0c917); labels.push("NEW:TacoBytes");
        ids.push(0xed99429be84b05331210ff2d4b1ff17e52876fb7c2a3b72caf3cb0fc8bd97e52); labels.push("OLD:TacoBytes");
        ids.push(0xd33e54e9d565c854b52ceeb7f1a252bb16c4bec54a08f29fef548c4904c7f669); labels.push("NEW:Tails & Conquest");
        ids.push(0x81d067ea1ad5367ddc5556020d6bef2bb5215e1d2d7d75888b400454b0f9b7cd); labels.push("OLD:Tails & Conquest");
        ids.push(0x048490cca1d847b1f7e1cfc900189acfe4cfaf0da287e5a14b4fc187e3b59507); labels.push("NEW:Tales & Conquest");
        ids.push(0xaabc7043f8d1616d55ecae080430fb180ece49b4c269377d6f9c830854acabfc); labels.push("OLD:Tales & Conquest");
        ids.push(0x375c9601c13c528fb9ad9c368653ba98cb2be79c293b0f947497b4dc04752c9d); labels.push("NEW:Tales & Conquests");
        ids.push(0x6a117ee75d9c3c44c18cf44009429034ad02bd2e14fc3e982e63bdafcd55625c); labels.push("OLD:Tales & Conquests");
        ids.push(0x7b8d8e21438705d574a0af378b90b15acb67c61b6f54f3bcc5c1a624ad07d8b9); labels.push("NEW:Theoriq");
        ids.push(0xcd69610384d862dcae7c4009fa01b20624fe0cbf464d2468a041ffc709bac2de); labels.push("OLD:Theoriq");
        ids.push(0xc5a365611641b6fe9312dda6c3dafc1a2e5356674e56220f2cd3af48e06d9591); labels.push("NEW:Unocoin");
        ids.push(0xfd1572a2a5e1bc5b350e34b0789326b6a02c14b357c67405d537eb4159df029d); labels.push("OLD:Unocoin");
        ids.push(0xc3869178544c5910e3eb89f8ea8dbe6cc9ad25d7269c5e1a7cfe578a8e0d4978); labels.push("NEW:Venice");
        ids.push(0xf8c784db930f5b824609b2a64bc7135b089666624ba6e3a8cca427eafcf572cd); labels.push("OLD:Venice");
        ids.push(0xe88f6cb907d15bc5b33cf0c64f5a8c38384f078d9dc3f05b9c570865ecfbc207); labels.push("NEW:Venice Pro");
        ids.push(0xc0b926f96e1aadbcd04c21c56649e3846b35bcd18ffafc1cdce7a3d8130c419c); labels.push("OLD:Venice Pro");
        ids.push(0xc140d9b8e35b7368df7975b31c3b87f44c11c5b3baae3af1de667d7cdff01753); labels.push("NEW:Virtuals");
        ids.push(0x638451aa95394a1ea79bbf9d15eb532b5beed7f3831ccc8db278654ae30dad27); labels.push("OLD:Virtuals");
        ids.push(0x4015031371a3f5c205ba00521f9e6d9c6e07b0e58271058295a87b1ca956e6fb); labels.push("NEW:Web3 Cities Network");
        ids.push(0x5328365500d7838f2451020c8e8b8a259ef10aaa5e21997d6719336ef3557de4); labels.push("OLD:Web3 Cities Network");
        ids.push(0x86fcacd23ee545954fc377b2d18b90b2f9bb7b66a048563bfa5b4da7db0b5c91); labels.push("NEW:Wire Network");
        ids.push(0x63891e659ff2ae88fdaf6ff05f07ffbbd4ffbca089600564c7c6c784a96ab0e5); labels.push("OLD:Wire Network");
        ids.push(0x657b3750d531096665b11ab4f79f3f4b8eaead757969bfd8b5272404329f7572); labels.push("NEW:ZO.ME");
        ids.push(0x2cef520db0d87be977cc612c0c57e2ef1788fcd8e7032418be1cccea82a603f4); labels.push("OLD:ZO.ME");
        ids.push(0x68ef0d0e9fe74bc6f09dba542e7e53d1b28761b0a8e17af326820da4de214a87); labels.push("NEW:aB3dH7");
        ids.push(0x8ea11a0d2a3fc12ef01ee16e87cdbd14813a134dd45feb08d2e6ae5b43dfc63d); labels.push("OLD:aB3dH7");
        ids.push(0x6fbb80b61f11abd6623ba37da4fb6576bec5bf60fa3cfe3c1f4508210508cc49); labels.push("NEW:brainpower");
        ids.push(0x25c16934a56ededa389e347f693f39caa3596a7aff16a3eab9f74bd3b731cf6e); labels.push("OLD:brainpower");
        ids.push(0xe4eb2ec1bb826c9d447f8fc812b13791ee5fe50f58b090d874234cc51eaf36f1); labels.push("NEW:cD3fT9");
        ids.push(0xb7afbb207d211258c10fb7da32f56ecbe1cf3c816f1134c70203217f4fbb369f); labels.push("OLD:cD3fT9");
        ids.push(0xfb56be6315faa3d4adbd9f00af6cf1501c2601a214d61649b15b561eb80d81ca); labels.push("NEW:ccovibe.com");
        ids.push(0xe9fba89ca97425c3389c8086a17a75785b04152c035b68b8108980375a60ad21); labels.push("OLD:ccovibe.com");
        ids.push(0xf6f7c51b8d3400d24fbb8d080e8110b0afc2f196f7304f5d6ff769281b6a14f8); labels.push("NEW:coincap");
        ids.push(0x0c8d5f4c48826aeecff5b2defb4314351a3ca7f93f7b41d8bb99c47e3aae1360); labels.push("OLD:coincap");
        ids.push(0xfb2fa959646b3458cc9b77dcc48bdf4e07b04c2e2cd12a70bddc4dc336a39afd); labels.push("NEW:eA8cT3");
        ids.push(0x8e33b44f2973f52ca1923b7b3922b5d465f4e8a999548e1bd98ad693c64e7529); labels.push("OLD:eA8cT3");
        ids.push(0x494b69b1e12a4f61587907ca93b58208f9c27b7e41f204da194764f2b62f75c1); labels.push("NEW:eK7nR8");
        ids.push(0xee0a6d6e5c828c10cf5be57c4ca739b5de160f40ea524d2f4a0207f71d5355bb); labels.push("OLD:eK7nR8");
        ids.push(0x3f8470ded74bf4cae237c46cf0b6dd1780986cac5475c78585d0fdc7ed03b99e); labels.push("NEW:exaBITS");
        ids.push(0xac491f4c14b9f329398b820d2573f73abdf66ebb0c5271fa55c3dcfd5adfa2fd); labels.push("OLD:exaBITS");
        ids.push(0xd3ce00b962f464ba0c66bdbad0f296e17653e9f451bf884d579ec1e2a31d41b1); labels.push("NEW:fT6aM1");
        ids.push(0x97bd9f473fb119707a62524d36189b5a58fa0409b0140a9b7c44ba7d839bfd44); labels.push("OLD:fT6aM1");
        ids.push(0x596cea3f7db71c52b52b56b0398ecdf58b18b59d6f44c0c5aabb7df0a17ab969); labels.push("NEW:gF2yM5");
        ids.push(0x0046fed04890542cee45802466b51895986fda6c4838e0a3a9d677d9dc56e31b); labels.push("OLD:gF2yM5");
        ids.push(0x57d69d599323d530041dd7c5de7de1f3ec2be9fd73d03edfcce5fce0072cbaa3); labels.push("NEW:iamai-core");
        ids.push(0x773f45fb1df3ae27ba60d371fc36af32fd1896863c842b4c4e89e30668944c0b); labels.push("OLD:iamai-core");
        ids.push(0x6c92738bce4c97824fd5e3c329b758b0ce75a2bb0a50f2b0fe296531219b572c); labels.push("NEW:nH7lM5");
        ids.push(0x3bbbda9835760a1478b287f3c5897253e32f52925f319eddc1eeffe164ea2e62); labels.push("OLD:nH7lM5");
        ids.push(0x0e97e7da0718991b0b255c493ad6240949c883c9d8334d12051852c9b2d74f71); labels.push("NEW:pL1cM6");
        ids.push(0x763ab46c0667cbe03bc32c23a297d5e7bed855d08205bd08c16d8772fb278fcd); labels.push("OLD:pL1cM6");
        ids.push(0xee98b932e3870cef5677feb4e7054ca73727520e91c1e9bf80a025348ccbf656); labels.push("NEW:pR6tG2");
        ids.push(0xf262a593668fbb893bfd4733d08fad5af963d8935c91437c68ff0a208febe01f); labels.push("OLD:pR6tG2");
        ids.push(0x909eb5f83818283118290eceea9899ba512ce0d1a55344e58cdda3c1a8addc5d); labels.push("NEW:pR9fL8");
        ids.push(0x3c4f197534d29123b002222315a63765621418d3a9304f1710ccad5fa6880811); labels.push("OLD:pR9fL8");
        ids.push(0x7b2bc282cec1ed06bf3801885adcbdae9edcfa8ba427b61eb19cd1bb333c0861); labels.push("NEW:rE5dN7");
        ids.push(0x774e334afa8c848864d129d84747a56ffc1eced3ef2df236a1dd3dfb0f62e76d); labels.push("OLD:rE5dN7");
                ids.push(0x32d31c22d421f51153dfaaf21ff07019423fef33b4656f4e7e0990dcf32a901f); labels.push("NEW:MorScan");
        ids.push(0xf61ee07ee9d2c2a8cb4fd44810006765c9a8df5d73a812c517946319a180c345); labels.push("OLD:MorScan");
        ids.push(0xe15aad4735b89593fafbd4de71e493047c0e4a67f45fa7a1c57c443709cb2208); labels.push("NEW:MORSCAN");
        ids.push(0x04a5b46830f8e465be7841c2ed449051743dcf9eed82046557b433961d7b608b); labels.push("OLD:MORSCAN");
        ids.push(0xe55e42f5e304ba5d8d1781d9e4e3075e761a8dcb631238ad60e33a9902e042f4); labels.push("NEW:Morscan");
        ids.push(0xf188fe2916289b3c5ced824d4cd2e54d24a6bbbb17d6e7d678e6a58513334016); labels.push("OLD:Morscan");
        ids.push(0x472839b7d2bc8b47fd8434abb21725a31fd4c992b75515801a3fd868b017ac69); labels.push("NEW:Marketplace API");
        ids.push(0xe12c82f3d4bc6977b4d7a8d6643292d9a096bec68944d1d3df90d095ed2555aa); labels.push("OLD:Marketplace API");
        ids.push(0x415471125cc4d03b89818acb8426981fa28a3eee03a9097176297a9a6ae87c8d); labels.push("NEW:Morpheus Marketplace API");
        ids.push(0xc8679bec1c4a7300eaa04c88ec2ea6de81fef1350351cbc1917eaa01c30a76fb); labels.push("OLD:Morpheus Marketplace API");
        ids.push(0x9bc85694173778b57acf933b8492b1407673ae34ed5a7bd4f4fe6a5b4df1791c); labels.push("NEW:MOR Marketplace API");
        ids.push(0xd1a71f9167d4e784fe859cae6d27d21b24c5e4d15630166ab947577bb52950e0); labels.push("OLD:MOR Marketplace API");
        ids.push(0xf129111951997d1c386be9b7de27d4c74490c42ad0ffbcb65e380d17f8a8ea3d); labels.push("NEW:Gnars");
        ids.push(0x1677c8783f2fddb250119a5200a55d34ddbd326298fbc5d5b042ace0d9ae3f74); labels.push("OLD:Gnars");
        ids.push(0xc4f2b2fb2e38dc24d9e3006fabe1190d6ca124cb62680d31ac1b4196a2f19969); labels.push("NEW:GNARS");
        ids.push(0x9966882c9663f3d649f3d1bb8de93497d05bf7d1dfab855f30b3696c5d2f2478); labels.push("OLD:GNARS");
        ids.push(0x60c5c7acff818a066cfa6c0ea84a18efc02af508dd3e6174cd4b63654818a4a6); labels.push("NEW:Gnars DAO");
        ids.push(0xcf2cf3e3d69efe06ae5e9caf46039eacc8a1e6f7cda221b3504e1702a84c58ea); labels.push("OLD:Gnars DAO");
        ids.push(0xcca20d40f12a125d006b11f40a656f68e6aa036f3dd1505360908a5d5515803f); labels.push("NEW:Mordiem");
        ids.push(0xc75c4e4428f4071865d2bea8f6b34c33e37a7ca5ce714ae62febcd74730e656c); labels.push("OLD:Mordiem");
        ids.push(0xffb8adb550865fd1fd301bcf621aeab06fc4e5789e64a226970aef38d4b3b006); labels.push("NEW:MORDIEM");
        ids.push(0x0dddde3c80b0f10ec1536535b162b27609cc5a8d92ebc5d32f645af542302e25); labels.push("OLD:MORDIEM");
        ids.push(0xb7ea1fdf6c216ada4abc73a2dcecf8c55e5a9df5ff9c7a71cab7045fda985952); labels.push("NEW:DIEM");
        ids.push(0xb4ff8b730f691dc7b3964f9145ee4303c6d3ec13d7f71674e6dad1d1963cde53); labels.push("OLD:DIEM");
        ids.push(0x6d9ae5393741341bef63a01c194906bbc59952c19ecae12a816a45cc01ab1a16); labels.push("NEW:Venice DIEM");
        ids.push(0x6fa379e1fcfc6826bc39480a97cac62c939afeddba337a2f75f152d51c7ce23c); labels.push("OLD:Venice DIEM");
        ids.push(0x5b88c26118b7e34b887e56e0627695c0ef357363b52e861fa6270622ad3d9358); labels.push("NEW:DRM3");
        ids.push(0xf2393e84096e5a300f0dd02a7d58e9c6210d58e38df0352bb210bf77fcdfb883); labels.push("OLD:DRM3");
        ids.push(0x6b5f79752e4f89a683e4cd24bf44e3c3c04ff85fa3f86cf907465f7d1ef91219); labels.push("NEW:DRM3 Labs");
        ids.push(0x694880e33fb7b4dc1229f5c9d181c6c2a7d263b62af4f55985e0ee3114862a9b); labels.push("OLD:DRM3 Labs");
        ids.push(0x91ac1987e67a11583b4ee35d1c75683efb187f2bc4d8c1c9f83a208a77eb0bc6); labels.push("NEW:MOR Treasury");
        ids.push(0xd7c432fbfd4363066b10f6b6faf877da77682020eb083f12d2c76c5bf35da38d); labels.push("OLD:MOR Treasury");
        ids.push(0x9b8ecc8908192c04d3fdfd99941ed4ba8c965cfb606203244e312138c71c433b); labels.push("NEW:Treasury");
        ids.push(0x6efca2866b731ee4984990bacad4cde10f1ef764fb54a5206bdfd291695b1a9b); labels.push("OLD:Treasury");
        ids.push(0xf4a1ea01b4f52b7328a1665df387c9ffeced4c7a3233e7316302d0ba45a0eaba); labels.push("NEW:Protection Fund");
        ids.push(0x3ecc09274450689cf70f22c2a60e59e5d3daab683789f6f71a27363a05bc49c4); labels.push("OLD:Protection Fund");
        ids.push(0x0550fe3a6c059719b69cf3792f074fe5902bd7a6437b6892371620bdfadb0776); labels.push("NEW:Morpheus");
        ids.push(0xb32ea3aea90cca3ed2348832807f99baa4fef5c95bdc5d0ed0c02b7325e53130); labels.push("OLD:Morpheus");
        ids.push(0xf5cee6e4d20c1cd34b40ff06ff2f3d89334c2f9def5b0e51ad9d959f6520c9b8); labels.push("NEW:MOR");
        ids.push(0x5fafe3543c706629975f1b4c9f31e30482eb84a4a81f2148d1bad8e427801c17); labels.push("OLD:MOR");
        ids.push(0x1bde4d2d3b7534fcee4bef9e174a68c89757903e37b0f33020771bd67eb52167); labels.push("NEW:Compute");
        ids.push(0x2ccd4917ee436cb21ce90d437f13e0718e76cba14e76902d488d9f01395d4616); labels.push("OLD:Compute");
        ids.push(0x7fcaa8c4a5bd57c2b491865d1b496a1c8d1c1230e299865587098ff280f513ca); labels.push("NEW:Marketplace");
        ids.push(0x893ab71b0c6fc92bef28fc4ee2bc8018ee56220e13f8a287176138660baa87c4); labels.push("OLD:Marketplace");
        ids.push(0x5364602fb326de08565fa6576ba5a72fcb79bc7c83d4ae01660f3ca567eb6688); labels.push("NEW:API");
        ids.push(0xaa1302583a6ff6f05da8af727b4c4bdd1ac9c2643715c7ef1ed5a87be55e2a2d); labels.push("OLD:API");
        ids.push(0x7732213ca6869e74cccb03db9fe13ac2f24f57a2f31d6b4f9aeab6498d78b1f2); labels.push("NEW:Morpheus API");
        ids.push(0x3374056c0aaee147b66c1d48a1d9d37f4e3654e03538972d05f56805bc8e6aab); labels.push("OLD:Morpheus API");
        ids.push(0x101dce7ef03a64d3538ce164dc07557cbdad2e23c56be6aa8af7c063664e262c); labels.push("NEW:OpenxAI");
        ids.push(0xb1de3c7129c2af972fb79d7b23c8ca4ee6d71fa9ed18f066bcebe73078ee6e76); labels.push("OLD:OpenxAI");
        ids.push(0xa192b26f76e44139b85cb28c857cd24879ac5502f71ca19dedfb844339277777); labels.push("NEW:OpenXAI");
        ids.push(0x7ddef6cbed747ae20bfa0ae2afa179f1e588c292219ff520cf9222e9dc1f7744); labels.push("OLD:OpenXAI");
        ids.push(0x8d90aae2aacb084ca77bfe59a6b1d6593b102631c8b500c5c6060c057e980d57); labels.push("NEW:CryptoGPT");
        ids.push(0xd33c5e040b53f4f0383771b7fd17c8517b832811304cc28b68f268d611665f77); labels.push("OLD:CryptoGPT");
        ids.push(0xb8e972ae572a82919935f6e0c8a27485fcb165f4cf3bbaa2e4dc669a3aaa1f54); labels.push("NEW:MarketplaceAPI");
        ids.push(0x9b7bb641a914495c3321cfab07db4daf577fda9255662785c16205291b9141c5); labels.push("OLD:MarketplaceAPI");
        ids.push(0xed94143b8a7ce6561d498ca32363829a64edea277ffbb14bd082c0595f690406); labels.push("NEW:mor scan");
        ids.push(0x2c5ea40eed01e421e34ee7a55d2398355956d2a2c99b0ee0ece573c36a5d2a58); labels.push("OLD:mor scan");
        ids.push(0x109c23127c7b279ca9e0021e8b3b085b55f1c8a50d673f05a64f4c64068526c1); labels.push("NEW:MOR Scan");
        ids.push(0x8ad2a8ad7c0b4554588503d38796892e820eb844814a239aa64ae85b17d4cd86); labels.push("OLD:MOR Scan");
        ids.push(0x938ab37a0a27085f20340b0974e204cabbd4daf031a35a1b45680c822c5d84da); labels.push("NEW:Builder");
        ids.push(0x4d836d856296621c88cc95797377627d4dedf9acb5df2432560f87352bc17040); labels.push("OLD:Builder");
        ids.push(0x3799de8f76b0901c140fbb1718c8b7adaf806ca7f215ff03aa6bcb2b79f26872); labels.push("NEW:Subnet");
        ids.push(0x79c12ab34ed1841428e41008ccc9250a288735a638da8d1467d420f4f2adfb76); labels.push("OLD:Subnet");
        ids.push(0xe8e68efd4c193f59bb1e01e1f7b2af81543f500c409e645bc6d46d302947e72f); labels.push("NEW:Staking MOR");
        ids.push(0x5c6940a27f2ad5008dac0767b3ea125c448828fd9ad9a19929fdc46d6015a5a2); labels.push("OLD:Staking MOR");
        ids.push(0xaf3f7b123119e01259f866fe0cadbaf6441a6a6097655f0e9d6281097780493a); labels.push("NEW:MOR Staking v2");
        ids.push(0x1f8c32c839566819f0d23919593dace77b82edc7e852c213146e3cdf9c903ffd); labels.push("OLD:MOR Staking v2");
        ids.push(0x5f06e227c95c8088357db43cd62842cd8ba9f545705c6810911f2e3735cd2906); labels.push("NEW:Inference API");
        ids.push(0xaf163a9f0fbed5e2339b6f254123232d7cc5bb333dc9ae11d7ba343a97692ba5); labels.push("OLD:Inference API");
        ids.push(0x3d6beefbc9a61aa05a2aebabfeb0ef2eae236f952682ae7265c1f31517622c76); labels.push("NEW:MOR Inference");
        ids.push(0x73277677d4b0655390417fbb683195d23b918800917afca809aca1e5ceb78767); labels.push("OLD:MOR Inference");
        ids.push(0xe794b9345bef007054c32e5f1c5761fe7e1d3483d3ed47b9218ddb4d48c2a7af); labels.push("NEW:Agent Marketplace");
        ids.push(0x6adfd5a3b262be9594c2764fcf6614a45de49a7d6ad6db4eaf291f41d9fa4e4e); labels.push("OLD:Agent Marketplace");
        ids.push(0xe8073d1f852276179f0f4ec8273b60dd4996609eaede7ae8f6e78919237d9f76); labels.push("NEW:Smart Agents");
        ids.push(0xd89ef4aa6dea61e42b33b4a0a936df4a8a918945c8a64bc7e2b92e1164e2dcd9); labels.push("OLD:Smart Agents");
        ids.push(0x8cbf5b0acd32a66e1f3506ea24ef5d4076274be461ca1a576c3c3bd5216e3f58); labels.push("NEW:Morpheus Builders");
        ids.push(0x642dcf286acb0abea2790cbc4121691da65e31c122c39789e0372dec11ec63c4); labels.push("OLD:Morpheus Builders");
        ids.push(0x3902987bcae17daeb5c2e0aa01853df2b8eecb60fe87cc68d69ae2f064560ecd); labels.push("NEW:Builder Rewards");
        ids.push(0x69b2f74549c85ef84c95aceff59c7f25ebbf2b4f7cd3afebd5e1b30f442ab71f); labels.push("OLD:Builder Rewards");
        ids.push(0x4e862752c9c7354d2245c127ab72c423b2f1290c77f67cdd49482c8e672be3f7); labels.push("NEW:Ecosystem");
        ids.push(0x144cd6a368f87a18499c81b0ae43c7edef18cd1af639ce356ab8043978756d22); labels.push("OLD:Ecosystem");
        ids.push(0x2c4139e349dffa2e96f8e96544d6c270920f88ce14d97ba967e2d79555819bdf); labels.push("NEW:Growth");
        ids.push(0xb7b427b85e2de741816a5c767978f49dec5af8a9c1c0d4a84bf8ea656da81201); labels.push("OLD:Growth");
        ids.push(0x1cea993e2c06a60d01fc9e461519d3ebaea16e4f89bd3c3ff77a47479aa53fa2); labels.push("NEW:MOR Growth");
        ids.push(0x0fd641f4a21eefe23c12a4e179b7dc251e2cbe5604f9f68c687d0aa564aef60d); labels.push("OLD:MOR Growth");
        ids.push(0x6c4445ef2f8cbe73af1cd0dc013112f6b6d928ffa95d976282574d19da97f823); labels.push("NEW:Community");
        ids.push(0x8f5d825fbb3e9141b62b618d4c2a3287ba17f74989e1b9738be30deedbaa88fd); labels.push("OLD:Community");
        ids.push(0xcb5b8b2c19b19bc09de3761045aed38d25b64c5fed366bf3f0a55d536a7bfd65); labels.push("NEW:MOR Community");
        ids.push(0x9d66b933bf0c002dbe4124c4da2cebbd9bba725d3fd3fff2ba30e7a481ff45dc); labels.push("OLD:MOR Community");
    }

    function test_measure() public {
        console.log("=== MO-C-02 STEP 1 MEASUREMENT, Base block", FORK_BLOCK);
        console.log("block.timestamp:", block.timestamp);
        console.log("builders version:", builders.version());
        console.log("treasury version:", treasury.version());
        console.log("buildersTreasury():", builders.buildersTreasury());
        console.log("rewardPool():", builders.rewardPool());
        console.log("depositToken():", builders.depositToken());
        console.log("treasury rewardToken():", treasury.rewardToken());
        console.log("treasury builders():", treasury.builders());
        console.log("networkShare (of 1e25):", builders.networkShare());

        uint256 treasuryBal = IERC20(MOR).balanceOf(TREASURY);
        console.log("TREASURY MOR BALANCE (wei):", treasuryBal);
        console.log("treasury lifetime distributedRewards (wei):", treasury.distributedRewards());

        (, uint256 rate, uint256 totalDeposited, ) = builders.allSubnetsData();
        (uint256 dist, uint256 undist, uint256 claimed, uint128 lastUpdate) = builders.allSubnetsDataV4();
        console.log("allSubnetsData.rate:", rate);
        console.log("allSubnetsData.totalDeposited (wei):", totalDeposited);
        console.log("V4 distributedRewards (wei):", dist);
        console.log("V4 undistributedRewards (wei):", undist);
        console.log("V4 claimedRewards (wei):", claimed);
        console.log("V4 lastUpdate:", uint256(lastUpdate));

        uint256 totalCurrent = builders.getCurrentSubnetsRewards();
        console.log("AGGREGATE getCurrentSubnetsRewards (wei):", totalCurrent);

        (uint256 feePart, address feeTreasury) = IFeeConfig(builders.feeConfig())
            .getFeeAndTreasuryForOperation(BUILDERS, bytes32("claim"));
        console.log("claim feePart (of 1e25):", feePart);
        console.log("claim feeTreasury:", feeTreasury);

        IRewardPool rp = IRewardPool(builders.rewardPool());
        (uint128 payoutStart, uint128 decreaseInterval, uint256 initialReward, uint256 rewardDecrease, bool isPublic) =
            rp.rewardPools(3);
        console.log("RewardPool[3] payoutStart:", uint256(payoutStart));
        console.log("RewardPool[3] decreaseInterval:", uint256(decreaseInterval));
        console.log("RewardPool[3] initialReward (wei):", initialReward);
        console.log("RewardPool[3] rewardDecrease (wei):", rewardDecrease);
        console.log("RewardPool[3] isPublic:", isPublic);
        uint128 nowTs = uint128(block.timestamp);
        uint256 rawDay = rp.getPeriodRewards(3, nowTs - 86400, nowTs);
        console.log("RewardPool[3] raw rewards last 24h (wei):", rawDay);
        console.log("  x networkShare = builders accrual/day (wei):", rawDay * builders.networkShare() / 1e25);

        uint256 sumDeposited = 0;
        uint256 sumCurrent = 0;
        uint256 active = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            (, uint256 deposited, , , uint256 storedPending) = builders.subnetsData(ids[i]);
            if (deposited == 0 && storedPending == 0) continue;
            uint256 cur = builders.getCurrentSubnetRewards(ids[i]);
            if (cur == 0 && deposited == 0) continue;
            active++;
            sumDeposited += deposited;
            sumCurrent += cur;
            console.log("SUBNET", labels[i]);
            console.log("  id:", vm.toString(ids[i]));
            console.log("  deposited (wei):", deposited);
            console.log("  currentRewards (wei):", cur);
        }
        console.log("=== ENUMERATION SUMMARY");
        console.log("candidate IDs scanned:", ids.length);
        console.log("active subnets found:", active);
        console.log("SUM deposited enumerated (wei):", sumDeposited);
        console.log("totalDeposited contract (wei):", totalDeposited);
        console.log("SUM currentRewards enumerated (wei):", sumCurrent);
        console.log("AGGREGATE currentRewards (wei):", totalCurrent);
        console.log("TREASURY BALANCE (wei):", treasuryBal);
        console.log("SHORTFALL vs aggregate (wei):", totalCurrent - treasuryBal);
        console.log("SHORTFALL vs enumerated per-subnet sum (wei):", sumCurrent - treasuryBal);
        // Rewards-side identity, conservative direction: enumerated per-subnet
        // claimable must cover the aggregate view (within 1 MOR of lens dust).
        assertTrue(sumCurrent + 1e18 >= totalCurrent, "enumerated claimable does not cover aggregate");
        assertTrue(totalCurrent > treasuryBal, "no shortfall vs aggregate at pinned block");
        assertTrue(sumCurrent > treasuryBal, "no shortfall vs per-subnet sum at pinned block");
    }
}
