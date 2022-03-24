import { PublicKey, Connection } from "@solana/web3.js"
import BN from "bn.js"
import * as borsh from "@project-serum/borsh"
import { PROGRAM_ID } from "../programId"

export interface StakeFields {
  mintId: PublicKey
  stakingStart: BN
}

export interface StakeJSON {
  mintId: string
  stakingStart: string
}

export class Stake {
  readonly mintId: PublicKey
  readonly stakingStart: BN

  static readonly discriminator = Buffer.from([
    150, 197, 176, 29, 55, 132, 112, 149,
  ])

  static readonly layout = borsh.struct([
    borsh.publicKey("mintId"),
    borsh.u64("stakingStart"),
  ])

  constructor(fields: StakeFields) {
    this.mintId = fields.mintId
    this.stakingStart = fields.stakingStart
  }

  static async fetch(c: Connection, address: PublicKey): Promise<Stake | null> {
    const info = await c.getAccountInfo(address)

    if (info === null) {
      return null
    }
    if (!info.owner.equals(PROGRAM_ID)) {
      throw new Error("account doesn't belong to this program")
    }

    return this.decode(info.data)
  }

  static async fetchMultiple(
    c: Connection,
    addresses: PublicKey[]
  ): Promise<Array<Stake | null>> {
    const infos = await c.getMultipleAccountsInfo(addresses)

    return infos.map((info) => {
      if (info === null) {
        return null
      }
      if (!info.owner.equals(PROGRAM_ID)) {
        throw new Error("account doesn't belong to this program")
      }

      return this.decode(info.data)
    })
  }

  static decode(data: Buffer): Stake {
    if (!data.slice(0, 8).equals(Stake.discriminator)) {
      throw new Error("invalid account discriminator")
    }

    const dec = Stake.layout.decode(data.slice(8))

    return new Stake({
      mintId: dec.mintId,
      stakingStart: dec.stakingStart,
    })
  }

  toJSON(): StakeJSON {
    return {
      mintId: this.mintId.toString(),
      stakingStart: this.stakingStart.toString(),
    }
  }

  static fromJSON(obj: StakeJSON): Stake {
    return new Stake({
      mintId: new PublicKey(obj.mintId),
      stakingStart: new BN(obj.stakingStart),
    })
  }
}
