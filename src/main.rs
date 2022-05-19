use anyhow::anyhow;
use aws_sdk_s3::{Client, Region};
use borsh::de::BorshDeserialize;
use mpl_token_metadata::state::Metadata;
use nestquest::{
    helpers::{aws_put_object, get_account_creation_date, get_gfx_stake_address, verify_signature},
    types::{Attribute, Offchain, PropertiesFile, UpgradeBody},
};
use solana_client::rpc_client::RpcClient;
use solana_sdk::pubkey::Pubkey;
use std::str::FromStr;
use std::{ops::Add, sync::Arc};
use tokio::sync::Mutex;
use warp::{http::StatusCode, Filter};

const REGION: &str = "ap-south-1";

#[derive(serde::Deserialize)]
struct Env {
    rpc: url::Url,
    port: u16,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let env = envy::from_env::<Env>()?;

    let shared_config = aws_config::from_env()
        .region(Region::new(REGION))
        .load()
        .await;

    let aws_client = Client::new(&shared_config);
    let solana_client = RpcClient::new(env.rpc.to_string());
    let http_client = reqwest::Client::new();

    let tier3_route = warp::post()
        .and(with_val(aws_client))
        .and(with_val(http_client))
        .and(with_val(Arc::new(Mutex::new(solana_client))))
        .and(warp::filters::body::json())
        .and(warp::path("tier3"))
        .and_then(tier3_handler);

    let ping_route = warp::get().and(warp::path("healthz")).map(ping_handler);

    let cors = warp::cors()
        .allow_any_origin()
        .allow_header("content-type")
        .allow_methods(&[warp::http::Method::GET, warp::http::Method::POST]);

    let routes = ping_route.or(tier3_route);

    warp::serve(routes.with(cors))
        .run(([0, 0, 0, 0], env.port))
        .await;

    Ok(())
}

async fn tier3_handler(
    aws_client: aws_sdk_s3::Client,
    http_client: reqwest::Client,
    rpc_arc: Arc<Mutex<RpcClient>>,
    body: UpgradeBody,
) -> Result<impl warp::Reply, std::convert::Infallible> {
    let res = async {
        let user_wallet: Pubkey = str::parse(&body.address)?;

        let signature_verification = verify_signature(&body.mint_id, &body.signature, &user_wallet);

        if signature_verification.is_err() {
            return Err(anyhow!("Invalid signature"));
        };

        let mint_id: Pubkey = str::parse(&body.mint_id)?;

        let rpc = rpc_arc.lock().await;

        if !is_nft_owner(&rpc, &mint_id, &user_wallet)? {
            return Err(anyhow!("Ownership fail"));
        };

        let gofx_stake = get_gfx_stake_address(&user_wallet);

        let account_data = rpc.get_account_data(&gofx_stake)?;

        let stake_amount = u64::from_le_bytes(account_data[56..64].try_into()?);

        if stake_amount < 25_000_000_000 {
            return Err(anyhow!("Insufficient staking amount"));
        }

        let created_at = get_account_creation_date(&rpc, &gofx_stake)?;

        let now = chrono::offset::Utc::now();
        if created_at.add(chrono::Duration::days(7)).gt(&now) {
            return Err(anyhow!("Insufficient staking length"));
        };

        let metadata = get_metadata(&rpc, &mint_id)?;

        let metadata_url = url::Url::from_str(&metadata.data.uri)?;

        let mut offchain_metadata = get_tier2_metadata(&http_client, &metadata_url).await?;

        upgrade_metadata(&mut offchain_metadata)?;

        let nft_id = get_nft_id(&metadata_url, &metadata)?;

        aws_put_object(&aws_client, &offchain_metadata, nft_id).await?;

        Ok(build_response(StatusCode::OK, "OK"))
    };

    match res.await {
        Ok(val) => Ok(val),
        Err(err) => {
            println!("{}", err.to_string());
            Ok(refuse())
        }
    }
}

fn ping_handler() -> impl warp::Reply {
    let response = serde_json::json!({ "status": "OK" });
    warp::reply::json(&response)
}

fn with_val<T: Clone + std::marker::Send>(
    val: T,
) -> impl Filter<Extract = (T,), Error = std::convert::Infallible> + Clone {
    warp::any().map(move || val.clone())
}

fn build_response(code: StatusCode, message: &str) -> warp::reply::WithStatus<warp::reply::Json> {
    let json = serde_json::json!({
        "code": code.as_u16(),
        "message": message.to_string(),
    });

    warp::reply::with_status(warp::reply::json(&json), code)
}

