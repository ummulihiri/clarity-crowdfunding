import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create a new campaign",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const goal = 1000;
    const deadline = 100;
    
    let block = chain.mineBlock([
      Tx.contractCall('crowdfunding', 'create-campaign', [
        types.uint(goal),
        types.uint(deadline)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
  },
});

Clarinet.test({
  name: "Can contribute to campaign",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const contributor = accounts.get('wallet_1')!;
    const goal = 1000;
    const deadline = 100;
    const contribution = 500;
    
    // Create campaign
    let block = chain.mineBlock([
      Tx.contractCall('crowdfunding', 'create-campaign', [
        types.uint(goal),
        types.uint(deadline)
      ], deployer.address)
    ]);
    
    // Contribute to campaign
    let contributionBlock = chain.mineBlock([
      Tx.contractCall('crowdfunding', 'contribute', [
        types.uint(1),
        types.uint(contribution)
      ], contributor.address)
    ]);
    
    contributionBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Verify contribution
    let getContribution = chain.callReadOnlyFn(
      'crowdfunding',
      'get-contribution',
      [types.uint(1), types.principal(contributor.address)],
      contributor.address
    );
    
    getContribution.result.expectSome().expectTuple({
      'amount': types.uint(contribution)
    });
  },
});

Clarinet.test({
  name: "Can claim funds when goal is reached",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const contributor = accounts.get('wallet_1')!;
    const goal = 1000;
    const deadline = 10;
    
    // Create and fund campaign
    let block = chain.mineBlock([
      Tx.contractCall('crowdfunding', 'create-campaign', [
        types.uint(goal),
        types.uint(deadline)
      ], deployer.address),
      Tx.contractCall('crowdfunding', 'contribute', [
        types.uint(1),
        types.uint(goal)
      ], contributor.address)
    ]);
    
    // Advance blockchain past deadline
    chain.mineEmptyBlockUntil(deadline + 1);
    
    // Claim funds
    let claimBlock = chain.mineBlock([
      Tx.contractCall('crowdfunding', 'claim-funds', [
        types.uint(1)
      ], deployer.address)
    ]);
    
    claimBlock.receipts[0].result.expectOk().expectBool(true);
  },
});

Clarinet.test({
  name: "Can refund when goal not reached",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const contributor = accounts.get('wallet_1')!;
    const goal = 1000;
    const deadline = 10;
    const contribution = 500;
    
    // Create and fund campaign
    let block = chain.mineBlock([
      Tx.contractCall('crowdfunding', 'create-campaign', [
        types.uint(goal),
        types.uint(deadline)
      ], deployer.address),
      Tx.contractCall('crowdfunding', 'contribute', [
        types.uint(1),
        types.uint(contribution)
      ], contributor.address)
    ]);
    
    // Advance blockchain past deadline
    chain.mineEmptyBlockUntil(deadline + 1);
    
    // Request refund
    let refundBlock = chain.mineBlock([
      Tx.contractCall('crowdfunding', 'refund', [
        types.uint(1)
      ], contributor.address)
    ]);
    
    refundBlock.receipts[0].result.expectOk().expectBool(true);
  },
});