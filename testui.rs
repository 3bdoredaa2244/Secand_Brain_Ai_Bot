use candid::Nat;
use ic_cdk::{caller};
use ic_cdk_macros::{init, query, update};
use std::cell::RefCell;
use std::collections::HashMap;

thread_local! {
    static BALANCES: RefCell<HashMap<String, Nat>> = RefCell::new(HashMap::new());
}

#[init]
fn init(total_supply: Nat) {
    let owner = caller().to_text();

    BALANCES.with(|b| {
        b.borrow_mut().insert(owner, total_supply);
    });
}

#[query]
fn balance_of(user: String) -> Nat {
    BALANCES.with(|b| {
        b.borrow().get(&user).cloned().unwrap_or(Nat::from(0u32))
    })
}

#[update]
fn transfer(to: String, amount: Nat) -> bool {
    let from = caller().to_text();

    BALANCES.with(|b| {
        let mut map = b.borrow_mut();

        let sender_balance = map.get(&from).cloned().unwrap_or(Nat::from(0u32));

        if sender_balance < amount {
            return false;
        }

        map.insert(from.clone(), sender_balance - amount.clone());

        let recv_balance = map.get(&to).cloned().unwrap_or(Nat::from(0u32));
        map.insert(to.clone(), recv_balance + amount);

        true
    })
}

use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}


use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}
use candid::Nat;
use ic_cdk::{caller};
use ic_cdk_macros::{init, query, update};
use std::cell::RefCell;
use std::collections::HashMap;

thread_local! {
    static BALANCES: RefCell<HashMap<String, Nat>> = RefCell::new(HashMap::new());
}

#[init]
fn init(total_supply: Nat) {
    let owner = caller().to_text();

    BALANCES.with(|b| {
        b.borrow_mut().insert(owner, total_supply);
    });
}

#[query]
fn balance_of(user: String) -> Nat {
    BALANCES.with(|b| {
        b.borrow().get(&user).cloned().unwrap_or(Nat::from(0u32))
    })
}

#[update]
fn transfer(to: String, amount: Nat) -> bool {
    let from = caller().to_text();

    BALANCES.with(|b| {
        let mut map = b.borrow_mut();

        let sender_balance = map.get(&from).cloned().unwrap_or(Nat::from(0u32));

        if sender_balance < amount {
            return false;
        }

        map.insert(from.clone(), sender_balance - amount.clone());

        let recv_balance = map.get(&to).cloned().unwrap_or(Nat::from(0u32));
        map.insert(to.clone(), recv_balance + amount);

        true
    })
}

use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}


use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}

use candid::Nat;
use ic_cdk::{caller};
use ic_cdk_macros::{init, query, update};
use std::cell::RefCell;
use std::collections::HashMap;

thread_local! {
    static BALANCES: RefCell<HashMap<String, Nat>> = RefCell::new(HashMap::new());
}

#[init]
fn init(total_supply: Nat) {
    let owner = caller().to_text();

    BALANCES.with(|b| {
        b.borrow_mut().insert(owner, total_supply);
    });
}

#[query]
fn balance_of(user: String) -> Nat {
    BALANCES.with(|b| {
        b.borrow().get(&user).cloned().unwrap_or(Nat::from(0u32))
    })
}

#[update]
fn transfer(to: String, amount: Nat) -> bool {
    let from = caller().to_text();

    BALANCES.with(|b| {
        let mut map = b.borrow_mut();

        let sender_balance = map.get(&from).cloned().unwrap_or(Nat::from(0u32));

        if sender_balance < amount {
            return false;
        }

        map.insert(from.clone(), sender_balance - amount.clone());

        let recv_balance = map.get(&to).cloned().unwrap_or(Nat::from(0u32));
        map.insert(to.clone(), recv_balance + amount);

        true
    })
}

use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}


use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}

use candid::Nat;
use ic_cdk::{caller};
use ic_cdk_macros::{init, query, update};
use std::cell::RefCell;
use std::collections::HashMap;

