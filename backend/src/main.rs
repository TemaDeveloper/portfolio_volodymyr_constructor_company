use crate::pic_info::PicInfo;

mod pic_info;

#[tokio::main]
async fn main() -> anyhow::Result<()>{
    let pic = include_bytes!("../20240518_214102.jpg");
    println!("{:?}", PicInfo::from_slice(pic).await?);

    Ok(())
}
