import matplotlib.pyplot as plt
import numpy as np
import os
import re
import sys

# Function to parse results file
def parse_results(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Extract all monitoring sections
    sections = re.findall(r'==========Monitoring Result \((fio0x?[0-9A-Fa-f]*)\)==========(.*?)(?===========|\Z)', 
                         content, re.DOTALL)
    
    print(f"Found {len(sections)} sections in the results file")
    
    data = {}
    for section in sections:
        config = section[0]
        section_content = section[1].strip()
        
        # Initialize collections for metrics
        xmem_miss_rates = []
        storage_throughput_r_values = []
        
        # Process each line in the section
        for line in section_content.split('\n'):
            if not line.strip():
                continue
                
            # Split the line by tabs or multiple spaces
            parts = re.split(r'\t+|\s{2,}', line.strip())
            if len(parts) < 2:
                continue
                
            field_name = parts[0].strip()
            # Extract all numeric values from the line
            values = []
            for value_part in parts[1:]:
                for val in value_part.strip().split():
                    if re.match(r'^[\d.]+$', val):
                        values.append(float(val))
            
            if not values:
                continue
                
            # Match field names with appropriate collections
            if field_name == "Xmem_L3_Miss_Rate":
                xmem_miss_rates.extend(values)
            elif field_name == "Storage1_Throughput_R(GB/s)":
                storage_throughput_r_values.extend(values)
        
        # Calculate averages if we found values
        if xmem_miss_rates:
            xmem_miss_rate = np.mean(xmem_miss_rates)
        else:
            print(f"Warning: No Xmem L3 Miss Rate found for {config}")
            xmem_miss_rate = 0
            
        if storage_throughput_r_values:
            storage_throughput_r = np.mean(storage_throughput_r_values)
        else:
            print(f"Warning: No Storage Throughput R found for {config}")
            storage_throughput_r = 0
        
        # Store in our data dictionary
        data[config] = {
            'Xmem L3 Miss Rate': xmem_miss_rate,
            'Storage Throughput R': storage_throughput_r
        }
    
    return data

def main():
    # Get the full path from command line argument
    if len(sys.argv) > 1:
        results_path = sys.argv[1]
    else:
        print("Usage: python gen_fig8b.py <full_path_to_results_folder>")
        sys.exit(1)
    
    # Validate the path and construct the results.txt path
    if not os.path.isdir(results_path):
        results_path = os.path.dirname(results_path)
    
    results_file = os.path.join(results_path, 'results.txt')
    if not os.path.exists(results_file):
        print(f"Error: Results file not found at {results_file}")
        sys.exit(1)
    
    # Parse data
    data = parse_results(results_file)
    
    # Define the order of way allocations
    way_order = ['fio0x1e0', 'fio0x1c0', 'fio0x180', 'fio0x100', 'fio0']
    
    # Filter and organize configs according to the defined order
    ordered_data = {}
    for way in way_order:
        if way in data:
            ordered_data[way] = data[way]
        else:
            print(f"Warning: Configuration {way} not found in results file")
    
    # Use ordered configs for plotting
    configs = list(ordered_data.keys())
    
    # Extract data for plotting
    xmem_miss_rates = [ordered_data[config]['Xmem L3 Miss Rate'] for config in configs]
    
    # Create separate data and positions for storage throughput (excluding X-Mem Solo)
    storage_positions = []
    storage_throughputs = []
    
    for i, config in enumerate(configs):
        if config != 'fio0':  # Skip X-Mem Solo
            storage_positions.append(i)
            storage_throughputs.append(ordered_data[config]['Storage Throughput R'])
    
    # Create figure with dual y-axes
    fig, ax1 = plt.subplots(figsize=(10, 6))
    ax2 = ax1.twinx()
    
    # Set y-axis limits
    ax1.set_ylim(0, 40)  # Main y-axis (Xmem L3 Miss Rate)
    ax2.set_ylim(0, 15)  # Secondary y-axis (Storage Throughput)
    
    # Plot Xmem miss rate as bars on main y-axis
    bar_positions = np.arange(len(configs))
    bar_width = 0.6
    bars = ax1.bar(bar_positions, xmem_miss_rates, bar_width, 
                   alpha=0.7, color='steelblue', 
                   label='Xmem L3 Miss Rate')
    
    # Plot storage throughput as line on secondary y-axis - excluding X-Mem Solo
    line = ax2.plot(storage_positions, storage_throughputs, 'r-o', linewidth=2, 
                    label='Storage Throughput Read', zorder=5)
    
    # Set labels and title
    ax1.set_xlabel('FIO Way Allocation')
    ax1.set_ylabel('Xmem L3 Miss Rate (%)')
    ax2.set_ylabel('Storage Throughput Read (GB/s)')
    plt.title('Xmem L3 Miss Rate and Storage Throughput vs. FIO Way Allocation')
    
    # Clean up config names for display
    display_configs = []
    for config in configs:
        if config == 'fio0':
            display_configs.append('X-Mem Solo')
        else:
            display_configs.append(config.replace('fio', ''))
    
    # Set x-ticks
    plt.xticks(bar_positions, display_configs, rotation=45)
    
    # Create combined legend
    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax1.legend(lines1 + lines2, labels1 + labels2, loc='best')
    
    # Adjust layout
    plt.tight_layout()
    
    # Save figure in the same folder as the results file
    output_path = os.path.join(results_path, 'fig8b.png')
    plt.savefig(output_path, dpi=300)
    
    print(f"Figure saved to {output_path}")
    
    # Show plot
    plt.show()

if __name__ == "__main__":
    main()
