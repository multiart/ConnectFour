// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Test, console, StdCheats} from "forge-std/Test.sol";
import "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/ConnectFour.sol";

contract ConnectFourTest is Test {
    ConnectFour connectFour;
    address public deployer;
    address public player1;
    address public player2;
    uint256 constant ENTRY_FEE = 1000;
    uint256 constant COMMISSION = 10; // 10%

    function setUp() public {
        deployer = makeAddr("deployer");
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        vm.deal(deployer, 100 ether);
        vm.deal(player1, 100 ether);
        vm.deal(player2, 100 ether);

        vm.startPrank(deployer);
        ConnectFour implementation = new ConnectFour();
        ERC1967Proxy proxy =
            new ERC1967Proxy(address(implementation), abi.encodeCall(ConnectFour.initialize, (10, 100)));

        connectFour = ConnectFour(payable(address(proxy)));
        vm.stopPrank();
    }

    function testCreateGameAndJoinWithDiffAccount() public {
        prepareGame();
        Game memory game = connectFour.getGame(1);
        assertEq(game.isStarted, true);
        vm.stopPrank();
    }

    function testCreateGameAndJoinWithSameAccount() public {
        vm.prank(player1);
        connectFour.startGame{value: 160}();
        vm.prank(player1);
        vm.expectRevert("You are already player 1.");
        connectFour.joinGame{value: 160}(1);
        vm.stopPrank();
    }

    function testPlayTheGameUntilP1WinsByColumn() public {
        prepareGame();
        for (uint8 i = 0; i < 3; i++) {
            makeMove(1, player1, 1);
            makeMove(1, player2, 2);
        }
        makeMove(1, player1, 1);
        Game memory game = connectFour.getGame(1);
        assertEq(uint256(game.winner), uint256(Winner.PLAYER1));
        assertEq(game.gameOver, true);
    }

    function testPlayTheGameUntilP2WinsByColumn() public {
        prepareGame();
        for (uint8 i = 0; i < 3; i++) {
            makeMove(1, player1, 1);
            makeMove(1, player2, 2);
        }
        makeMove(1, player1, 6);
        makeMove(1, player2, 2);
        Game memory game = connectFour.getGame(1);
        assertEq(uint256(game.winner), uint256(Winner.PLAYER2));
        assertEq(game.gameOver, true);
    }

    function testPlayTheGameUntilP1WinsByRow() public {
        prepareGame();
        for (uint8 i = 0; i < 3; i++) {
            makeMove(1, player1, i);
            makeMove(1, player2, i);
        }
        makeMove(1, player1, 3);
        Game memory game = connectFour.getGame(1);
        assertEq(uint256(game.winner), uint256(Winner.PLAYER1));
        assertEq(game.gameOver, true);
    }

    function testPlayTheGameUntilP2WinsByRow() public {
        prepareGame();
        for (uint8 i = 0; i < 3; i++) {
            makeMove(1, player1, i);
            makeMove(1, player2, i);
        }
        makeMove(1, player1, 4);
        makeMove(1, player2, 3);
        makeMove(1, player1, 5);
        makeMove(1, player2, 3);

        Game memory game = connectFour.getGame(1);
        assertEq(uint256(game.winner), uint256(Winner.PLAYER2));
        assertEq(game.gameOver, true);
    }

    function testPlayTheGameUntilP1WinsByLefToRightDiagonal() public {
        prepareGame();

        makeMove(1, player1, 2);
        makeMove(1, player2, 3);
        makeMove(1, player1, 3);
        makeMove(1, player2, 4);
        makeMove(1, player1, 4);
        makeMove(1, player2, 5);
        makeMove(1, player1, 4);
        makeMove(1, player2, 5);
        makeMove(1, player1, 6);
        makeMove(1, player2, 5);
        makeMove(1, player1, 5);
        Game memory game = connectFour.getGame(1);
        assertEq(uint256(game.winner), uint256(Winner.PLAYER1));
        assertEq(game.gameOver, true);
    }

    function testPlayTheGameUntilP1WinsByRightToLeftDiagonal() public {
        prepareGame();

        makeMove(1, player1, 6);
        makeMove(1, player2, 5);
        makeMove(1, player1, 5);
        makeMove(1, player2, 4);
        makeMove(1, player1, 4);
        makeMove(1, player2, 3);
        makeMove(1, player1, 4);
        makeMove(1, player2, 3);
        makeMove(1, player1, 2);
        makeMove(1, player2, 3);
        makeMove(1, player1, 3);
        Game memory game = connectFour.getGame(1);
        assertEq(uint256(game.winner), uint256(Winner.PLAYER1));
        assertEq(game.gameOver, true);
    }

    function testPlayTheGameUntilP2WinsByLefToRightDiagonal() public {
        prepareGame();
        makeMove(1, player1, 6);
        makeMove(1, player2, 1);
        makeMove(1, player1, 2);
        makeMove(1, player2, 2);
        makeMove(1, player1, 3);
        makeMove(1, player2, 4);
        makeMove(1, player1, 3);
        makeMove(1, player2, 3);
        makeMove(1, player1, 4);
        makeMove(1, player2, 5);
        makeMove(1, player1, 4);
        makeMove(1, player2, 4);
        Game memory game = connectFour.getGame(1);
        assertEq(uint256(game.winner), uint256(Winner.PLAYER2));
        assertEq(game.gameOver, true);
    }

    function testPlayTheGameUntilP2WinsByRightToLeftDiagonal() public {
        prepareGame();
        makeMove(1, player1, 6);
        makeMove(1, player2, 5);
        makeMove(1, player1, 4);
        makeMove(1, player2, 4);
        makeMove(1, player1, 3);
        makeMove(1, player2, 2);
        makeMove(1, player1, 3);
        makeMove(1, player2, 3);
        makeMove(1, player1, 2);
        makeMove(1, player2, 1);
        makeMove(1, player1, 2);
        makeMove(1, player2, 2);
        Game memory game = connectFour.getGame(1);
        assertEq(uint256(game.winner), uint256(Winner.PLAYER2));
        assertEq(game.gameOver, true);
    }

    function testPlayTheGameUntilDraw() public {
        prepareGame();

        for (uint8 i = 0; i < 2; i++) {
            makeMove(1, player1, 0);
            makeMove(1, player2, 1);
            makeMove(1, player1, 2);
            makeMove(1, player2, 3);
            makeMove(1, player1, 4);
            makeMove(1, player2, 5);
        }
        for (uint8 i = 0; i < 2; i++) {
            makeMove(1, player1, 6);
            makeMove(1, player2, 0);
            makeMove(1, player1, 1);
            makeMove(1, player2, 2);
            makeMove(1, player1, 3);
            makeMove(1, player2, 4);
            makeMove(1, player1, 5);
            makeMove(1, player2, 6);
        }
        for (uint8 i = 0; i < 2; i++) {
            makeMove(1, player1, 0);
            makeMove(1, player2, 1);
            makeMove(1, player1, 2);
            makeMove(1, player2, 3);
            makeMove(1, player1, 4);
            makeMove(1, player2, 5);
        }
        makeMove(1, player1, 6);
        makeMove(1, player2, 6);

        Game memory game = connectFour.getGame(1);
        assertEq(uint256(game.winner), uint256(Winner.DRAW));
        assertEq(game.gameOver, true);
    }

    function testRevertTxDueToPlayingTwice() public {
        vm.prank(player1);
        connectFour.startGame{value: 160}();
        vm.prank(player2);
        connectFour.joinGame{value: 160}(1);

        makeMove(1, player1, 6);
        vm.expectRevert("Not your turn!");
        makeMove(1, player1, 2);

        makeMove(1, player2, 2);
        vm.expectRevert("Not your turn!");
        makeMove(1, player2, 0);
    }

    function testRevertTxDueToSelectFilledColumn() public {
        vm.prank(player1);
        connectFour.startGame{value: 160}();
        vm.prank(player2);
        connectFour.joinGame{value: 160}(1);

        makeMove(1, player1, 0);
        makeMove(1, player2, 0);
        makeMove(1, player1, 0);
        makeMove(1, player2, 0);
        makeMove(1, player1, 0);
        makeMove(1, player2, 0);
        vm.expectRevert("Cell is not empty!");
        makeMove(1, player1, 0);
    }

    function testRevertTxDueToTryClaimingWithoutAnyReward() public {
        vm.prank(player1);
        vm.expectRevert("Not enough balance.");
        connectFour.claimRewards(100);
    }

    function testRevertDueToTryWithdrawFromContractByNormalUser() public {
        vm.prank(player1);
        connectFour.startGame{value: 1000}();

        vm.deal(player2, 1 ether);
        vm.prank(player2);
        connectFour.joinGame{value: 1000}(1);

        // Try to withdraw as non-owner
        vm.prank(player1);
        vm.expectRevert();
        connectFour.withdrawCommisions(100);
    }

    function testBalancesAreUpdatedBasedOnRewards() public {
        vm.prank(player1);
        connectFour.startGame{value: 1000}();

        vm.prank(player2);
        connectFour.joinGame{value: 1000}(1);

        // Play game until player1 wins
        vm.prank(player1);
        connectFour.makeMove(1, 0);
        vm.prank(player2);
        connectFour.makeMove(1, 1);
        vm.prank(player1);
        connectFour.makeMove(1, 0);
        vm.prank(player2);
        connectFour.makeMove(1, 1);
        vm.prank(player1);
        connectFour.makeMove(1, 0);
        vm.prank(player2);
        connectFour.makeMove(1, 1);
        vm.prank(player1);
        connectFour.makeMove(1, 0); // Player 1 wins

        // Calculate expected rewards
        uint256 totalPool = 2000;
        uint256 commission = (totalPool * 10) / 100; // 10% commission
        uint256 winnerReward = totalPool - commission;

        // Verify balances
        assertEq(connectFour.getPlayerBalance(player1), winnerReward);
        assertEq(connectFour.getPlayerBalance(player2), 0);
        assertEq(connectFour.getPlayerBalance(address(connectFour)), commission);
    }

    function testBalancesAreUpdatedBasedOnRewardsForDraw() public {
        vm.prank(player1);
        connectFour.startGame{value: 1000}();

        vm.prank(player2);
        connectFour.joinGame{value: 1000}(1);

        for (uint8 i = 0; i < 2; i++) {
            makeMove(1, player1, 0);
            makeMove(1, player2, 1);
            makeMove(1, player1, 2);
            makeMove(1, player2, 3);
            makeMove(1, player1, 4);
            makeMove(1, player2, 5);
        }
        for (uint8 i = 0; i < 2; i++) {
            makeMove(1, player1, 6);
            makeMove(1, player2, 0);
            makeMove(1, player1, 1);
            makeMove(1, player2, 2);
            makeMove(1, player1, 3);
            makeMove(1, player2, 4);
            makeMove(1, player1, 5);
            makeMove(1, player2, 6);
        }
        for (uint8 i = 0; i < 2; i++) {
            makeMove(1, player1, 0);
            makeMove(1, player2, 1);
            makeMove(1, player1, 2);
            makeMove(1, player2, 3);
            makeMove(1, player1, 4);
            makeMove(1, player2, 5);
        }
        makeMove(1, player1, 6);
        makeMove(1, player2, 6);

        // Play moves that lead to a draw
        // Note: You'll need to make specific moves that result in a draw
        // This is a simplified version - you should add actual moves that cause a draw
        // Game memory game = connectFour.getGame(1);
        // Fill the board in a way that causes a draw

        uint256 totalPool = 2000;
        uint256 expectedReward = totalPool / 2; // In draw, pool is split equally

        // Verify balances after draw
        assertEq(connectFour.getPlayerBalance(player1), expectedReward);
        assertEq(connectFour.getPlayerBalance(player2), expectedReward);
    }

    function testClaimRewardsByPlayer() public {
        vm.prank(player1);
        connectFour.startGame{value: 1000}();

        vm.prank(player2);
        connectFour.joinGame{value: 1000}(1);

        // Play until player1 wins
        vm.prank(player1);
        connectFour.makeMove(1, 0);
        vm.prank(player2);
        connectFour.makeMove(1, 1);
        vm.prank(player1);
        connectFour.makeMove(1, 0);
        vm.prank(player2);
        connectFour.makeMove(1, 1);
        vm.prank(player1);
        connectFour.makeMove(1, 0);
        vm.prank(player2);
        connectFour.makeMove(1, 1);
        vm.prank(player1);
        connectFour.makeMove(1, 0); // Player 1 wins

        // Calculate expected reward
        uint256 totalPool = 2000;
        uint256 commission = (totalPool * 10) / 100;
        uint256 winnerReward = totalPool - commission;

        // Get initial balance
        uint256 initialBalance = address(player1).balance;

        // Claim rewards
        vm.prank(player1);
        connectFour.claimRewards(winnerReward);

        // Verify balances
        assertEq(connectFour.getPlayerBalance(player1), 0);
        assertEq(address(player1).balance, initialBalance + winnerReward);
    }

    function testWithdrawCommisionByOwner() public {
        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);

        // Start and complete a game to generate commission
        // Player 1 starts game
        vm.prank(player1);
        connectFour.startGame{value: 1000}();

        // Player 2 joins game
        vm.prank(player2);
        connectFour.joinGame{value: 1000}(1);

        // Total pool is now 2000 wei

        // Make moves to finish the game with player1 winning
        // Player 1's moves
        vm.prank(player1);
        connectFour.makeMove(1, 0);

        vm.prank(player2);
        connectFour.makeMove(1, 1);

        vm.prank(player1);
        connectFour.makeMove(1, 0);

        vm.prank(player2);
        connectFour.makeMove(1, 1);

        vm.prank(player1);
        connectFour.makeMove(1, 0);

        vm.prank(player2);
        connectFour.makeMove(1, 1);

        vm.prank(player1);
        connectFour.makeMove(1, 0); // Player 1 wins with vertical line

        // Calculate expected commission (10% of 2000)
        uint256 expectedCommission = 200; // 2000 * 10%

        // Verify contract's commission balance
        assertEq(connectFour.getPlayerBalance(address(connectFour)), expectedCommission);

        // Get owner's initial balance
        address owner = connectFour.owner();
        uint256 initialOwnerBalance = address(owner).balance;

        // Owner withdraws commission
        vm.prank(owner);
        connectFour.withdrawCommisions(expectedCommission);

        // Verify commission was withdrawn
        assertEq(connectFour.getPlayerBalance(address(connectFour)), 0);
        assertEq(address(owner).balance, initialOwnerBalance + expectedCommission);
    }

    function testWithdrawCommisionByNonOwner() public {
        // Try to withdraw as non-owner
        vm.prank(player2);
        vm.expectRevert();
        connectFour.withdrawCommisions(100);
    }

    function testCancelGameByPlayer() public {
        vm.deal(player1, ENTRY_FEE);
        vm.prank(player1);
        connectFour.startGame{value: ENTRY_FEE}();

        // Advance time by 1 day
        vm.warp(block.timestamp + 1 days + 1);

        uint256 initialBalance = player1.balance;

        vm.prank(player1);
        connectFour.cancelGame(1);

        assertEq(player1.balance, initialBalance + ENTRY_FEE);
    }

    function testCannotCancelStartedGame() public {
        // Setup
        uint256 entryFee = 1000;
        vm.deal(player1, entryFee);
        vm.deal(player2, entryFee);

        // Start game
        vm.prank(player1);
        connectFour.startGame{value: entryFee}();

        // Join game
        vm.prank(player2);
        connectFour.joinGame{value: entryFee}(1);

        // Try to cancel started game
        vm.warp(block.timestamp + 1 days + 1);
        vm.prank(player1);
        vm.expectRevert("Game is started.");
        connectFour.cancelGame(1);
    }

    function testCannotCancelBeforeOneDay() public {
        // Setup
        uint256 entryFee = 1000;
        vm.deal(player1, entryFee);

        // Start game
        vm.prank(player1);
        connectFour.startGame{value: entryFee}();

        // Try to cancel game before 1 day
        vm.warp(block.timestamp + 1 days - 1);
        vm.prank(player1);
        vm.expectRevert("Should pass 1 day.");
        connectFour.cancelGame(1);
    }

    function testCannotCancelOtherPlayersGame() public {
        // Setup
        uint256 entryFee = 1000;
        vm.deal(player1, entryFee);

        // Start game as player1
        vm.prank(player1);
        connectFour.startGame{value: entryFee}();

        // Try to cancel game as player2
        vm.warp(block.timestamp + 1 days + 1);
        vm.prank(player2);
        vm.expectRevert("Not your game.");
        connectFour.cancelGame(1);
    }

    function testPauseContractByOwner() public {
        vm.prank(player1);
        connectFour.startGame{value: 160}();

        vm.prank(deployer);
        connectFour.toggleContract();
        assertEq(connectFour.gamesEnabled(), false);

        vm.prank(player2);
        vm.expectRevert("All games are paused.");
        connectFour.joinGame{value: 160}(1);
    }

    function testGetGamesArray() public {
        // Start a game as player1
        vm.deal(player1, 1 ether);
        vm.prank(player1);
        connectFour.startGame{value: 160}();

        // Join the game as player2
        vm.deal(player2, 1 ether);
        vm.prank(player2);
        connectFour.joinGame{value: 160}(1);

        // Get all games
        Game[] memory allGames = connectFour.getGames();

        // Assert array length (should be 2: initial empty game at index 0 and our created game)
        assertEq(allGames.length, 2);

        // Verify game at index 1 (our created game)
        Game memory game = allGames[1];
        assertEq(game.gameId, 1);
        assertEq(game.player1, player1);
        assertEq(game.player2, player2);
        assertEq(game.rewardPool, 320); // 160 from each player
        assertTrue(game.isStarted);
        assertFalse(game.gameOver);
        assertEq(uint256(game.winner), uint256(Winner.NONE));
    }

    function prepareGame() public {
        vm.prank(player1);
        connectFour.startGame{value: 160}();
        vm.prank(player2);
        connectFour.joinGame{value: 160}(1);
    }

    function makeMove(uint256 gameId, address player, uint8 column) public {
        vm.prank(player);
        connectFour.makeMove(gameId, column);
    }
}
