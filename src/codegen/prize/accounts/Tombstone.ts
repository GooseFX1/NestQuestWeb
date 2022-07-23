import { PublicKey, Connection } from "@solana/web3.js"
import BN from "bn.js" // eslint-disable-line @typescript-eslint/no-unused-vars
import * as borsh from "@project-serum/borsh" // eslint-disable-line @typescript-eslint/no-unused-vars
import { PROGRAM_ID } from "../programId"

export interface TombstoneFields {}

export interface TombstoneJSON {}

export class Tombstone {
  static readonly discriminator = Buffer.from([
    45, 187, 252, 155, 232, 114, 36, 22,
  ])

  static readonly layout = borsh.struct([])

  constructor(fields: TombstoneFields) {}

  static async fetch(
    c: Connection,
    address: PublicKey
  ): Promise<Tombstone | null> {
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
  ): Promise<Array<Tombstone | null>> {
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

  static decode(data: Buffer): Tombstone {
    if (!data.slice(0, 8).equals(Tombstone.discriminator)) {
      throw new Error("invalid account discriminator")
    }

    const dec = Tombstone.layout.decode(data.slice(8))

    return new Tombstone({})
  }

  toJSON(): TombstoneJSON {
    return {}
  }

  static fromJSON(obj: TombstoneJSON): Tombstone {
    return new Tombstone({})
  }
}
