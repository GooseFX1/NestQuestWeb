export type JsonObject = { [Key in string]?: JsonValue };
export type JsonArray = JsonValue[];

/**
Matches any valid JSON value.
Source: https://github.com/sindresorhus/type-fest/blob/master/source/basic.d.ts
*/
export type JsonValue =
  | string
  | number
  | boolean
  | null
  | JsonObject
  | JsonArray;

export interface ElmApp {
  ports: {
    interopFromElm: PortFromElm<FromElm>;
    interopToElm: PortToElm<ToElm>;
    [key: string]: UnknownPort;
  };
}

export type FromElm = { data : { mintId : string; sig : number[] }; tag : "claim" } | { data : string; tag : "stake" } | { data : string; tag : "signTimestamp" } | { data : null; tag : "disconnect" } | { data : number; tag : "connect" } | { data : string; tag : "withdraw" } | { data : null; tag : "stopTheme" } | { data : null; tag : "playTheme" } | { data : string; tag : "alert" } | { data : string; tag : "log" };

export type ToElm = { data : string; tag : "alreadyStaked" } | { data : ({ address : string } & { stake : { mintId : string; stakingStart : number } | null } & { nfts : { mintId : string; name : string; tier : number }[] } & { orbs : number }) | null; tag : "connectResponse" } | { data : { mintId : string; stakingStart : number } | null; tag : "stakeResponse" } | { data : { mintId : string; name : string; tier : number } | null; tag : "withdrawResponse" } | { data : { mintId : string; signature : string } | null; tag : "signResponse" } | { data : string | null; tag : "claimResponse" };

export type Flags = { backendUrl : string; now : number; screen : { height : number; width : number } };

export namespace Main {
  function init(options: { node?: HTMLElement | null; flags: Flags }): ElmApp;
}

export as namespace Elm;

export { Elm };

export type UnknownPort = PortFromElm<unknown> | PortToElm<unknown> | undefined;

export type PortFromElm<Data> = {
  subscribe(callback: (fromElm: Data) => void): void;
  unsubscribe(callback: (fromElm: Data) => void): void;
};

export type PortToElm<Data> = { send(data: Data): void };
