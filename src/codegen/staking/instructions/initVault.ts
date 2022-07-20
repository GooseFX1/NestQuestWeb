import { PublicKey, TransactionInstruction } from "@solana/web3.js";
import BN from "bn.js";
import * as borsh from "@project-serum/borsh";
import { PROGRAM_ID } from "../programId";

export interface InitVaultAccounts {
  payer: PublicKey;
  gofxVault: PublicKey;
  gofxMint: PublicKey;
  tokenProgram: PublicKey;
  systemProgram: PublicKey;
  rent: PublicKey;
}

export function initVault(accounts: InitVaultAccounts) {
  const keys = [
    { pubkey: accounts.payer, isSigner: true, isWritable: true },
    { pubkey: accounts.gofxVault, isSigner: false, isWritable: true },
    { pubkey: accounts.gofxMint, isSigner: false, isWritable: false },
    { pubkey: accounts.tokenProgram, isSigner: false, isWritable: false },
    { pubkey: accounts.systemProgram, isSigner: false, isWritable: false },
    { pubkey: accounts.rent, isSigner: false, isWritable: false },
  ];
  const identifier = Buffer.from([77, 79, 85, 150, 33, 217, 52, 106]);
  const data = identifier;
  const ix = new TransactionInstruction({ keys, programId: PROGRAM_ID, data });
  return ix;
}
