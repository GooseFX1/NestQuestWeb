#[derive(serde::Deserialize)]
pub struct UpgradeBody {
    pub address: String,
    pub mint_id: String,
    pub signature: String,
}

#[derive(serde::Serialize)]
pub struct ErrorMessage {
    pub code: u16,
    pub message: String,
}

#[derive(serde::Deserialize, serde::Serialize)]
pub struct Offchain {
    pub name: String,
    pub symbol: String,
    pub description: String,
    pub seller_fee_basis_points: u16,
    pub image: url::Url,
    pub external_url: url::Url,
    pub attributes: Vec<Attribute>,
    pub collection: Collection,
    pub properties: Properties,
}

#[derive(serde::Deserialize, serde::Serialize)]
pub struct Attribute {
    pub trait_type: String,
    pub value: String,
}

#[derive(serde::Deserialize, serde::Serialize)]
pub struct Creator {
    pub address: String,
    pub share: usize,
}

#[derive(serde::Deserialize, serde::Serialize)]
pub struct Properties {
    pub files: Vec<PropertiesFile>,
    pub category: String,
    pub creators: Vec<Creator>,
}

#[derive(serde::Deserialize, serde::Serialize, Clone)]
pub struct Collection {
    pub name: String,
    pub family: String,
}

#[derive(serde::Deserialize, serde::Serialize)]
pub struct PropertiesFile {
    pub uri: url::Url,
    #[serde(rename = "type")]
    pub type_: String,
}
