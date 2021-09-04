// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// import "openzeppelin-solidity-solc6/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import "./SendValueOrEscrow.sol";

/**
 * @title Payments contract for SuperRare Marketplaces.
 */
contract Payments is SendValueOrEscrow {
    using SafeMath for uint256;
    using SafeMath for uint8;

    /////////////////////////////////////////////////////////////////////////
    // refund
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to refund an address. Typically for canceled bids or offers.

     * Requirements:
     *
     *  - _payee cannot be the zero address
     * 
     * @param _amount uint256 value to be split.
     * @param _payee address seller of the token.
     */
    function refund(
        address payable _payee,
        uint256 _amount
    ) internal {
        require(
            _payee != address(0),
            "refund::no payees can be the zero address"
        );

        if (_amount > 0) {
            SendValueOrEscrow.sendValueOrEscrow(_payee, _amount);
        }
    }

    /////////////////////////////////////////////////////////////////////////
    // payout
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to pay the seller.
     * @param _amount uint256 value to be split.
     * @param _payee address seller of the token.
     */
    function payout(
        uint256 _amount,
        address payable _payee
       
    ) internal {
      
        require(
            _payee != address(0)
        );

        // Note:: Solidity is kind of terrible in that there is a limit to local
        //        variables that can be put into the stack. The real pain is that
        //        one can put structs, arrays, or mappings into memory but not basic
        //        data types. Hence our payments array that stores these values.
      
        uint256[1] memory payments;
        
        // uint256 payeePayment
        payments[0] = _amount;

        // payeePayment
        if (payments[0] > 0) {
            SendValueOrEscrow.sendValueOrEscrow(_payee, payments[0]);
        }
    }

}
