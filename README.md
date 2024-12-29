# Crowda - Decentralized Crowdfunding Platform

A transparent and decentralized crowdfunding platform built on the Stacks blockchain using Clarity smart contracts.

## Features
- Create crowdfunding campaigns with funding goals and deadlines
- Contribute STX tokens to campaigns
- Automatic refunds if funding goal is not met
- Secure fund release to campaign creator if goal is met
- Full transparency of all transactions and campaign status

## How it works
1. Campaign creators can start a new campaign by specifying:
   - Funding goal (in STX)
   - Campaign deadline
   - Campaign details

2. Contributors can pledge STX to campaigns they want to support

3. When the deadline is reached:
   - If the goal is met, funds are released to the campaign creator
   - If the goal is not met, contributors can claim refunds

## Security
- All funds are held in the smart contract until conditions are met
- Automatic refund mechanism protects contributors
- Campaign details immutably stored on-chain