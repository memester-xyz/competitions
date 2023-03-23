// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseTest.sol";

import "../src/LensCompetitionHub.sol";
import "./LensCompetitionHubUpgradeTest.sol";

contract LensCompetitionHubTest is BaseTest {
    address immutable attacker = vm.addr(3);

    function setUp() public override {
        super.setUp();
    }

    function testSetGovernance() public {
        assertEq(lensCompetitionHub.governance(), governance);

        vm.prank(governance);
        lensCompetitionHub.setGovernance(userOne);

        assertEq(lensCompetitionHub.governance(), userOne);

        vm.prank(userOne);
        lensCompetitionHub.setGovernance(governance);

        assertEq(lensCompetitionHub.governance(), governance);
    }

    function testCannotSetGovernanceIfNotGovernance() public {
        assertEq(lensCompetitionHub.governance(), governance);

        vm.prank(attacker);
        vm.expectRevert(LensCompetitionHub.Unauthorized.selector);
        lensCompetitionHub.setGovernance(userOne);
    }

    function testWhitelistCompetition() public {
        assertTrue(lensCompetitionHub.competitionWhitelist(address(judgeCompetition)));

        vm.prank(governance);
        lensCompetitionHub.whitelistCompetition(address(judgeCompetition), false);

        assertFalse(lensCompetitionHub.competitionWhitelist(address(judgeCompetition)));
    }

    function testCannotWhitelistCompetitionIfNotGovernance() public {
        assertEq(lensCompetitionHub.governance(), governance);

        vm.startPrank(attacker);

        vm.expectRevert(LensCompetitionHub.Unauthorized.selector);
        lensCompetitionHub.whitelistCompetition(address(judgeCompetition), true);

        vm.expectRevert(LensCompetitionHub.Unauthorized.selector);
        lensCompetitionHub.whitelistCompetition(address(judgeCompetition), false);

        vm.stopPrank();
    }

    function testCanUpgrade() public {
        LensCompetitionHubUpgradeTest lensCompetitionHubUpgradeTest = new LensCompetitionHubUpgradeTest();

        vm.prank(governance);
        lensCompetitionHub.upgradeTo(address(lensCompetitionHubUpgradeTest));

        LensCompetitionHubUpgradeTest lensCompetitionHub = LensCompetitionHubUpgradeTest(address(lensCompetitionHub));

        assertEq(lensCompetitionHub.implementation(), address(lensCompetitionHubUpgradeTest));
    }

    function testCanWhitelistCompetitionAsAttackerAfterUpgrade() public {
        LensCompetitionHubUpgradeTest lensCompetitionHubUpgradeTest = new LensCompetitionHubUpgradeTest();

        vm.prank(governance);
        lensCompetitionHub.upgradeTo(address(lensCompetitionHubUpgradeTest));

        assertTrue(lensCompetitionHub.competitionWhitelist(address(judgeCompetition)));

        vm.startPrank(attacker);
        lensCompetitionHub.whitelistCompetition(address(judgeCompetition), false);
        assertFalse(lensCompetitionHub.competitionWhitelist(address(judgeCompetition)));

        lensCompetitionHub.whitelistCompetition(address(judgeCompetition), true);
        assertTrue(lensCompetitionHub.competitionWhitelist(address(judgeCompetition)));

        vm.stopPrank();
    }

    function testCannotUpgradeIfNotGovernance() public {
        vm.startPrank(attacker);

        vm.expectRevert(LensCompetitionHub.Unauthorized.selector);
        lensCompetitionHub.upgradeTo(address(0));

        vm.stopPrank();
    }
}
