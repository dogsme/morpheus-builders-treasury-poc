// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";

// Minimal interfaces against the DEPLOYED BuildersV4 / BuildersTreasuryV2 proxies
// on Base (Sourcify exact-match; project sources byte-identical to branch pin
// a4a8083 — see evidence/MO-C-02/correspondence.txt). Every call below is
// deployed-bytecode behaviour on a pinned-block fork.
interface IBuildersV4 {
    function subnets(bytes32) external view returns (string memory, address, uint128, uint128, uint128, uint256, address);
    function getCurrentSubnetRewards(bytes32) external view returns (uint256);
    function getCurrentSubnetsRewards() external view returns (uint256);
    function claim(bytes32, address) external;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

// MO-C-02 decisive sequence (QUEUE.md Step 2, shortfall branch):
// At the pinned block the Treasury balance (68,768.89 MOR) is BELOW total accrued
// pendingRewards (aggregate view 79,547.25 MOR; enumerated per-subnet sum
// 80,518.58 MOR). Eight subnets claim legitimately, in descending pending order,
// each through its OWN admin (fork-only impersonation of the subnet's own admin
// using the normal claim path — the QUEUE attacker model). The ninth — the
// "Protection Fund" subnet, pending 18,448.03 MOR — then cannot be paid in full
// and its claim reverts: its accrued rewards are locked until a top-up.
// A final simulated top-up (plain ERC20 transfer from this test contract, dealt
// the top-up amount — anyone can transfer MOR to the Treasury; this models the
// team's manual funding action) releases the victim's claim in full, bounding
// the impact as a recoverable lock, not a loss.
//
// Prank inventory (program rule: no privileged prank accounts). claim() is
// gated by BuildersV4 to each subnet's own admin/claimAdmin, so a claim can
// only ever be executed by that admin; there is no unprivileged third-party
// claim path to exercise instead. Every vm.prank below therefore impersonates
// an account doing exactly its own normal, unprivileged action:
//   - 8 pranks: each drainer subnet's own admin claiming its OWN subnet
//     (claim(id, admin) with msg.sender == that subnet's admin).
//   - 2 pranks: the victim subnet's own admin claiming its OWN subnet
//     (the reverting claim, then the post-top-up claim).
// No protocol-privileged account is impersonated anywhere: not the
// BuildersV4/Treasury owner (the Appendix-excluded multisig), not
// BuildersV4 or the Treasury themselves, not any fee or oracle role.
// The top-up uses no prank: the test contract is dealt the MOR and transfers
// it itself, modelling any holder funding the Treasury by plain transfer.
// The measurement test (MO-C-02-Measure.t.sol) uses no pranks at all —
// the insolvency itself (accruals > balance) is asserted from view calls.
contract MO_C_02_ClaimsTest is Test {
    uint256 constant FORK_BLOCK = 58452000;
    address constant BUILDERS = 0x42BB446eAE6dca7723a9eBdb81EA88aFe77eF4B9;
    address constant TREASURY = 0x9eba628581896ce086cb8f1A513ea6097A8FC561;
    address constant MOR = 0x7431aDa8a591C955a994a21710752EF9b882b8e3;
    bytes32 constant VICTIM = 0xf4a1ea01b4f52b7328a1665df387c9ffeced4c7a3233e7316302d0ba45a0eaba;

    IBuildersV4 builders = IBuildersV4(BUILDERS);
    bytes32[] drainers;
    string[] drainerLabels;

    function setUp() public {
        vm.createSelectFork("base", FORK_BLOCK);
        drainers.push(0x03fa50361370455816211100c40123006f5f15b53b290735edc0810fd61e77fd); drainerLabels.push("OLD:Morlord"); // pending at measure time: 14889050961604532064771 wei
        drainers.push(0xf8c784db930f5b824609b2a64bc7135b089666624ba6e3a8cca427eafcf572cd); drainerLabels.push("OLD:Venice"); // pending at measure time: 11147147621290671963291 wei
        drainers.push(0x96e624768600a7be0f2a82545d33c137ff3df2f377dc3fdf468308e5b977a72f); drainerLabels.push("OLD:MySuperAgent"); // pending at measure time: 9880592789825893347408 wei
        drainers.push(0x79611d94d04d7c5a4dcfa6733b4c096a918193b453b10688665088f5183723b1); drainerLabels.push("OLD:Nounspace"); // pending at measure time: 7460160898206221242467 wei
        drainers.push(0x63891e659ff2ae88fdaf6ff05f07ffbbd4ffbca089600564c7c6c784a96ab0e5); drainerLabels.push("OLD:Wire Network"); // pending at measure time: 3836831107314165127355 wei
        drainers.push(0xc8a0087b1d7e5b3a2f18b2d79fd2fbf187802af7370b928ff0e6eacf47341299); drainerLabels.push("OLD:PALcapital"); // pending at measure time: 1616089546723957971214 wei
        drainers.push(0x8036bbb740074d06db6b7741fcf9f52bd25846b9fc7e0a10c983c51530eaa999); drainerLabels.push("OLD:MOR Builders"); // pending at measure time: 1132420377726787220169 wei
        drainers.push(0x523f1bb39a49927241fcd48dacab09dd72c218bf1e3a01e3206264fd666f0d79); drainerLabels.push("OLD:OLAS"); // pending at measure time: 1044009103956937057319 wei
    }

    function _adminOf(bytes32 id) internal view returns (address) {
        (, address admin, , , , , ) = builders.subnets(id);
        return admin;
    }

    function test_fcfs_lock() public {
        uint256 bal0 = IERC20(MOR).balanceOf(TREASURY);
        uint256 agg0 = builders.getCurrentSubnetsRewards();
        uint256 victimPending = builders.getCurrentSubnetRewards(VICTIM);
        console.log("=== MO-C-02 TWO-CLAIM / FCFS LOCK TEST, Base block", FORK_BLOCK);
        console.log("treasury balance at start (wei):", bal0);
        console.log("aggregate accruals at start (wei):", agg0);
        console.log("victim (Protection Fund) pending (wei):", victimPending);
        assertEq(bal0, 68768894862118286295836, "treasury balance != Step-1 measurement");
        assertTrue(victimPending > 0, "victim has no pending");

        uint256 totalPaid = 0;
        for (uint256 i = 0; i < drainers.length; i++) {
            bytes32 id = drainers[i];
            uint256 pending = builders.getCurrentSubnetRewards(id);
            address admin = _adminOf(id);
            uint256 before = IERC20(MOR).balanceOf(TREASURY);
            vm.prank(admin);
            builders.claim(id, admin);
            uint256 paid = before - IERC20(MOR).balanceOf(TREASURY);
            totalPaid += paid;
            console.log("CLAIM OK", drainerLabels[i]);
            console.log("  pending (wei):", pending);
            console.log("  paid from treasury (wei):", paid);
            assertEq(paid, pending, "claim not paid in full");
            assertEq(builders.getCurrentSubnetRewards(id), 0, "pending not zeroed after claim");
        }

        uint256 remaining = IERC20(MOR).balanceOf(TREASURY);
        console.log("total paid to drainers (wei):", totalPaid);
        console.log("treasury remaining (wei):", remaining);
        console.log("victim pending (wei):", victimPending);
        assertTrue(remaining < victimPending, "treasury still covers victim - lock not reached");

        // Victim claim reverts: Treasury cannot cover its accrued pending.
        address vAdmin = _adminOf(VICTIM);
        console.log("victim admin:", vAdmin);
        vm.prank(vAdmin);
        vm.expectRevert();
        builders.claim(VICTIM, vAdmin);
        console.log("VICTIM CLAIM REVERTED as expected");

        // The failed claim does NOT erase the accrual: still fully pending (locked, not lost).
        assertEq(builders.getCurrentSubnetRewards(VICTIM), victimPending, "victim pending changed after failed claim");
        console.log("victim pending after failed claim (wei):", builders.getCurrentSubnetRewards(VICTIM));
        console.log("LOCKED SHORTFALL for victim = pending - remaining (wei):", victimPending - remaining);

        // Recovery by top-up: this contract is dealt the MOR and transfers it
        // itself — a plain ERC20 transfer, the only funding path the Treasury
        // has, open to any holder. No impersonation involved.
        uint256 topup = victimPending - remaining + 1e18;
        deal(MOR, address(this), topup);
        IERC20(MOR).transfer(TREASURY, topup);
        console.log("top-up transferred (wei):", topup);

        uint256 vBalBefore = IERC20(MOR).balanceOf(vAdmin);
        vm.prank(vAdmin);
        builders.claim(VICTIM, vAdmin);
        uint256 vGot = IERC20(MOR).balanceOf(vAdmin) - vBalBefore;
        console.log("victim claim after top-up paid (wei):", vGot);
        assertEq(vGot, victimPending, "victim not paid in full after top-up");
        assertEq(builders.getCurrentSubnetRewards(VICTIM), 0, "victim pending not zeroed after top-up claim");
        console.log("=== FCFS LOCK DEMONSTRATED AND RECOVERED BY TOP-UP");
    }
}