thread_local! {
    static BALANCES: RefCell<HashMap<String, Nat>> = RefCell::new(HashMap::new());
}

#[init]
fn init(total_supply: Nat) {
    let owner = caller().to_text();

    BALANCES.with(|b| {
        b.borrow_mut().insert(owner, total_supply);
    });
}

#[query]
fn balance_of(user: String) -> Nat {
    BALANCES.with(|b| {
        b.borrow().get(&user).cloned().unwrap_or(Nat::from(0u32))
    })
}

#[update]
fn transfer(to: String, amount: Nat) -> bool {
    let from = caller().to_text();

    BALANCES.with(|b| {
        let mut map = b.borrow_mut();

        let sender_balance = map.get(&from).cloned().unwrap_or(Nat::from(0u32));

        if sender_balance < amount {
            return false;
        }

        map.insert(from.clone(), sender_balance - amount.clone());

        let recv_balance = map.get(&to).cloned().unwrap_or(Nat::from(0u32));
        map.insert(to.clone(), recv_balance + amount);

        true
    })
}

use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}


use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}
use candid::Nat;
use ic_cdk::{caller};
use ic_cdk_macros::{init, query, update};
use std::cell::RefCell;
use std::collections::HashMap;

thread_local! {
    static BALANCES: RefCell<HashMap<String, Nat>> = RefCell::new(HashMap::new());
}

#[init]
fn init(total_supply: Nat) {
    let owner = caller().to_text();

    BALANCES.with(|b| {
        b.borrow_mut().insert(owner, total_supply);
    });
}

#[query]
fn balance_of(user: String) -> Nat {
    BALANCES.with(|b| {
        b.borrow().get(&user).cloned().unwrap_or(Nat::from(0u32))
    })
}

#[update]
fn transfer(to: String, amount: Nat) -> bool {
    let from = caller().to_text();

    BALANCES.with(|b| {
        let mut map = b.borrow_mut();

        let sender_balance = map.get(&from).cloned().unwrap_or(Nat::from(0u32));

        if sender_balance < amount {
            return false;
        }

        map.insert(from.clone(), sender_balance - amount.clone());

        let recv_balance = map.get(&to).cloned().unwrap_or(Nat::from(0u32));
        map.insert(to.clone(), recv_balance + amount);

        true
    })
}

use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}


use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}
use candid::Nat;
use ic_cdk::{caller};
use ic_cdk_macros::{init, query, update};
use std::cell::RefCell;
use std::collections::HashMap;

thread_local! {
    static BALANCES: RefCell<HashMap<String, Nat>> = RefCell::new(HashMap::new());
}

#[init]
fn init(total_supply: Nat) {
    let owner = caller().to_text();

    BALANCES.with(|b| {
        b.borrow_mut().insert(owner, total_supply);
    });
}

#[query]
fn balance_of(user: String) -> Nat {
    BALANCES.with(|b| {
        b.borrow().get(&user).cloned().unwrap_or(Nat::from(0u32))
    })
}

#[update]
fn transfer(to: String, amount: Nat) -> bool {
    let from = caller().to_text();

    BALANCES.with(|b| {
        let mut map = b.borrow_mut();

        let sender_balance = map.get(&from).cloned().unwrap_or(Nat::from(0u32));

        if sender_balance < amount {
            return false;
        }

        map.insert(from.clone(), sender_balance - amount.clone());

        let recv_balance = map.get(&to).cloned().unwrap_or(Nat::from(0u32));
        map.insert(to.clone(), recv_balance + amount);

        true
    })
}

use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}


use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}

use candid::Nat;
use ic_cdk::{caller};
use ic_cdk_macros::{init, query, update};
use std::cell::RefCell;
use std::collections::HashMap;

thread_local! {
    static BALANCES: RefCell<HashMap<String, Nat>> = RefCell::new(HashMap::new());
}

#[init]
fn init(total_supply: Nat) {
    let owner = caller().to_text();

    BALANCES.with(|b| {
        b.borrow_mut().insert(owner, total_supply);
    });
}

