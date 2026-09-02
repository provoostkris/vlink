## VHDL Coding Standard & Guidelines

- **Libraries:** Always use standard IEEE libraries (`ieee.std_logic_1164.all` and `ieee.numeric_std.all`). Avoid outdated libraries like `ieee.std_logic_arith` or `ieee.std_logic_unsigned`.
- **Types:** Use `unsigned` and `signed` types for arithmetic operations. Avoid `std_logic_vector` for arithmetic.
- **Resets:**
  - Prefer synchronous resets and asynchronous resets in all sequential processes
  - Put the reset assignments in a procedure and use that process to reset all signals.
  - The reset procedure should be named 'do_reset'
  - The synchronous reset should be named 's_rst'
  - the asynchronous reset should be named 'a_rst'
  - Use `a_rst` as the first condition in the process sensitivity list.
- **Clock Edges:**
Always use `rising_edge(clk)` for synchronous logic.
- **Naming Conventions:**
  - Signals and variables: `snake_case` (e.g., `data_counter`, `fifo_empty`)
  - Constants: `c_` prefix followed by `lower_case` (e.g., `c_data_width`, `c_timeout_limit`)
  - Generics: `g_` prefix followed by `lower_case` (e.g., `g_data_width`, `g_timeout_limit`)
  - Variables: `v_` prefix followed by `lower_case` (e.g., `v_data_counter`, `v_fifo_empty`)
  - Entity: Name matching the filename.