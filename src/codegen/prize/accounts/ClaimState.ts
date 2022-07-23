import { PublicKey, Connection } from "@solana/web3.js"
import BN from "bn.js" // eslint-disable-line @typescript-eslint/no-unused-vars
import * as borsh from "@project-serum/borsh" // eslint-disable-line @typescript-eslint/no-unused-vars
import { PROGRAM_ID } from "../programId"

export interface ClaimStateFields {
  orbClaimed: boolean
}

export interface ClaimStateJSON {
  orbClaimed: boolean
}

export class ClaimState {
  readonly orbClaimed: boolean

  static readonly discriminator = Buffer.from([
    71, 73, 19, 83, 53, 228, 242, 53,
  ])

  static readonly layout = borsh.struct([borsh.bool("orbClaimed")])

  constructor(fields: ClaimStateFields) {
    this.orbClaimed = fields.orbClaimed
  }

  static async fetch(
    c: Connection,
    address: PublicKey
  ): Promise<ClaimState | null> {
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
  ): Promise<Array<ClaimState | null>> {
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

  static decode(data: Buffer): ClaimState {
    if (!data.slice(0, 8).equals(ClaimState.discriminator)) {
      throw new Error("invalid account discriminator")
    }

    const dec = ClaimState.layout.decode(data.slice(8))

    return new ClaimState({
      orbClaimed: dec.orbClaimed,
    })
  }

  toJSON(): ClaimStateJSON {
    return {
      orbClaimed: this.orbClaimed,
    }
  }

  static fromJSON(obj: ClaimStateJSON): ClaimState {
    return new ClaimState({
      orbClaimed: obj.orbClaimed,
    })
  }
}