#[query]
fn balance_of(user: String) -> Nat {
    BALANCES.with(|b| {
        b.borrow().get(&user).cloned().unwrap_or(Nat::from(0u32))
    })
}

#[update]
fn transfer(to: String, amount: Nat) -> bool {
    let from = caller().to_text();

    BALANCES.with(|b| {
        let mut map = b.borrow_mut();

        let sender_balance = map.get(&from).cloned().unwrap_or(Nat::from(0u32));

        if sender_balance < amount {
            return false;
        }

        map.insert(from.clone(), sender_balance - amount.clone());

        let recv_balance = map.get(&to).cloned().unwrap_or(Nat::from(0u32));
        map.insert(to.clone(), recv_balance + amount);

        true
    })
}

use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}


use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}

use candid::Nat;
use ic_cdk::{caller};
use ic_cdk_macros::{init, query, update};
use std::cell::RefCell;
use std::collections::HashMap;

thread_local! {
    static BALANCES: RefCell<HashMap<String, Nat>> = RefCell::new(HashMap::new());
}

#[init]
fn init(total_supply: Nat) {
    let owner = caller().to_text();

    BALANCES.with(|b| {
        b.borrow_mut().insert(owner, total_supply);
    });
}

#[query]
fn balance_of(user: String) -> Nat {
    BALANCES.with(|b| {
        b.borrow().get(&user).cloned().unwrap_or(Nat::from(0u32))
    })
}

#[update]
fn transfer(to: String, amount: Nat) -> bool {
    let from = caller().to_text();

    BALANCES.with(|b| {
        let mut map = b.borrow_mut();

        let sender_balance = map.get(&from).cloned().unwrap_or(Nat::from(0u32));

        if sender_balance < amount {
            return false;
        }

        map.insert(from.clone(), sender_balance - amount.clone());

        let recv_balance = map.get(&to).cloned().unwrap_or(Nat::from(0u32));
        map.insert(to.clone(), recv_balance + amount);

        true
    })
}

use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}


use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}

use candid::Nat;
use ic_cdk::{caller};
use ic_cdk_macros::{init, query, update};
use std::cell::RefCell;
use std::collections::HashMap;

thread_local! {
    static BALANCES: RefCell<HashMap<String, Nat>> = RefCell::new(HashMap::new());
}

#[init]
fn init(total_supply: Nat) {
    let owner = caller().to_text();

    BALANCES.with(|b| {
        b.borrow_mut().insert(owner, total_supply);
    });
}

#[query]
fn balance_of(user: String) -> Nat {
    BALANCES.with(|b| {
        b.borrow().get(&user).cloned().unwrap_or(Nat::from(0u32))
    })
}

#[update]
fn transfer(to: String, amount: Nat) -> bool {
    let from = caller().to_text();

    BALANCES.with(|b| {
        let mut map = b.borrow_mut();

        let sender_balance = map.get(&from).cloned().unwrap_or(Nat::from(0u32));

        if sender_balance < amount {
            return false;
        }

        map.insert(from.clone(), sender_balance - amount.clone());

        let recv_balance = map.get(&to).cloned().unwrap_or(Nat::from(0u32));
        map.insert(to.clone(), recv_balance + amount);

        true
    })
}

use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}


use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}
use candid::Nat;
use ic_cdk::{caller};
use ic_cdk_macros::{init, query, update};
use std::cell::RefCell;
use std::collections::HashMap;

thread_local! {
    static BALANCES: RefCell<HashMap<String, Nat>> = RefCell::new(HashMap::new());
}

#[init]
fn init(total_supply: Nat) {
    let owner = caller().to_text();

    BALANCES.with(|b| {
        b.borrow_mut().insert(owner, total_supply);
    });
}

#[query]
fn balance_of(user: String) -> Nat {
    BALANCES.with(|b| {
        b.borrow().get(&user).cloned().unwrap_or(Nat::from(0u32))
    })
}

