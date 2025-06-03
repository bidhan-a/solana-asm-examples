#[cfg(test)]
mod tests {
    use mollusk_svm::{result::Check, Mollusk};
    use solana_sdk::account::Account;
    use solana_sdk::instruction::{AccountMeta, Instruction};
    use solana_sdk::native_token::LAMPORTS_PER_SOL;
    use solana_sdk::program_error::ProgramError;
    use solana_sdk::pubkey::Pubkey;

    const BASE_LAMPORTS: u64 = 10 * LAMPORTS_PER_SOL;
    const DEPOSIT_AMOUNT: u64 = 1;
    const DEPOSIT_LAMPORTS: u64 = DEPOSIT_AMOUNT * LAMPORTS_PER_SOL;

    pub fn get_program_id() -> Pubkey {
        let program_id_keypair_bytes = std::fs::read("deploy/asm-transfer-lamports-keypair.json")
            .unwrap()[..32]
            .try_into()
            .expect("slice with incorrect length");
        Pubkey::new_from_array(program_id_keypair_bytes)
    }

    #[test]
    fn test_invalid_num_accounts() {
        let program_id = get_program_id();
        let mollusk = Mollusk::new(&program_id, "deploy/asm-transfer-lamports");

        let sender_pubkey = Pubkey::new_unique();
        let receiver_pubkey = Pubkey::new_unique();
        let extra_pubkey = Pubkey::new_unique();

        // Less than 2 accounts.
        let instruction = Instruction::new_with_bytes(
            program_id,
            &[],
            vec![AccountMeta::new(sender_pubkey, true)],
        );
        mollusk.process_and_validate_instruction(
            &instruction,
            &[(sender_pubkey, Account::new(BASE_LAMPORTS, 0, &program_id))],
            &[Check::err(ProgramError::Custom(1))],
        );

        // More than 2 accounts.
        let instruction = Instruction::new_with_bytes(
            program_id,
            &[],
            vec![
                AccountMeta::new(sender_pubkey, true),
                AccountMeta::new(receiver_pubkey, true),
                AccountMeta::new(extra_pubkey, true),
            ],
        );
        mollusk.process_and_validate_instruction(
            &instruction,
            &[
                (sender_pubkey, Account::new(BASE_LAMPORTS, 0, &program_id)),
                (receiver_pubkey, Account::new(BASE_LAMPORTS, 0, &program_id)),
                (extra_pubkey, Account::new(BASE_LAMPORTS, 0, &program_id)),
            ],
            &[Check::err(ProgramError::Custom(1))],
        );
    }

    #[test]
    fn test_duplicate_accounts() {
        let program_id = get_program_id();
        let mollusk = Mollusk::new(&program_id, "deploy/asm-transfer-lamports");

        let sender_pubkey = Pubkey::new_unique();

        let instruction = Instruction::new_with_bytes(
            program_id,
            &[],
            // duplicate accounts
            vec![
                AccountMeta::new(sender_pubkey, true),
                AccountMeta::new(sender_pubkey, true),
            ],
        );
        mollusk.process_and_validate_instruction(
            &instruction,
            &[(sender_pubkey, Account::new(BASE_LAMPORTS, 0, &program_id))],
            &[Check::err(ProgramError::Custom(2))],
        );
    }

    #[test]
    fn test_invalid_instruction_data() {
        let program_id = get_program_id();
        let mollusk = Mollusk::new(&program_id, "deploy/asm-transfer-lamports");

        let sender_pubkey = Pubkey::new_unique();
        let receiver_pubkey = Pubkey::new_unique();

        let instruction = Instruction::new_with_bytes(
            program_id,
            // empty instruction data
            &[],
            vec![
                AccountMeta::new(sender_pubkey, true),
                AccountMeta::new(receiver_pubkey, true),
            ],
        );
        mollusk.process_and_validate_instruction(
            &instruction,
            &[
                (sender_pubkey, Account::new(BASE_LAMPORTS, 0, &program_id)),
                (receiver_pubkey, Account::new(BASE_LAMPORTS, 0, &program_id)),
            ],
            &[Check::err(ProgramError::Custom(3))],
        );
    }

    #[test]
    fn test_transfer_lamports() {
        let program_id = get_program_id();
        let mollusk = Mollusk::new(&program_id, "deploy/asm-transfer-lamports");

        let sender_pubkey = Pubkey::new_unique();
        let receiver_pubkey = Pubkey::new_unique();

        let instruction_data = DEPOSIT_LAMPORTS.to_le_bytes();
        let instruction = Instruction::new_with_bytes(
            program_id,
            &instruction_data,
            vec![
                AccountMeta::new(sender_pubkey, true),
                AccountMeta::new(receiver_pubkey, true),
            ],
        );
        mollusk.process_and_validate_instruction(
            &instruction,
            &[
                (sender_pubkey, Account::new(BASE_LAMPORTS, 0, &program_id)),
                (receiver_pubkey, Account::new(BASE_LAMPORTS, 0, &program_id)),
            ],
            &[
                Check::success(),
                Check::account(&sender_pubkey)
                    .lamports(BASE_LAMPORTS - DEPOSIT_LAMPORTS)
                    .build(),
                Check::account(&receiver_pubkey)
                    .lamports(BASE_LAMPORTS + DEPOSIT_LAMPORTS)
                    .build(),
            ],
        );
    }
}
