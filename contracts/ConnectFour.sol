// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";

enum FieldStatus {
    EMPTY,
    PLAYER1,
    PLAYER2
}

enum Winner {
    NONE,
    PLAYER1,
    PLAYER2,
    DRAW
}

struct Game {
    uint256 gameId;
    uint256 creatingTime;
    uint256 rewardPool;
    address player1;
    address player2;
    address nextMove;
    bool isStarted;
    bool gameOver;
    FieldStatus[7][6] gameBoard;
    Winner winner;
}

contract ConnectFour is Initializable, OwnableUpgradeable {
    bool public gamesEnabled;
    uint256 public gameCounter = 0;
    uint256 MINIMUM_ENTRY_FEE;
    uint256 public commission;

    mapping(address => uint256) public balance;
    Game[] public games;

    modifier notPaused() {
        require(gamesEnabled, "All games are paused.");
        _;
    }

    event GameStarted(uint256 gameId, address player1, uint256 entryFee);
    event JoinedGame(uint256 gameId, address player2);
    event MadeMove(uint256 gameId, uint8 colNum, address player);
    event HaveWinner(uint256 gameId, Winner winner, uint256 reward);
    event HaveDraw(uint256 gameId, address player1, address player2, uint256 reward);
    event GameCancelled(uint256 gameId, address player1);

    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _commission, uint256 _MINIMUM_ENTRY_FEE) public initializer {
        __Ownable_init(msg.sender);
        require(_commission < 50, "Commission should be < 50.");
        require(_commission >= 0, "Commission should be >= 0.");
        require(_MINIMUM_ENTRY_FEE >= 100, "Minimum fee should be >= 100.");
        commission = _commission;
        MINIMUM_ENTRY_FEE = _MINIMUM_ENTRY_FEE;
        gamesEnabled = true;
        gameCounter = 0;

        Game memory game;
        games.push(game);
    }

    // function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getGame(uint256 _gameId) public view returns (Game memory) {
        require(_gameId <= gameCounter, "Game does not exist.");
        return games[_gameId];
    }

    function startGame() external payable notPaused {
        require(msg.value > MINIMUM_ENTRY_FEE, "Not enough entry fee.");

        // user deposits entry fee to the contract
        (bool sent,) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        gameCounter++;
        Game memory game;
        game.gameId = gameCounter;
        game.player1 = msg.sender;
        game.creatingTime = block.timestamp;
        game.rewardPool = msg.value;
        game.nextMove = msg.sender;
        games.push(game);

        emit GameStarted(game.gameId, game.player1, msg.value);
    }

    function joinGame(uint256 _gameId) external payable notPaused {
        Game memory game = games[_gameId];
        require(!game.isStarted, "Already started.");
        require(msg.value == game.rewardPool, "Not enough entry fee.");
        require(game.player1 != msg.sender, "You are already player 1.");

        // user deposits entry fee to the contract
        (bool sent,) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        game.player2 = msg.sender;
        game.rewardPool += msg.value;
        game.isStarted = true;
        games[_gameId] = game;

        emit JoinedGame(_gameId, msg.sender);
    }

    function makeMove(uint256 _gameId, uint8 _colNum) public notPaused {
        Game memory game = games[_gameId];
        require(game.isStarted, "Not started yet.");
        require(game.winner == Winner.NONE, "Game is finished.");
        require(game.nextMove == msg.sender, "Not your turn!");
        require(_colNum < 7, "Invalid column");

        require(game.gameBoard[0][_colNum] == FieldStatus.EMPTY, "Cell is not empty!");
        FieldStatus status = msg.sender == game.player1 ? FieldStatus.PLAYER1 : FieldStatus.PLAYER2;

        for (uint8 i = 5; i >= 0; i--) {
            if (game.gameBoard[i][_colNum] == FieldStatus.EMPTY) {
                game.gameBoard[i][_colNum] = status;
                break;
            }
        }
        game.nextMove = game.player1 == msg.sender ? game.player2 : game.player1;
        emit MadeMove(_gameId, _colNum, msg.sender);
        game.winner = isGameFinished(game.gameBoard);

        if (game.winner != Winner.NONE) {
            giveRewards(game.gameId, game.winner, game.rewardPool, game.player1, game.player2);
            game.gameOver = true;
        }
        games[_gameId] = game;
    }

    function giveRewards(uint256 _gameId, Winner _winner, uint256 _rewardPool, address _player1, address _player2)
        private
    {
        if (_winner == Winner.PLAYER1) {
            uint256 reward = (_rewardPool * (100 - commission)) / 100;
            uint256 com = (_rewardPool * commission) / 100;
            balance[_player1] += reward;
            balance[address(this)] += com;
            emit HaveWinner(_gameId, _winner, reward);
        } else if (_winner == Winner.PLAYER2) {
            uint256 reward = (_rewardPool * (100 - commission)) / 100;
            uint256 com = (_rewardPool * commission) / 100;
            balance[_player2] += reward;
            balance[address(this)] += com;
            emit HaveWinner(_gameId, _winner, reward);
        } else if (_winner == Winner.DRAW) {
            uint256 reward = (_rewardPool / 2);
            balance[_player1] += reward;
            balance[_player2] += reward;
            emit HaveDraw(_gameId, _player1, _player2, reward);
        }
    }

    function claimRewards(uint256 _amount) public payable {
        require(balance[msg.sender] >= _amount, "Not enough balance.");
        balance[msg.sender] -= _amount;
        (bool sent,) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Failed to claim rewards.");
    }

    function withdrawCommisions(uint256 _amount) public payable onlyOwner {
        require(balance[address(this)] >= _amount, "Not enough balance.");
        balance[address(this)] -= _amount;
        (bool sent,) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Failed to withdraw.");
    }

    function cancelGame(uint256 _gameId) external {
        Game memory game = games[_gameId];
        require(!game.isStarted, "Game is started.");
        require(game.creatingTime + 1 days < block.timestamp, "Should pass 1 day.");
        require(game.player1 == msg.sender, "Not your game.");
        (bool sent,) = payable(msg.sender).call{value: game.rewardPool}("");
        require(sent, "Failed to send.");

        delete games[_gameId];
        emit GameCancelled(_gameId, msg.sender);
    }

    // pause/continue all games by owner
    function toggleContract() public onlyOwner {
        gamesEnabled = !gamesEnabled;
    }

    function isGameFinished(FieldStatus[7][6] memory _gameBoard) private pure returns (Winner) {
        Winner player = winnerInColmn(_gameBoard);
        if (player != Winner.NONE) {
            return player;
        }

        player = winnerInRow(_gameBoard);
        if (player != Winner.NONE) {
            return player;
        }

        player = winnerInDiagonal(_gameBoard);
        if (player != Winner.NONE) {
            return player;
        }

        if (isGameBoardFull(_gameBoard)) {
            return Winner.DRAW;
        }

        return Winner.NONE;
    }

    function winnerInColmn(FieldStatus[7][6] memory _gameBoard) private pure returns (Winner) {
        for (uint8 i = 0; i < 7; i++) {
            for (uint8 j = 0; j <= 2; j++) {
                if (
                    _gameBoard[j][i] == FieldStatus.PLAYER1 && _gameBoard[j + 1][i] == FieldStatus.PLAYER1
                        && _gameBoard[j + 2][i] == FieldStatus.PLAYER1 && _gameBoard[j + 3][i] == FieldStatus.PLAYER1
                ) {
                    return Winner.PLAYER1;
                }
                if (
                    _gameBoard[j][i] == FieldStatus.PLAYER2 && _gameBoard[j + 1][i] == FieldStatus.PLAYER2
                        && _gameBoard[j + 2][i] == FieldStatus.PLAYER2 && _gameBoard[j + 3][i] == FieldStatus.PLAYER2
                ) {
                    return Winner.PLAYER2;
                }
            }
        }
        return Winner.NONE;
    }

    function winnerInRow(FieldStatus[7][6] memory _gameBoard) private pure returns (Winner) {
        for (uint8 i = 0; i <= 3; i++) {
            for (uint8 j = 0; j < 6; j++) {
                if (
                    _gameBoard[j][i] == FieldStatus.PLAYER1 && _gameBoard[j][i + 1] == FieldStatus.PLAYER1
                        && _gameBoard[j][i + 2] == FieldStatus.PLAYER1 && _gameBoard[j][i + 3] == FieldStatus.PLAYER1
                ) {
                    return Winner.PLAYER1;
                }
                if (
                    _gameBoard[j][i] == FieldStatus.PLAYER2 && _gameBoard[j][i + 1] == FieldStatus.PLAYER2
                        && _gameBoard[j][i + 2] == FieldStatus.PLAYER2 && _gameBoard[j][i + 3] == FieldStatus.PLAYER2
                ) {
                    return Winner.PLAYER2;
                }
            }
        }
        return Winner.NONE;
    }

    function winnerInDiagonal(FieldStatus[7][6] memory _gameBoard) private pure returns (Winner) {
        // Check descending diagonals (top-left to bottom-right)
        for (uint8 row = 0; row <= 2; row++) {
            for (uint8 col = 0; col <= 3; col++) {
                if (
                    _gameBoard[row][col] == FieldStatus.PLAYER1 && _gameBoard[row + 1][col + 1] == FieldStatus.PLAYER1
                        && _gameBoard[row + 2][col + 2] == FieldStatus.PLAYER1
                        && _gameBoard[row + 3][col + 3] == FieldStatus.PLAYER1
                ) {
                    return Winner.PLAYER1;
                }
                if (
                    _gameBoard[row][col] == FieldStatus.PLAYER2 && _gameBoard[row + 1][col + 1] == FieldStatus.PLAYER2
                        && _gameBoard[row + 2][col + 2] == FieldStatus.PLAYER2
                        && _gameBoard[row + 3][col + 3] == FieldStatus.PLAYER2
                ) {
                    return Winner.PLAYER2;
                }
            }
        }

        // Check ascending diagonals (bottom-left to top-right)
        for (uint8 row = 3; row < 6; row++) {
            for (uint8 col = 0; col <= 3; col++) {
                if (
                    _gameBoard[row][col] == FieldStatus.PLAYER1 && _gameBoard[row - 1][col + 1] == FieldStatus.PLAYER1
                        && _gameBoard[row - 2][col + 2] == FieldStatus.PLAYER1
                        && _gameBoard[row - 3][col + 3] == FieldStatus.PLAYER1
                ) {
                    return Winner.PLAYER1;
                }
                if (
                    _gameBoard[row][col] == FieldStatus.PLAYER2 && _gameBoard[row - 1][col + 1] == FieldStatus.PLAYER2
                        && _gameBoard[row - 2][col + 2] == FieldStatus.PLAYER2
                        && _gameBoard[row - 3][col + 3] == FieldStatus.PLAYER2
                ) {
                    return Winner.PLAYER2;
                }
            }
        }

        return Winner.NONE;
    }

    function isGameBoardFull(FieldStatus[7][6] memory _gameBoard) private pure returns (bool) {
        for (uint8 i = 0; i < 6; i++) {
            for (uint8 j = 0; j < 7; j++) {
                if (_gameBoard[i][j] == FieldStatus.EMPTY) {
                    return false;
                }
            }
        }
        return true;
    }

    function getGameBoard(uint256 _gameId) public view returns (FieldStatus[7][6] memory) {
        FieldStatus[7][6] memory gameBoard = games[_gameId].gameBoard;
        return gameBoard;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlayerBalance(address _address) public view returns (uint256) {
        return balance[_address];
    }

    function getGames() public view returns (Game[] memory) {
        return games;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