#[update]
fn transfer(to: String, amount: Nat) -> bool {
    let from = caller().to_text();

    BALANCES.with(|b| {
        let mut map = b.borrow_mut();

        let sender_balance = map.get(&from).cloned().unwrap_or(Nat::from(0u32));

        if sender_balance < amount {
            return false;
        }

        map.insert(from.clone(), sender_balance - amount.clone());

        let recv_balance = map.get(&to).cloned().unwrap_or(Nat::from(0u32));
        map.insert(to.clone(), recv_balance + amount);

        true
    })
}

use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}


use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}

use candid::Nat;
use ic_cdk::{caller};
use ic_cdk_macros::{init, query, update};
use std::cell::RefCell;
use std::collections::HashMap;

thread_local! {
    static BALANCES: RefCell<HashMap<String, Nat>> = RefCell::new(HashMap::new());
}

#[init]
fn init(total_supply: Nat) {
    let owner = caller().to_text();

    BALANCES.with(|b| {
        b.borrow_mut().insert(owner, total_supply);
    });
}

#[query]
fn balance_of(user: String) -> Nat {
    BALANCES.with(|b| {
        b.borrow().get(&user).cloned().unwrap_or(Nat::from(0u32))
    })
}

#[update]
fn transfer(to: String, amount: Nat) -> bool {
    let from = caller().to_text();

    BALANCES.with(|b| {
        let mut map = b.borrow_mut();

        let sender_balance = map.get(&from).cloned().unwrap_or(Nat::from(0u32));

        if sender_balance < amount {
            return false;
        }

        map.insert(from.clone(), sender_balance - amount.clone());

        let recv_balance = map.get(&to).cloned().unwrap_or(Nat::from(0u32));
        map.insert(to.clone(), recv_balance + amount);

        true
    })
}

use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}


use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}

use candid::Nat;
use ic_cdk::{caller};
use ic_cdk_macros::{init, query, update};
use std::cell::RefCell;
use std::collections::HashMap;

thread_local! {
    static BALANCES: RefCell<HashMap<String, Nat>> = RefCell::new(HashMap::new());
}

#[init]
fn init(total_supply: Nat) {
    let owner = caller().to_text();

    BALANCES.with(|b| {
        b.borrow_mut().insert(owner, total_supply);
    });
}

#[query]
fn balance_of(user: String) -> Nat {
    BALANCES.with(|b| {
        b.borrow().get(&user).cloned().unwrap_or(Nat::from(0u32))
    })
}

#[update]
fn transfer(to: String, amount: Nat) -> bool {
    let from = caller().to_text();

    BALANCES.with(|b| {
        let mut map = b.borrow_mut();

        let sender_balance = map.get(&from).cloned().unwrap_or(Nat::from(0u32));

        if sender_balance < amount {
            return false;
        }

        map.insert(from.clone(), sender_balance - amount.clone());

        let recv_balance = map.get(&to).cloned().unwrap_or(Nat::from(0u32));
        map.insert(to.clone(), recv_balance + amount);

        true
    })
}

use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}


use ic_cdk::api::call::call;
use ic_cdk_macros::{init, update, query};
use candid::{CandidType, Deserialize, Nat};

#[init]
fn init() {
    // Nothing needed for init
}

#[update]
async fn swap_a_for_b(amount: Nat, token_a: String, token_b: String) -> bool {
    let caller_principal = ic_cdk::caller();

    // Transfer token A from caller to this swap canister
    let a_result: Result<(bool,), _> = call(
        token_a.parse().unwrap(),
        "transfer",
        (caller_principal.to_text(), amount.clone()),
    ).await;

    if let Ok((true,)) = a_result {
        // Send token B from swap canister to caller
        let b_result: Result<(bool,), _> = call(
            token_b.parse().unwrap(),
            "transfer",
            (caller_principal.to_text(), amount),
        ).await;

        if let Ok((true,)) = b_result {
            return true;
        }
    }

    false
}

#[query]
fn dummy() -> String {
    "Swap ready".to_string()
}


