use std::process::Command;
use std::process::Output;
use std::io::{self, Read, Write};
use std::{fs};
use std::fs::File;
use std::str;
use rand::Rng;

use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
struct SenseiInstanceInfo {
    root: SenseiNode,
    nodes: Vec<SenseiNode>,
}

impl SenseiInstanceInfo {
    fn path(&self) -> String {
        format!("sensei_instance_info.json")
    }

    pub fn save(&mut self) {
        fs::write(
            self.path().clone(),
            serde_json::to_string(&self)
            .expect("Failed to serialize Sensei Instance Info")
        )
        .expect("Failed to write serialized Sensei Instance Info");
    }
}

#[derive(Serialize, Deserialize, Debug)]
struct LndInvoice {
    r_hash: String,
    payment_request: String,
    add_index: String,
    payment_addr: String
}

#[derive(Serialize, Deserialize, Debug)]
struct SenseiNode {
    token: String,
    pubkey: String,
    macaroon: String,
    // external_id: String,
    role: u32,
}

#[derive(Serialize, Deserialize, Debug)]
struct SenseiAddress {
    address: String,
}

#[derive(Serialize, Deserialize, Debug)]
struct ClnInfo {
    id: String,
    alias: String,
    num_peers: u8,
    num_pending_channels: u8,
    num_active_channels: u8,
    blockheight: u64,
    version: String
}

#[derive(Serialize, Deserialize, Debug)]
struct ClnInvoice {
    payment_hash: String,
    expires_at: u32,
    bolt11: String,
    payment_secret: String,
}


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
struct LndPaymentResult {
    payment_hash: String,
    value: String,
    fee: String,
    status: String,
    failure_reason: String,

}

#[derive(Serialize, Deserialize, Debug)]
struct LndPeers {
    peers: Vec<LndPeer>
}

