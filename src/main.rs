use aws_sdk_s3::{Client, Region};
use nestquest::{
    helpers::{aws_put_object, get_account_creation_date, get_gfx_stake_address, verify_signature},
    types::{Offchain, UpgradeBody},
};
use solana_client::rpc_client::RpcClient;
use solana_sdk::pubkey::Pubkey;
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

    let routes = warp::post()
        .and(with_val(aws_client))
        .and(with_val(Arc::new(Mutex::new(solana_client))))
        .and(warp::filters::body::json())
        .and(warp::path("tier3"))
        .and_then(tier3_handler);

    warp::serve(routes).run(([0, 0, 0, 0], env.port)).await;

    Ok(())
}

async fn tier3_handler(
    aws_client: aws_sdk_s3::Client,
    rpc_arc: Arc<Mutex<RpcClient>>,
    body: UpgradeBody,
) -> Result<impl warp::Reply, std::convert::Infallible> {
    let res = async {
        let user_wallet: Pubkey = str::parse(&body.address).map_err(|_| refuse())?;

        let now_unix = std::time::SystemTime::now()
            .duration_since(std::time::SystemTime::UNIX_EPOCH)
            .expect("system/unix time fail")
            .as_millis();

        if (now_unix - 30_000) < body.timestamp {
            return Err(refuse());
        };

        let signature_verification =
            verify_signature(&body.timestamp.to_string(), &body.signature, &user_wallet);

        if signature_verification.is_err() {
            return Err(refuse());
        };

        let gofx_stake = get_gfx_stake_address(&user_wallet);

        let rpc = rpc_arc.lock().await;

        // TODO: Check stake balance here
        //let bal = rpc.get_token_account_balance(&gofx_stake).unwrap();
        //if bal.ui_amount.unwrap() < 25.0 {
        //return Ok(refuse());
        //};

        let created_at = get_account_creation_date(&rpc, &gofx_stake).map_err(|_| refuse())?;

        let now = chrono::offset::Utc::now();
        if created_at.add(chrono::Duration::days(7)).gt(&now) {
            return Err(refuse());
        };

        // TODO: Get id from metadata or NFT database
        let nft_id = 1;

        let metadata: Offchain = serde_json::from_str("TODO").map_err(|_| refuse())?;

        aws_put_object(&aws_client, &metadata, nft_id)
            .await
            .map_err(|_| refuse())?;

        Ok(build_response(StatusCode::OK, "OK"))
    };

    match res.await {
        Ok(val) => Ok(val),
        Err(val) => Ok(val),
    }
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
