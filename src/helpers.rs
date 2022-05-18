use crate::types::Offchain;
use aws_sdk_s3::{types::ByteStream, Client};
use chrono::{DateTime, Utc};
use ed25519_dalek::Verifier;
use solana_client::{
    rpc_client::RpcClient, rpc_response::RpcConfirmedTransactionStatusWithSignature,
};
use solana_sdk::{pubkey::Pubkey, signature::Signature};
use std::{
    str::FromStr,
    time::{Duration, UNIX_EPOCH},
};

const AWS_BUCKET: &str = "gfxnestquest";

pub fn get_account_creation_date(rpc: &RpcClient, addr: &Pubkey) -> anyhow::Result<DateTime<Utc>> {
    fn fetch(
        rpc: &RpcClient,
        addr: &Pubkey,
        before: Option<Signature>,
    ) -> Result<RpcConfirmedTransactionStatusWithSignature, anyhow::Error> {
        let mut sigs = rpc.get_signatures_for_address_with_config(
            &addr,
            solana_client::rpc_client::GetConfirmedSignaturesForAddress2Config {
                before,
                ..Default::default()
            },
        )?;

        sigs.sort_by_key(|sig| sig.block_time);

        let earliest = sigs
            .first()
            .ok_or(anyhow::Error::msg("empty signature list"))?;

        if sigs.len() < 1000 {
            Ok(earliest.clone())
        } else {
            let sig = Signature::from_str(&earliest.signature)?;
            fetch(&rpc, &addr, Some(sig))
        }
    }

    let status = fetch(&rpc, &addr, None)?;

    let d = UNIX_EPOCH
        + Duration::from_secs(
            status
                .block_time
                .ok_or(anyhow::Error::msg("missing block time"))?
                .try_into()?,
        );

    Ok(DateTime::<Utc>::from(d))
}

pub fn get_gfx_stake_address(user_wallet: &Pubkey) -> Pubkey {
    let controller = str::parse::<Pubkey>("8CxKnuJeoeQXFwiG6XiGY2akBjvJA5k3bE52BfnuEmNQ").unwrap();
    let program_id = str::parse::<Pubkey>("8KJx48PYGHVC9fxzRRtYp4x4CM2HyYCm2EjVuAP4vvrx").unwrap();

    let (addr, _b) = Pubkey::find_program_address(
        &[
            b"GFX-STAKINGACCOUNT",
            &controller.to_bytes(),
            &user_wallet.to_bytes(),
        ],
        &program_id,
    );

    addr
}

pub async fn aws_put_object(
    client: &Client,
    metadata: &Offchain,
    nft_id: usize,
) -> anyhow::Result<()> {
    let raw_body = serde_json::to_vec(&metadata)?;
    let body = ByteStream::from(raw_body);

    client
        .put_object()
        .bucket(AWS_BUCKET)
        .key(format!("metadata/{}.json", nft_id))
        .body(body)
        .send()
        .await?;

    Ok(())
}

pub fn verify_signature(
    message: &str,
    signature: &str,
    user_wallet: &Pubkey,
) -> anyhow::Result<()> {
    let hex = hex::decode(signature.to_string())?;

    let sig_bytes: [u8; 64] = hex
        .try_into()
        .map_err(|_| anyhow::Error::msg("hex length error"))?;

    let pubk = ed25519_dalek::PublicKey::from_bytes(&user_wallet.to_bytes())?;

    pubk.verify(
        &format!("NestQuest verify:\n{}", message).as_bytes(),
        &ed25519_dalek::Signature::from_bytes(&sig_bytes)?,
    )
    .map_err(|e| e.into())
}