#[derive(Serialize, Deserialize, Debug)]
struct SenseiInvoice {
    invoice: String
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

fn open_channel_lnd_sensei_root(sensei_config: &SenseiInstanceInfo, amount: u32) -> () {
    run_lnd_command(vec!["openchannel", &format!("{}", sensei_config.root.pubkey), &amount.to_string()]);
}

fn open_channel_lnd_cln(cln_pubkey: &str, amount: u32) -> () {
    run_lnd_command(vec!["openchannel", &format!("{}", cln_pubkey), &amount.to_string()]);
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

fn get_lnd_info() -> LndInfo {
    let out = run_lnd_command(vec!["getinfo"]);

    // io::stdout().write_all(&out.stdout).unwrap();
    // io::stderr().write_all(&out.stderr).unwrap();

    serde_json::from_str(str::from_utf8(&out.stdout).unwrap()).unwrap()
}

fn get_lnd_invoice(amount: u32) -> LndInvoice {
    let out = run_lnd_command(vec!["addinvoice", &amount.to_string()]);

    serde_json::from_str(str::from_utf8(&out.stdout).unwrap()).unwrap()
}

fn lnd_pay_invoice(invoice: &str) -> Result<LndPaymentResult, serde_json::Error> {
    let output = run_lnd_command(vec!["payinvoice", "-f", "--json", invoice]);
    
    serde_json::from_str(str::from_utf8(&output.stdout).unwrap())
}


fn get_lnd_peers() -> LndPeers {
    let out = run_lnd_command(vec!["listpeers"]);

    serde_json::from_str(str::from_utf8(&out.stdout).unwrap()).unwrap()
}

fn get_cln_info() -> ClnInfo {
    let out = run_cln_command(vec!["getinfo"]);

    serde_json::from_str(str::from_utf8(&out.stdout).unwrap()).unwrap()
}

fn get_cln_invoice(amount: u32) -> ClnInvoice {
    let label = random_invoice_label();
    let out = run_cln_command(vec!["invoice", &amount.to_string(), &label, "some-description"]);
    // io::stdout().write_all(&out.stdout).unwrap();
    // io::stderr().write_all(&out.stderr).unwrap();
    serde_json::from_str(str::from_utf8(&out.stdout).unwrap()).unwrap()
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
    // println!("Now going to sleep for 4 seconds to let blocks generate, etc");
    // thread::sleep(Duration::from_millis(4000));
}

fn generate_block() -> () {
    Command::new("nigiri")
        .args(["rpc", "-generate=1"])
        .output()
        .expect("Failed to generate blocks");
}

fn load_sensei_config() -> Result<String, io::Error>  {
    let path = "sensei_instance_info.json";
    let mut f = File::open(path)?;
    let mut s = String::new();
    f.read_to_string(&mut s)?;
    Ok(s)
    
}

fn initialize_sensei() -> SenseiInstanceInfo {
    let config = load_sensei_config();
    match config {
        Ok(config) => {
            println!("Sensei Configuration loaded successfully");
            let reified: SenseiInstanceInfo = serde_json::from_str(&config).unwrap();
            reified
        },
        Err(err) => {
            println!("Sensei configuration not found, actually initalizing");
            initialize_fresh_sensei()
        }
    }
}

fn initialize_fresh_sensei() -> SenseiInstanceInfo {
    let output = Command::new("senseicli")
        .arg("--passphrase")
        .arg("1234")
        .arg("init")
        .arg("some-username")
        .arg("some-alias")
        .output()
        .expect("failed to initialize Sensei root");

    // io::stdout().write_all(&output.stdout).unwrap();
    // io::stderr().write_all(&output.stderr).unwrap();
    
    let output_string = str::from_utf8(&output.stdout).unwrap().trim();
    
    println!("This is my string I'm going to parse {}", &output_string);
    let root_config: SenseiNode = serde_json::from_str(&output_string).unwrap();
    let mut sensei = SenseiInstanceInfo{ root: root_config, nodes: vec![] };
    sensei.save();
    sensei
}

fn start_sensei_root(sensei_config: &SenseiInstanceInfo) -> () {
    let output = Command::new("senseicli")
        .arg("--passphrase")
        .arg("1234")
        .arg("--token")
        .arg(&sensei_config.root.token)
        .arg("start")
        .output()
        .expect("Failed to start sensei node");
}

fn add_sensei_node(mut sensei_config: SenseiInstanceInfo) -> SenseiInstanceInfo {
    let output = Command::new("senseicli")
        .arg("--passphrase")
        .arg("1234")
        .arg("--token")
        .arg(&sensei_config.root.token)
        .arg("createnode")
        .arg("some-username")
        .arg(random_invoice_label())
        .arg("true")
        .output()
        .expect("failed to create sensei node");

    // io::stdout().write_all(&output.stdout).unwrap();
    // io::stderr().write_all(&output.stderr).unwrap();
    
    let output_string = str::from_utf8(&output.stdout).unwrap().trim();
    
    let node_config: SenseiNode = serde_json::from_str(&output_string).unwrap();
    sensei_config.nodes.push(node_config);
    sensei_config.save();
    sensei_config
}

fn get_sensei_invoice(instance: &SenseiNode, amount: u32) -> SenseiInvoice {
    let out: Output = Command::new("senseicli")
        .args(["--macaroon", &instance.macaroon, "createinvoice", &amount.to_string()])
        .output()
        .expect("Failed to create invoice");
    
    serde_json::from_str(str::from_utf8(&out.stdout).unwrap()).unwrap()
}

fn get_sensei_address(instance: &SenseiNode) -> SenseiAddress {
    let out: Output = Command::new("senseicli")
        .args(["--macaroon", &instance.macaroon, "getaddress"])
        .output()
        .expect("Failed to get new address");
    
    // io::stdout().write_all(&out.stdout).unwrap();
    // io::stderr().write_all(&out.stderr).unwrap();

    serde_json::from_str(str::from_utf8(&out.stdout).unwrap()).unwrap()
}

fn connect_sensei_instances(from: &SenseiNode, to: &SenseiNode, size: u32) {
    // This is fucknig madness
    let output = Command::new("senseicli")
        .arg("--macaroon")
        .arg(&from.macaroon)
        .arg("nodeinfo")
        .output()
        .expect("failed to get node info");

    io::stdout().write_all(&output.stdout).unwrap();
    io::stderr().write_all(&output.stderr).unwrap();

    let output = Command::new("senseicli")
        .arg("--token")
        .arg(&from.token)
        .arg("listnodes")
        .output()
        .expect("failed to list nodes");

    io::stdout().write_all(&output.stdout).unwrap();
    io::stderr().write_all(&output.stderr).unwrap();

}

fn sequential_test_lnd_sensei_payments(times: u32, sensei_config: &SenseiInstanceInfo) -> () {
    println!("Doing {} LND -> Sensei invoice payments", &times);
    let mut failures = 0;
    for _ in 0..times {
        let sensei_invoice = get_sensei_invoice(&sensei_config.root, random_invoice_amount());
        match lnd_pay_invoice(&sensei_invoice.invoice) {
            Ok(res) => {
                if res.status == "SUCCEEDED" {
                    // println!("Success")
                } else {
                    // println!("Failure - parsed");
                    failures += 1;
                }
            },
            Err(err) => {
                println!("Error paying invoice {:?}", err);
                failures += 1;
            }
        }
    }
    println!("Done - {} failures", failures);
}

fn random_invoice_amount() -> u32 {
    rand::thread_rng().gen_range(10000..100000)
}

fn random_invoice_label() -> String {
    format!("label-{}", rand::thread_rng().gen_range(10..10000000))
}

fn main() {
    
    setup();
    // Let's just genearte a block every time we run for sanity
    generate_block();

    // nigiri faucet cln 1
    // nigiri faucet lnd 1
    // nigiri cln connect `nigiri lnd getinfo | jq -r .identity_pubkey`@lnd:9735
    // nigiri lnd openchannel --node_key=`nigiri cln getinfo | jq -r .id` --local_amt=100000

    let peers = get_lnd_peers();

    println!("LND peer count: {:?}", peers.peers.len());

    let out = Command::new("nigiri")
        .arg("faucet").arg("lnd").arg("1")
        .output()
        .expect("Failed to fund lnd node");
    assert!(out.status.success());

    // get the lnd pubkey
    let lnd_info = get_lnd_info();
    let lnd_pubkey = lnd_info.identity_pubkey;
    println!("Retrieved LND pubkey {}", &lnd_pubkey);

    // get the cln pubkey
    let cln_info = get_cln_info();
    let cln_pubkey = cln_info.id;
    println!("Retrieved CLN pubkey {}", &cln_pubkey);

    // get the sensei config (start it up, etc)
    let sensei_config = initialize_sensei();
    start_sensei_root(&sensei_config);

    println!("Sensei child node count: {}", &sensei_config.nodes.len());

    let sensei_config = if sensei_config.nodes.len() < 5 {
        println!("Now going to add sensei child nodes");
        let sensei_config = add_sensei_node(sensei_config);
        let sensei_config = add_sensei_node(sensei_config);
        let sensei_config = add_sensei_node(sensei_config);
        let sensei_config = add_sensei_node(sensei_config);
        let sensei_config = add_sensei_node(sensei_config);
        println!("Added 5 child nodes successfully");
        sensei_config
    } else {
        sensei_config
    };

    let sensei_btc_address = get_sensei_address(&sensei_config.root);
    let out = Command::new("nigiri")
        .arg("faucet").arg(sensei_btc_address.address).arg("1")
        .output()
        .expect("Failed to fund sensei node");
    assert!(out.status.success());

    // Ok let's open a channel from sensei root to a child and try to pay it

    connect_sensei_instances(&sensei_config.root, &sensei_config.nodes[0], 1_000_000);


    // Done with that task 

    if lnd_info.num_active_channels < 2 {
        println!("We'll connect up our cluster");

        // connect cln to the lnd pubkey
        let out = run_cln_command(vec!["connect", &format!("{}@lnd:9735", lnd_pubkey)]);
        assert!(out.status.success());

        // Connect LND to Sensei!
        let out = run_lnd_command(vec!["connect", &format!("{}@sensei:9735", sensei_config.root.pubkey)]);
            
        io::stdout().write_all(&out.stdout).unwrap();
        io::stderr().write_all(&out.stderr).unwrap();

        // assert!(out.status.success());

        // Connect CLN to Sensei!
        let out = run_cln_command(vec!["connect", &format!("{}@sensei:9735", sensei_config.root.pubkey)]);
            
        io::stdout().write_all(&out.stdout).unwrap();
        io::stderr().write_all(&out.stderr).unwrap();

        // assert!(out.status.success());

        println!("OK now going to try to open a channel");
        open_channel_lnd_sensei_root(&sensei_config, 1000000);
        open_channel_lnd_cln(&cln_pubkey, 440000);

        println!("Now generate some blocks");
        generate_block();
        generate_block();
        generate_block();
        generate_block();
        generate_block();
        generate_block();
    } else {
        println!("Cluster connectivity in place");
    }

    // Sending some money around?
    
    let times = 10;
    sequential_test_lnd_sensei_payments(times, &sensei_config);

    println!("Doing {} LND -> CLN invoice payments", &times);
    let mut failures = 0;
    for _ in 0..times {
        let invoice = get_cln_invoice(random_invoice_amount());
        match lnd_pay_invoice(&invoice.bolt11) {
            Ok(res) => {
                if res.status == "SUCCEEDED" {
                    // println!("Success")
                } else {
                    // println!("Failure - parsed");
                    failures += 1;
                }
            },
            Err(err) => {
                println!("Error paying invoice {:?}", err);
                failures += 1;
            }
        }
    }
    println!("Done - {} failures", failures);
    
}


// Goal!
// Create sensei node, send money from faucet

// 

#[cfg(test)]
mod tests {

    #[test]
    fn internal() {
        let my_string = r#"{"pubkey":"03bf8695412986df4df466c10772dfbe9e8147117a0397aa8a896d80c35cb89741","macaroon":"02010773656e73656964029b017b226964656e746966696572223a5b3135332c3138312c3137362c3138332c3233362c37332c37392c33302c3138372c3235312c3234382c3130362c3234362c3134372c3138322c3234305d2c227075626b6579223a22303362663836393534313239383664663464663436366331303737326466626539653831343731313761303339376161386138393664383063333563623839373431227d00000620f403cd8ad2e2faeccb91a8ecbfc376e273495b89160a29d1be3bef5034117dec","role":0,"token":"5c56be2bac66425a0037705cc6f36339199b139e1bafe558475dac80987a9712"}"#;

        let obj: super::SenseiNode = serde_json::from_str(my_string).unwrap();
        println!("OBJ: {:?}", obj);
        assert_eq!(obj, super::SenseiNode { 
            token: "boo".to_string(),
            pubkey: "bar".to_string(),
            role: 0,
            // external_id: "saontheu".to_string(),
            macaroon: "sntahoeu100".to_string(),
        })
    }
}