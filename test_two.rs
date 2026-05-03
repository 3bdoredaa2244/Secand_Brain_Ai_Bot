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
}use candid::Nat;
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
}use candid::Nat;
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
}use candid::Nat;
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
}use candid::Nat;
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
}use candid::Nat;
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
}use candid::Nat;
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
}use candid::Nat;
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
}use candid::Nat;
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