fn refuse() -> warp::reply::WithStatus<warp::reply::Json> {
    build_response(StatusCode::BAD_REQUEST, "There was a problem.")
}

fn is_nft_owner(
    rpc: &RpcClient,
    mint_address: &Pubkey,
    user_wallet: &Pubkey,
) -> anyhow::Result<bool> {
    let addr =
        spl_associated_token_account::get_associated_token_address(user_wallet, mint_address);

    let res = rpc.get_token_account_balance(&addr)?;

    let amount = res.ui_amount.ok_or(anyhow!("missing token balance"))?;

    Ok(amount == 1.0)
}

async fn get_tier2_metadata(
    client: &reqwest::Client,
    metadata_url: &url::Url,
) -> anyhow::Result<Offchain> {
    let data: Offchain = client
        .get(metadata_url.to_string())
        .send()
        .await?
        .json()
        .await?;

    if !data.description.contains("hatchling has emerged") {
        Err(anyhow!("NFT is not Tier 2"))
    } else {
        Ok(data)
    }
}

fn build_attrs(body: &str, flame: &str, aura: &str) -> Vec<Attribute> {
    vec![
        Attribute {
            trait_type: "Body".to_string(),
            value: body.to_string(),
        },
        Attribute {
            trait_type: "Flame".to_string(),
            value: flame.to_string(),
        },
        Attribute {
            trait_type: "Aura".to_string(),
            value: aura.to_string(),
        },
    ]
}

fn upgrade_metadata(metadata: &mut Offchain) -> anyhow::Result<()> {
    let body = metadata
        .attributes
        .iter()
        .find(|field| field.trait_type == "Body")
        .ok_or(anyhow!("Body attribute not found: {}", metadata.name))?
        .value
        .clone();

    let attrs_result = match &*body {
        "Black" => Ok(build_attrs(&body, "Plague", "Death")),
        "Blue" => Ok(build_attrs(&body, "Frost", "Water")),
        "Gold" => Ok(build_attrs(&body, "Lightning", "Life")),
        "Green" => Ok(build_attrs(&body, "Growth", "Forest")),
        "Orange" => Ok(build_attrs(&body, "Molten", "Earth")),
        "Purple" => Ok(build_attrs(&body, "Heart", "Love")),
        "Red" => Ok(build_attrs(&body, "Fire", "Sun")),
        _ => Err(anyhow!("Invalid body attribute: {}", metadata.name)),
    };

    let attrs = attrs_result?;

    let img = url::Url::from_str(&format!(
        "https://gfxnestquest.s3.ap-south-1.amazonaws.com/img/tier3/{}.png",
        &body.to_lowercase()
    ))?;

    let files = vec![PropertiesFile {
        uri: img.clone(),
        type_: "image/png".to_string(),
    }];

    metadata.description = TIER_3_DESC.to_string();
    metadata.image = img;
    metadata.attributes = attrs;
    metadata.properties.files = files;

    Ok(())
}

fn get_nft_id(metadata_url: &url::Url, metadata: &Metadata) -> anyhow::Result<usize> {
    let id_title_str = metadata
        .data
        .name
        .split("#")
        .last()
        .ok_or(anyhow!("title parse fail"))?
        .trim_end_matches('\0');
    let id_from_title = str::parse::<usize>(id_title_str)?;

    let id_url_str = metadata_url
        .path_segments()
        .and_then(|segs| segs.last())
        .and_then(|file| file.split(".").nth(0))
        .ok_or(anyhow!("url parse fail"))?;
    let id_from_url = str::parse::<usize>(id_url_str)?;

    if id_from_title == id_from_url {
        Ok(id_from_title)
    } else {
        Err(anyhow!("id mismatch"))
    }
}

fn get_metadata(rpc: &RpcClient, mint_address: &Pubkey) -> anyhow::Result<Metadata> {
    let (meta_addr, _) = mpl_token_metadata::pda::find_metadata_account(&mint_address);
    let metadata_account = rpc.get_account(&meta_addr)?;
    let acct = &mut &metadata_account.data[..];
    Metadata::deserialize(acct).map_err(|e| e.into())
}

const TIER_3_DESC: &str = "The training has paid off and the Hatchling has evolved into a much stronger Gosling. The Gosling still emits a dangerous flame from its mouth which appears to be related to its prior Aura. Additional training is required to evolve again.";
