DeFi Protocol

Design a DeFi protocol named Clip that incentivizes users for depositing ETH into its Vault contract. The core mechanism involves a manual invocation of the releaseRewards() function from the Vault contract. This function weekly transfers 1000 $USDC from the treasury address to the Vault contract. The distributed reward is proportionally shared among ETH depositors based on their contribution weight. Users can claim their entitled rewards by executing the claimRewards() function.

For instance, consider the scenario where Alice deposits 5 ETH and Bob deposits 20 ETH into the Clip contract, anticipating reward withdrawals at the week's end. Subsequently, after one week elapses, the Clip team triggers the releaseRewards() function, transferring 1000 $USDC from the treasury. At this point, Alice can execute claimRewards(), receiving 200 $USDC in addition to her initially deposited 5 ETH. Likewise, upon invoking claimRewards(), Bob obtains 800 $USDC along with his 20 ETH deposit.

Task entails the following:
Develop the Clip contract, considering a substantial treasury balance of $USDC.
Integrate essential functions into the Vault contract, including depositEth(), releaseRewards(), and claimRewards(). Feel free to include any auxiliary functions as deemed necessary.
Implement safeguards to ensure exclusive access to the releaseRewards() function by the authorized team.
Address edge cases comprehensively, including scenarios where deposits are made at different times within a reward release cycle. (Hint: Establish a time limit for ETH deposits.)
Assume a maximum limit of 20 weekly ETH depositors, with an individual cap of 20 ETH per person.