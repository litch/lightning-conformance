use std::array;
use std::process::Command;
use std::process::Output;
use std::io::{self, Write};
use std::str;
// use std::{thread, time::Duration};

use serde::{Deserialize, Serialize};
use serde_json::Result;

#[derive(Serialize, Deserialize, Debug)]
struct LndInfo {
    version: String,
    identity_pubkey: String,
    alias: String,
    block_height: u64,
    num_pending_channels: u8,
    num_active_channels: u8,
    num_inactive_channels: u8,
    synced_to_chain: bool,
    synced_to_graph: bool
}

#[derive(Serialize, Deserialize, Debug)]
struct LndPeer {
    pub_key: String,
    address: String,
    inbound: bool,
    ping_time: String
}

#[derive(Serialize, Deserialize, Debug)]
struct LndPeers {
    peers: Vec<LndPeer>
}

fn run_lnd_command(passed_args: Vec<&str>) -> Output {
    let out = Command::new("docker")
        .args(["exec", "-i", "lnd", "lncli", "--network", "regtest"])
        .args(&passed_args)
        .output()
        .expect(&format!("Failed to execute: {:?}", passed_args));

    return out;
}

fn run_cln_command(passed_args: Vec<&str>) -> Output {
    let out = Command::new("docker")
        .args(["exec", "-i", "cln", "lightning-cli", "--network", "regtest"])
        .args(&passed_args)
        .output()
        .expect(&format!("Failed to execute: {:?}", passed_args));

    return out;
}

fn start_nigiri() -> Output {
    let output = Command::new("nigiri")
        .arg("start")
        .arg("--ln")
        .output()
        .expect("failed to start nigiri");

    return output
}

fn stop_nigiri() -> Output {
    let output = Command::new("nigiri")
        .arg("stop")
        .output()
        .expect("failed to stop nigiri");

    return output
}

fn setup() {
    let nigiri_output = start_nigiri();
    
    dbg!(nigiri_output.status.success());

    if nigiri_output.status.success() {
        println!("Started!");
    } else {
        println!("Nigiri already running.  Not Restarting.");
        // stop_nigiri();
        // let restart: Output = start_nigiri();
        // assert!(restart.status.success(), "Nigiri configuration unsuccessful, idk.");
    }
    println!("Now going to sleep for 4 seconds to let blocks generate, etc");
    // thread::sleep(Duration::from_millis(4000));

}

fn main() {
    
    setup();
    // nigiri faucet cln 1
    // nigiri faucet lnd 1
    // nigiri cln connect `nigiri lnd getinfo | jq -r .identity_pubkey`@lnd:9735
    // nigiri lnd openchannel --node_key=`nigiri cln getinfo | jq -r .id` --local_amt=100000

    let out = run_lnd_command(vec!["listpeers"]);

    let peers: LndPeers = serde_json::from_str(str::from_utf8(&out.stdout).unwrap()).unwrap();

    println!("{:?}", peers);

    let out = run_cln_command(vec!["newaddr"])

    let out = Command::new("nigiri")
        .arg("faucet").arg("lnd").arg("1")
        .output()
        .expect("Failed to fund lnd node");
    assert!(out.status.success());

    // let out = Command::new("nigiri")
    //     .arg("cln").arg("connect").arg(r#"`nigiri lnd getinfo | jq -r .identity_pubkey`@lnd:9735"#)
    //     .output()
    //     .expect("Failed to connect nodes");

    // get the lnd pubkey
    let out = Command::new("docker")
        .args(["exec", "-i", "lnd", "lncli", "--network", "regtest", "getinfo"])
        .output()
        .expect("Failed to get lnd node info");

    io::stdout().write_all(&out.stdout).unwrap();
    io::stderr().write_all(&out.stderr).unwrap();

    let info: LndInfo = serde_json::from_str(str::from_utf8(&out.stdout).unwrap()).unwrap();

    println!("{:?}", info);
    assert!(out.status.success());
    
    let lnd_pubkey = info.identity_pubkey;

    // connect cln to the lnd pubkey

    let out: Output = Command::new("docker")
        .args(["exec", "-i", "cln", "lightning-cli", "--network", "regtest", "connect", &format!("{}@lnd:9735", lnd_pubkey)])
        .output()
        .expect("Failed to connect nodes");

    assert!(out.status.success());

    // stop_nigiri();


}
