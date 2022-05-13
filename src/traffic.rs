use std::process::Command;
use std::process::Output;
use std::io::{self, Read, Write};
use std::{fs};

use std::str;
use rand::{Rng, seq::SliceRandom};

use serde::{Deserialize, Serialize};


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
struct ClnPaymentResult {
    payment_preimage: String,
    status: String,
    msatoshi: u64,
    amount_msat: String,
    msatoshi_sent: u64,
    amount_sent_msat: String,
    destination: String,
    payment_hash: String,
    created_at: f64,
    parts: u64

}

fn run_cln_command(instance: &str, passed_args: Vec<&str>) -> Output {
    let out = Command::new("docker")
        .args(["exec", "-i", &format!("cln-{}", instance), "lightning-cli", "--network", "regtest"])
        .args(&passed_args)
        .output()
        .expect(&format!("Failed to execute: {:?}", passed_args));

    return out;
}

fn get_cln_info(instance: &str) -> ClnInfo {
    let out = run_cln_command(instance, vec!["getinfo"]);

    serde_json::from_str(str::from_utf8(&out.stdout).unwrap()).unwrap()
}

fn get_cln_invoice(instance: &str, amount: u32) -> ClnInvoice {
    let label = random_invoice_label();
    let out = run_cln_command(instance, vec!["invoice", &amount.to_string(), &label, "some-description"]);
    // io::stdout().write_all(&out.stdout).unwrap();
    // io::stderr().write_all(&out.stderr).unwrap();
    serde_json::from_str(str::from_utf8(&out.stdout).unwrap()).unwrap()
}

fn cln_pay_invoice(instance: &str, invoice: &String) -> Result<ClnPaymentResult, serde_json::Error> {
    let out = run_cln_command(instance, vec!["pay", &invoice]);
    io::stdout().write_all(&out.stdout).unwrap();
    io::stderr().write_all(&out.stderr).unwrap();

    serde_json::from_str(str::from_utf8(&out.stdout).unwrap())
}

fn random_invoice_amount() -> u32 {
    rand::thread_rng().gen_range(10000..100000)
}

fn random_invoice_label() -> String {
    format!("label-{}", rand::thread_rng().gen_range(10..10000000))
}

fn main() {
    // Sending some money around?
    
    let vs = vec!["c1", "c2", "c3", "c4"];

    let times = 10;

    println!("Doing {} Remote -> Child invoice payments", &times);
    let mut failures = 0;
    for _ in 0..times {
        let instance = vs.choose(&mut rand::thread_rng()).unwrap();
        println!("Fetching invoice from: {}", &instance);
        let invoice = get_cln_invoice(&instance, random_invoice_amount());
        println!("Fetched invoice, now paying");
        match cln_pay_invoice("remote", &invoice.bolt11) {
            Ok(res) => {
                if res.status == "complete" {
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
