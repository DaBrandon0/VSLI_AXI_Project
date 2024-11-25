import argparse
import sys
import pandas as pd
import math
import os


class FSMConverter:
    """
    A class to convert an FSM described in a CSV file into a Verilog module.
    """

    def __init__(self, csv_file, output_file=None):
        self.csv_file = csv_file
        self.output_file = output_file or self._default_output_file()
        self.df = None
        self.input_columns = []
        self.output_columns = []
        self.input_bits = {}
        self.output_bits = {}
        self.states = []
        self.initial_state = None
        self.state_encodings = {}
        self.state_bits = 0

    def _default_output_file(self):
        module_name = os.path.splitext(os.path.basename(self.csv_file))[0]
        return module_name + '.v'

    def parse_csv(self):
        """
        Reads the CSV file and stores it in a pandas DataFrame.
        """
        try:
            self.df = pd.read_csv(self.csv_file, dtype=str)
            self.df.fillna('0', inplace=True)  # Replace NaNs with '0'
        except Exception as e:
            raise ValueError(f"Error reading CSV file: {e}")

    def validate(self):
        """
        Validates the CSV data to ensure it meets the required format.
        """
        self._check_required_columns()
        self.input_columns, self.output_columns = self._get_input_output_columns()
        self._check_state_entries()
        self._check_state_sets()
        self._check_integer_columns()
        self._process_data()

    def _check_required_columns(self):
        """
        Checks that the CSV has the required 'Current State' and 'Next State' columns.
        """
        columns = self.df.columns
        if columns[0] != 'Current State':
            raise ValueError("The first column must be named 'Current State'.")
        if 'Next State' not in columns:
            raise ValueError("The 'Next State' column is missing.")

    def _get_input_output_columns(self):
        """
        Identifies input and output columns based on their positions.
        """
        columns = self.df.columns
        current_state_idx = columns.get_loc('Current State')
        next_state_idx = columns.get_loc('Next State')
        input_cols = columns[current_state_idx + 1:next_state_idx]
        output_cols = columns[next_state_idx + 1:]

        if len(input_cols) == 0:
            raise ValueError("There must be at least one column between 'Current State' and 'Next State'.")
        if len(output_cols) == 0:
            raise ValueError("There must be at least one column after 'Next State'.")

        return input_cols.tolist(), output_cols.tolist()

    def _check_state_entries(self):
        """
        Ensures all entries in 'Current State' and 'Next State' are non-empty strings.
        """
        for col in ['Current State', 'Next State']:
            if self.df[col].isnull().any():
                raise ValueError(f"All entries in '{col}' must be non-empty strings.")
            if not self.df[col].apply(lambda x: isinstance(x, str) and x.strip()).all():
                raise ValueError(f"All entries in '{col}' must be non-empty strings.")

    def _check_state_sets(self):
        """
        Validates that all states in 'Next State' are present in 'Current State'.
        """
        current_states = set(self.df['Current State'])
        next_states = set(self.df['Next State'])
        if not next_states.issubset(current_states):
            raise ValueError("All states in 'Next State' must be present in 'Current State'.")

    def _check_integer_columns(self):
        """
        Ensures input and output columns contain valid integers or wildcards.
        """
        errors = []
        for col in self.input_columns + self.output_columns:
            # Allow integers or '*'
            if not self.df[col].apply(lambda x: x.isdigit() or x.strip() == '*').all():
                errors.append(f"Column '{col}' must contain integers or '*' (wildcard).")
        if errors:
            raise ValueError("Validation failed with the following errors:\n" + "\n".join(errors))

    def _process_data(self):
        """
        Processes the data to calculate bits required and assign state encodings.
        """
        self.states = self.df['Current State'].unique().tolist()
        self.initial_state = self.states[0]
        self.input_bits = self._calculate_bits_required(self.input_columns)
        self.output_bits = self._calculate_bits_required(self.output_columns)
        self.state_encodings, self.state_bits = self._assign_state_encodings(self.states)

    def _calculate_bits_required(self, columns):
        """
        Calculates the number of bits required to represent each column.
        """
        bits_required = {}
        for col in columns:
            column_values = self.df[col].replace('*', '0').astype(int)
            max_value = column_values.max()
            bits = max(1, int(math.ceil(math.log2(max_value + 1))))
            bits_required[col] = bits
        return bits_required

    def _assign_state_encodings(self, states):
        """
        Assigns binary encodings to each state.
        """
        num_states = len(states)
        bits_needed = max(1, int(math.ceil(math.log2(num_states))))
        state_encodings = {state: idx for idx, state in enumerate(states)}
        return state_encodings, bits_needed

    def generate_verilog(self):
        """
        Generates the Verilog module and writes it to the output file.
        """
        module_name = os.path.splitext(os.path.basename(self.output_file))[0]
        with open(self.output_file, 'w') as f:
            self._write_module_header(f, module_name)
            self._write_state_declarations(f)
            self._write_state_transition_logic(f)
            self._write_next_state_logic(f)
            f.write("endmodule\n")
        print(f"\nVerilog module '{module_name}' has been written to '{self.output_file}'.")

    def _write_module_header(self, f, module_name):
        """
        Writes the module declaration with port definitions.
        """
        f.write(f"module {module_name} (\n")
        port_lines = ["    input clk", "    input reset"]
        for input_name, bits in self.input_bits.items():
            if bits == 1:
                port_lines.append(f"    input {input_name}")
            else:
                port_lines.append(f"    input [{bits - 1}:0] {input_name}")
        for output_name, bits in self.output_bits.items():
            if bits == 1:
                port_lines.append(f"    output reg {output_name}")
            else:
                port_lines.append(f"    output reg [{bits - 1}:0] {output_name}")
        ports_str = ',\n'.join(port_lines)
        f.write(ports_str + '\n')
        f.write(");\n\n")

    def _write_state_declarations(self, f):
        """
        Writes the state register and encoding parameters.
        """
        f.write(f"    reg [{self.state_bits - 1}:0] current_state;\n")
        f.write(f"    reg [{self.state_bits - 1}:0] next_state;\n\n")
        f.write("    // State encodings\n")
        for state, code in self.state_encodings.items():
            f.write(f"    parameter {state.upper()} = {self.state_bits}'d{code};\n")
        f.write("\n")

    def _write_state_transition_logic(self, f):
        """
        Writes the always block for state transitions.
        """
        f.write("    // State transition\n")
        f.write("    always @(posedge clk or negedge reset) begin\n")
        f.write("        if (!reset)\n")
        f.write(f"            current_state <= {self.initial_state.upper()};\n")
        f.write("        else\n")
        f.write("            current_state <= next_state;\n")
        f.write("    end\n\n")

    def _write_next_state_logic(self, f):
        """
        Writes the combinational logic for next state and outputs.
        """
        f.write("    // Next state and output logic\n")
        f.write("    always @(*) begin\n")
        f.write("        next_state = current_state;\n")
        # Initialize outputs to zero
        for output_name in self.output_columns:
            bits = self.output_bits[output_name]
            if bits == 1:
                f.write(f"        {output_name} = 0;\n")
            else:
                f.write(f"        {output_name} = {bits}'d0;\n")
        f.write("\n")
        f.write("        case (current_state)\n")
        for state in self.states:
            f.write(f"            {state.upper()}: begin\n")
            # Get all rows where Current State == state
            state_rows = self.df[self.df['Current State'] == state]
            if not state_rows.empty:
                for _, row in state_rows.iterrows():
                    # Generate conditions based on input values
                    conditions = []
                    for input_name in self.input_columns:
                        input_value = row[input_name]
                        bits = self.input_bits[input_name]
                        if input_value.strip() == '*':
                            continue  # Skip condition for wildcard
                        if bits == 1:
                            conditions.append(f"{input_name} == {input_value}")
                        else:
                            conditions.append(f"{input_name} == {bits}'d{input_value}")
                    if conditions:
                        condition_str = ' && '.join(conditions)
                        f.write(f"                if ({condition_str}) begin\n")
                    else:
                        f.write(f"                begin\n")
                    # Set next state
                    next_state_name = row['Next State']
                    f.write(f"                    next_state = {next_state_name.upper()};\n")
                    # Set outputs
                    for output_name in self.output_columns:
                        output_value = row[output_name]
                        bits = self.output_bits[output_name]
                        if output_value.strip() == '*':
                            continue  # Skip assignment for wildcard
                        if bits == 1:
                            f.write(f"                    {output_name} = {output_value};\n")
                        else:
                            f.write(f"                    {output_name} = {bits}'d{output_value};\n")
                    f.write("                end\n")
            f.write("            end\n")
        f.write("        endcase\n")
        f.write("    end\n\n")

    def run(self):
        """
        Executes the conversion process.
        """
        try:
            self.parse_csv()
            self.validate()
            self.generate_verilog()
        except ValueError as e:
            print(f"Error: {e}")
            sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description='Convert FSM CSV file to Verilog module.')
    parser.add_argument('csv_file', help='Path to the CSV file.')
    parser.add_argument('-o', '--output', help='Output Verilog file name.')
    args = parser.parse_args()

    converter = FSMConverter(args.csv_file, args.output)
    converter.run()


if __name__ == "__main__":
    main()
