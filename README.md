# MO-C-02 PoC: BuildersV4 accrual vs BuildersTreasuryV2 solvency (Base)

Foundry tests against the deployed BuildersV4 / BuildersTreasuryV2 proxies on a
Base mainnet fork pinned at block 58452000.

## Run

Requirements: Foundry (verified with 1.9.0). No API key and no other setup.
The RPC endpoint is configured in `foundry.toml` (public Base archive endpoint,
`https://base.drpc.org`).

```sh
forge test
```

Expected result: 2 tests passed, 0 failed.

- `MO_C_02_MeasureTest.test_measure`: reads the Treasury balance, the aggregate
  accrual view and every enumerated subnet's pending at the pinned block, and
  asserts the shortfall (accruals exceed the balance in both accounting views).
  Uses no impersonation at all.
- `MO_C_02_ClaimsTest.test_fcfs_lock`: eight subnet admins claim their own
  subnets in full (51,006.3024 MOR total), the Protection Fund subnet's claim of
  18,448.0261 MOR then reverts with its pending unchanged, and a 686.4337 MOR
  top-up (plain transfer) releases it in full.

## On the `vm.prank` calls

`claim()` is gated by BuildersV4 to each subnet's own admin/claimAdmin, so a claim
can only ever be executed by that account. Each prank in the claims test
impersonates a subnet admin claiming its own subnet, which is that account's
normal, unprivileged action. No protocol-privileged account (owner/multisig,
BuildersV4, the Treasury, any fee or oracle role) is impersonated. The top-up
uses no prank: the test contract is dealt the MOR and transfers it itself,
modelling any holder funding the Treasury by plain transfer, the Treasury's
only funding path. The full inventory is also documented in the claims test
header.

## Notes

- One compiler warning is expected (`Function state mutability can be restricted
  to view` in the measurement test); it does not affect the run.
- The public RPC rate-limits under heavy parallel load. If a run fails with
  HTTP 429 transport errors, re-run the same command; a clean run passes
  deterministically at the pinned block.
- Working batch tests used during the original investigation (subnet
  enumeration in chunks) are not needed to reproduce the finding and are kept
  with the research evidence, not in this repo.
