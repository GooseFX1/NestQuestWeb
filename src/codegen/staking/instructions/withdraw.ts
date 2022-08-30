import { TransactionInstruction, PublicKey, AccountMeta } from "@solana/web3.js" // eslint-disable-line @typescript-eslint/no-unused-vars
import BN from "bn.js" // eslint-disable-line @typescript-eslint/no-unused-vars
import * as borsh from "@project-serum/borsh" // eslint-disable-line @typescript-eslint/no-unused-vars
import { PROGRAM_ID } from "../programId"

export interface WithdrawArgs {
  vaultBump: number
  stakeBump: number
}

export interface WithdrawAccounts {
  payer: PublicKey
  vault: PublicKey
  tokenAccount: PublicKey
  stake: PublicKey
  gofxVault: PublicKey
  gofxUserAccount: PublicKey
  gofxMint: PublicKey
  tokenProgram: PublicKey
}

export const layout = borsh.struct([
  borsh.u8("vaultBump"),
  borsh.u8("stakeBump"),
])

export function withdraw(args: WithdrawArgs, accounts: WithdrawAccounts) {
  const keys: Array<AccountMeta> = [
    { pubkey: accounts.payer, isSigner: true, isWritable: true },
    { pubkey: accounts.vault, isSigner: false, isWritable: true },
    { pubkey: accounts.tokenAccount, isSigner: false, isWritable: true },
    { pubkey: accounts.stake, isSigner: false, isWritable: true },
    { pubkey: accounts.gofxVault, isSigner: false, isWritable: true },
    { pubkey: accounts.gofxUserAccount, isSigner: false, isWritable: true },
    { pubkey: accounts.gofxMint, isSigner: false, isWritable: false },
    { pubkey: accounts.tokenProgram, isSigner: false, isWritable: false },
  ]
  const identifier = Buffer.from([183, 18, 70, 156, 148, 109, 161, 34])
  const buffer = Buffer.alloc(1000)
  const len = layout.encode(
    {
      vaultBump: args.vaultBump,
      stakeBump: args.stakeBump,
    },
    buffer
  )
  const data = Buffer.concat([identifier, buffer]).slice(0, 8 + len)
  const ix = new TransactionInstruction({ keys, programId: PROGRAM_ID, data })
  return ix
}
