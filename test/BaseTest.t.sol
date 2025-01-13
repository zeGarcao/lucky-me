// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {Pool} from "@lucky-me/Pool.sol";
import {TwabController} from "@lucky-me/TwabController.sol";
import {DrawManager} from "@lucky-me/DrawManager.sol";
import {AavePoolMock} from "./mocks/AavePoolMock.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {LinkMock} from "./mocks/LinkMock.sol";
import {SwapRouterMock} from "./mocks/SwapRouterMock.sol";
import {QuoterMock} from "./mocks/QuoterMock.sol";
import {VRFWrapperMock} from "./mocks/VRFWrapperMock.sol";
import {ONE_HUNDRED_PERCENT_BPS} from "@lucky-me/utils/Constants.sol";
import {UniformRandomNumber} from "@lucky-me/libraries/UniformRandomNumber.sol";

abstract contract BaseTest is Test {
    ERC20Mock usdc;
    ERC20Mock aUsdc;
    LinkMock link;
    AavePoolMock aavePool;
    Pool pool;
    TwabController twabController;
    DrawManager drawManager;
    SwapRouterMock swapRouter;
    QuoterMock quoter;
    VRFWrapperMock vrfWrapper;

    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address carol = makeAddr("carol");
    address bob = makeAddr("bob");
    address rando = makeAddr("rando");
    address keeper = makeAddr("keeper");

    address[] users;

    function setUp() public virtual {
        // Skip 1 week in time
        skip(1 weeks);

        // Deploy mocks
        usdc = new ERC20Mock("USDC Mock", "USDC", 6);
        aUsdc = new ERC20Mock("aUSDC Mock", "aUSDC", 6);
        link = new LinkMock("LINK Mock", "LINK");
        aavePool = new AavePoolMock(address(aUsdc));
        quoter = new QuoterMock();
        swapRouter = new SwapRouterMock(address(quoter));
        vrfWrapper = new VRFWrapperMock(address(link));

        // Set luck factor list
        uint256[] memory luckFactor = new uint256[](13);
        luckFactor[0] = 1000;
        luckFactor[1] = 1000;
        luckFactor[2] = 1000;
        luckFactor[3] = 5000;
        luckFactor[4] = 5000;
        luckFactor[5] = 5000;
        luckFactor[6] = 5000;
        luckFactor[7] = 10000;
        luckFactor[8] = 10000;
        luckFactor[9] = 10000;
        luckFactor[10] = 10000;
        luckFactor[11] = 10000;
        luckFactor[12] = 15000;

        // Deploy Lucky Me pool
        vm.prank(owner);
        pool = new Pool(
            address(usdc),
            address(aavePool),
            address(aUsdc),
            keeper,
            address(vrfWrapper),
            address(swapRouter),
            address(quoter),
            block.timestamp,
            luckFactor
        );

        // Get twab controller & draw manager
        twabController = TwabController(pool.TWAB_CONTROLLER());
        drawManager = DrawManager(pool.DRAW_MANAGER());

        // Set up users account with USDC
        users.push(alice);
        users.push(carol);
        users.push(bob);
        users.push(rando);
        for (uint8 i; i < users.length; ++i) {
            address user = users[i];
            usdc.mint(user, 1_000_000e6);
            vm.prank(user);
            usdc.approve(address(pool), 1_000_000e6);
        }

        // Set up swap router mock with LINK
        link.mint(address(swapRouter), 1_000_000e18);
    }

    function _awardDraw(uint256 _drawId) internal {
        vm.prank(address(pool));
        drawManager.awardDraw(_drawId);

        _fulfillRandomWords();
    }

    function _fulfillRandomWords() internal {
        uint256 requestId = vrfWrapper.lastRequestId();
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = uint256(keccak256(abi.encode(requestId)));

        vrfWrapper.fulfillRandomWords(address(drawManager), requestId, randomWords);
    }

    function _getUsdcAmountIn(uint256 _linkAmountOut, uint24 _poolFee, uint256 _slippage)
        internal
        view
        returns (uint256)
    {
        uint256 usdcAmountIn =
            quoter.quoteExactOutputSingle(address(usdc), drawManager.getLinkTokenAddress(), _poolFee, _linkAmountOut, 0);

        return (usdcAmountIn * (ONE_HUNDRED_PERCENT_BPS + _slippage)) / ONE_HUNDRED_PERCENT_BPS;
    }

    function _clampBetween(uint256 _value, uint256 _min, uint256 _max) internal pure returns (uint256) {
        return _min + UniformRandomNumber.uniform(_value, _max - _min);
    }
}
