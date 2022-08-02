import { TransactionInstruction, PublicKey, AccountMeta } from "@solana/web3.js" // eslint-disable-line @typescript-eslint/no-unused-vars
import BN from "bn.js" // eslint-disable-line @typescript-eslint/no-unused-vars
import * as borsh from "@project-serum/borsh" // eslint-disable-line @typescript-eslint/no-unused-vars
import { PROGRAM_ID } from "../programId"

export interface ClaimOrbAccounts {
  payer: PublicKey
  userOrbAcct: PublicKey
  /** CHECK */
  authorityAcct: PublicKey
  claimState: PublicKey
  orbMint: PublicKey
  tier3Nft: PublicKey
  /** CHECK */
  instructions: PublicKey
  tokenProgram: PublicKey
  systemProgram: PublicKey
}

export function claimOrb(accounts: ClaimOrbAccounts) {
  const keys: Array<AccountMeta> = [
    { pubkey: accounts.payer, isSigner: true, isWritable: true },
    { pubkey: accounts.userOrbAcct, isSigner: false, isWritable: true },
    { pubkey: accounts.authorityAcct, isSigner: false, isWritable: false },
    { pubkey: accounts.claimState, isSigner: false, isWritable: true },
    { pubkey: accounts.orbMint, isSigner: false, isWritable: true },
    { pubkey: accounts.tier3Nft, isSigner: false, isWritable: false },
    { pubkey: accounts.instructions, isSigner: false, isWritable: false },
    { pubkey: accounts.tokenProgram, isSigner: false, isWritable: false },
    { pubkey: accounts.systemProgram, isSigner: false, isWritable: false },
  ]
  const identifier = Buffer.from([230, 3, 49, 106, 78, 183, 48, 22])
  const data = identifier
  const ix = new TransactionInstruction({ keys, programId: PROGRAM_ID, data })
  return ix
}
