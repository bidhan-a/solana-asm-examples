.equ NUM_ACCOUNTS, 0x0000

.equ SENDER_HEADER, 0x0008
.equ SENDER_KEY, 0x0010
.equ SENDER_OWNER, 0x0030
.equ SENDER_LAMPORTS, 0x0050
.equ SENDER_DATA_LEN, 0x0058
.equ SENDER_DATA, 0x0060

.equ RECEIVER_HEADER, 0x2868
.equ RECEIVER_KEY, 0x2870
.equ RECEIVER_OWNER, 0x2890
.equ RECEIVER_LAMPORTS, 0x28b0
.equ RECEIVER_DATA_LEN, 0x28b8
.equ RECEIVER_DATA, 0x28c0

.equ INSTRUCTION_DATA_LEN, 0x50c8
.equ INSTRUCTION_DATA, 0x50d0
.equ PROGRAM_ID, 0x50d0

.globl entrypoint

entrypoint:
  ldxdw r2, [r1 + NUM_ACCOUNTS]                                 # Load number of accounts to r2.
  jne r2, 2, error_invalid_num_accounts                         # Exit with an error if we don't have exactly 2 accounts.

  # First account
  ldxdw r2, [r1 + SENDER_LAMPORTS]                              # Load source account lamports to r2.

  # Second account
  ldxb r3, [r1 + RECEIVER_HEADER]                               # Load first byte of second account to r3.
  jne r3, 0xff, error_duplicate_accounts                        # Exit if it's a duplicate account.
  ldxdw r3, [r1 + RECEIVER_LAMPORTS]                            # Load destination account lamports to r3.

  # Instruction data
  ldxdw r4, [r1 + INSTRUCTION_DATA_LEN]                         # Load instruction data size to r4.
  jne r4, 8, error_invalid_instruction_data                     # Exit if we don't have exactly 8 bytes.
  ldxdw r4, [r1 + INSTRUCTION_DATA]                             # Load instruction data to r4.

  # Transfer lamports
  sub64 r2, r4                                                  # Subtract lamports from source account (r2).
  add64 r3, r4                                                  # Add lamports to destination account (r5).
  stxdw [r1 + SENDER_LAMPORTS], r2                              # Write new lamports to source.
  stxdw [r1 + RECEIVER_LAMPORTS], r3                            # Write new lamports to destination.

  # Log success message
  lddw r1, message                                              # Load success message to r1.
  lddw r2, 34                                                   # Load message length to r2.
  call sol_log_                                                 # Log the message.

  exit                                                          # Exit.

error_invalid_num_accounts:
  lddw r0, 1                                                    # Load error code 1 to r0.
  exit                                                          # Exit.

error_duplicate_accounts:
  lddw r0, 2                                                    # Load error code 2 to r0.
  exit                                                          # Exit.

error_invalid_instruction_data:
  lddw r0, 3                                                    # Load error code 3 to r0.
  exit                                                          # Exit.

.rodata
  message: .ascii "Lamports transferred successfully."
