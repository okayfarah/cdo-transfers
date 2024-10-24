module MyModule::CDOTransfer {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::timestamp;
    use aptos_framework::aptos_coin::AptosCoin;

    /// Error codes
    const E_INSUFFICIENT_BALANCE: u64 = 1;
    const E_INVALID_AMOUNT: u64 = 2;

    /// Struct to store CDO position details
    struct CDOPosition has key, store {
        token_amount: u64,         // Amount of tokens in the position
        maturity_date: u64,        // Timestamp when tokens can be claimed
        is_transferred: bool,      // Track if position is transferred
    }

    /// Creates a new CDO position with specified tokens and maturity
    public entry fun create_cdo_position(
        issuer: &signer,
        token_amount: u64,
        maturity_days: u64
    ) {
        assert!(token_amount > 0, E_INVALID_AMOUNT);
        
        // Calculate maturity timestamp
        let current_time = timestamp::now_seconds();
        let maturity_time = current_time + (maturity_days * 86400);

        // Create CDO position
        let cdo = CDOPosition {
            token_amount,
            maturity_date: maturity_time,
            is_transferred: false,
        };

        // Transfer tokens from issuer to contract
        let tokens = coin::withdraw<AptosCoin>(issuer, token_amount);
        coin::deposit(signer::address_of(issuer), tokens);
        
        // Store CDO position
        move_to(issuer, cdo);
    }

    /// Transfers CDO tokens to investor
    public entry fun transfer_to_investor(
        issuer: &signer,
        investor_addr: address,
        amount: u64
    ) acquires CDOPosition {
        let issuer_addr = signer::address_of(issuer);
        let cdo = borrow_global_mut<CDOPosition>(issuer_addr);
        
        // Verify conditions
        assert!(!cdo.is_transferred, E_INSUFFICIENT_BALANCE);
        assert!(amount <= cdo.token_amount, E_INVALID_AMOUNT);
        assert!(timestamp::now_seconds() >= cdo.maturity_date, E_INVALID_AMOUNT);

        // Transfer tokens to investor
        let tokens = coin::withdraw<AptosCoin>(issuer, amount);
        coin::deposit(investor_addr, tokens);
        
        // Mark as transferred
        cdo.is_transferred = true;
    }
}