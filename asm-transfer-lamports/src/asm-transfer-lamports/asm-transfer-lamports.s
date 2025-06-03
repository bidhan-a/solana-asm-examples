.globl entrypoint

entrypoint:
  ldxdw r2, [r1 + 0]                                            # Load number of accounts to r2.
  jne r2, 2, error_invalid_num_accounts                         # Exit with an error if we don't have exactly 2 accounts.
  add64 r1, 8                                                   # Add 8 to r1 (move input data forward by 8 bytes).

  # First account
  ldxdw r2, [r1 + 8 + 32 + 32]                                  # Load source account lamports to r2.
  ldxdw r3, [r1 + 8 + 32 + 32 + 8]                              # Load account data size to r3.
  mov64 r4, r1                                                  # Copy pointer r1 into r4.
  add64 r4, 8 + 32 + 32 + 8 + 8 + 10240 + 8                     # Load the end of first account to r4.
  add64 r4, r3                                                  # Add account data size to r4.
  mov64 r5, r4                                                  # Copy r4 to r5.
  and64 r4, -8                                                  # Align to 8 bytes.
  jeq r5, r4, 1                                                 # If already aligned, skip the next step. 
  add64 r4, 8                                                   # Otherwise, add 8 bytes.

  # Second account
  ldxb r5, [r4 + 0]                                             # Load first byte of second account to r5.
  jne r5, 0xff, error_duplicate_accounts                        # Exit if it's a duplicate account.
  ldxdw r5, [r4 + 8 + 32 + 32]                                  # Load destination account lamports to r5.
  ldxdw r6, [r4 + 8 + 32 + 32 + 8]                              # Load account data size to r6.
  mov64 r7, r4                                                  # Copy pointer r4 into r7.
  add64 r7, 8 + 32 + 32 + 8 + 8 + 10240 + 8                     # Load the end of second account to r7.
  add64 r7, r6                                                  # Add account data size to r7.
  mov64 r8, r7                                                  # Copy r7 to r8.
  and64 r7, -8                                                  # Align to 8 bytes.
  jeq r8, r7, 1                                                 # If already aligned, skip the next step.
  add64 r7, 8                                                   # Otherwise, add 8 bytes.

  # Instruction data
  ldxdw r8, [r7 + 0]                                            # Load instruction data size to r8.
  jne r8, 8, error_invalid_instruction_data                     # Exit if we don't have exactly 8 bytes.
  ldxdw r8, [r7 + 8]                                            # Load instruction data to r8.

  # Transfer lamports
  sub64 r2, r8                                                  # Subtract lamports from source account (r2).
  add64 r5, r8                                                  # Add lamports to destination account (r5).
  stxdw [r1 + 8 + 32 + 32], r2                                  # Write new lamports to source.
  stxdw [r4 + 8 + 32 + 32], r5                                  # Write new lamports to destination.

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
