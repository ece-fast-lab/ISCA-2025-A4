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
    sections = re.findall(r'==========Monitoring Result \((.*?)\)==========(.*?)(?===========|\Z)', 
                         content, re.DOTALL)
    
    data = {}
    for section in sections:
        config = section[0]
        content = section[1]
        
        # Extract DDIO status (on/off) and XMem way allocation
        if 'ddio1' in config:
            ddio_status = 'DCA ON'
        elif 'ddio0' in config:
            ddio_status = 'DCA OFF'
        elif 'xmem_sol' in config:
            ddio_status = 'X-Mem Sol'
        else:
            continue
            
        # Extract XMem way allocation
        xmem_way = re.search(r'xmem(0x[0-9A-Fa-f]+)', config)
        if xmem_way:
            xmem_way = xmem_way.group(1)
        else:
            continue
            
        # Create a combined configuration name
        combined_config = f"{ddio_status}\n{xmem_way}"
        
        # Extract metrics
        xmem_miss_rate = np.mean([float(x) for x in re.findall(r'Xmem L3 Miss Rate\s+([\d.]+)', content)])
        
        # Fix the parsing for Average_latency
        # The results file may have multiple columns of data per metric
        avg_latency_line = re.search(r'Average_latency\s+(.*?)$', content, re.MULTILINE)
        if avg_latency_line:
            # Split the line and extract all numeric values
            avg_latency_values = [float(x) for x in avg_latency_line.group(1).split() if re.match(r'^[\d.]+$', x)]
            if avg_latency_values:
                avg_latency = np.mean(avg_latency_values)
            else:
                avg_latency = 0
        else:
            avg_latency = 0
        
        data[combined_config] = {
            'Xmem L3 Miss Rate': xmem_miss_rate,
            'Average Latency': avg_latency,
            'Config': config  # Store the original config for reference
        }
    
    return data

def main():
    # Get the full path from command line argument
    if len(sys.argv) > 1:
        results_path = sys.argv[1]
    else:
        print("Usage: python gen_fig4.py <full_path_to_results_folder>")
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
    
    # Group configurations by DDIO status
    ddio_on_configs = {k: v for k, v in data.items() if 'DCA ON' in k}
    ddio_off_configs = {k: v for k, v in data.items() if 'DCA OFF' in k}
    xmem_sol_configs = {k: v for k, v in data.items() if 'X-Mem Sol' in k}
    
    # Define the desired xmem order
    xmem_order = ['0x600', '0x0c0', '0x030', '0x003']
    
    # Sort configurations by the specific xmem order
    def sort_by_xmem_custom_order(configs):
        # Create a mapping of xmem value to its position in the desired order
        order_map = {v: i for i, v in enumerate(xmem_order)}
        
        # Sort the configs based on the desired order
        result = {}
        for xmem in xmem_order:
            # Find all configs that match this xmem value
            matching_configs = {k: v for k, v in configs.items() if k.split('\n')[1] == xmem}
            # Add them to the result in the order they were found
            result.update(matching_configs)
        
        # If there are any configs that don't match the predefined values, add them at the end
        for k, v in configs.items():
            if k.split('\n')[1] not in xmem_order:
                result[k] = v
                
        return result
    
    # Apply the custom sorting
    ddio_on_configs = sort_by_xmem_custom_order(ddio_on_configs)
    ddio_off_configs = sort_by_xmem_custom_order(ddio_off_configs)
    
    # Combine all configurations in the desired order
    all_configs = list(ddio_on_configs.keys()) + list(ddio_off_configs.keys()) + list(xmem_sol_configs.keys())
    
    # Extract data for plotting
    xmem_miss_rates = [data[config]['Xmem L3 Miss Rate'] for config in all_configs]
    latencies = []
    
    # Only include latency values for non-X-Mem Sol configurations
    for i, config in enumerate(all_configs):
        if 'X-Mem Sol' in config:
            latencies.append(np.nan)  # Use NaN to hide the bar for X-Mem Sol
        else:
            latencies.append(data[config]['Average Latency'])
    
    # Create figure with dual y-axes
    fig, ax1 = plt.subplots(figsize=(12, 7))
    ax2 = ax1.twinx()
    
    # Set positions for bars
    bar_positions = np.arange(len(all_configs))
    bar_width = 0.6
    
    # Set colors based on DCA status
    bar_colors = ['blue' if 'DCA ON' in config else 'orange' if 'DCA OFF' in config else 'green' for config in all_configs]
    
    # Plot bars for average latency (NaN values will be skipped)
    bars = ax1.bar(bar_positions, latencies, bar_width, alpha=0.7, 
                   color=bar_colors, label='Average Latency')
    
    # Plot line for XMem L3 miss rate on secondary y-axis
    line = ax2.plot(bar_positions, xmem_miss_rates, 'r-', marker='o', 
                    label='X-Mem L3 Miss Rate', linewidth=2.5, markersize=8, zorder=5)
    
    # Set labels and title
    ax1.set_xlabel('Configuration')
    ax1.set_ylabel('Average Network Latency (μs)')
    ax2.set_ylabel('X-Mem L3 Miss Rate (%)')
    ax2.set_ylim(0,100)
    plt.title('Average Network Latency and X-Mem L3 Miss Rate vs. Configuration')
    
    # Set x-ticks
    plt.xticks(bar_positions, all_configs, rotation=45, ha='right')
    
    # Add a vertical line to separate DCA ON/OFF sections
    on_count = len(ddio_on_configs)
    off_count = len(ddio_off_configs)
    if on_count > 0 and off_count > 0:
        ax1.axvline(x=on_count-0.5, color='black', linestyle='--', alpha=0.5)
    if off_count > 0 and len(xmem_sol_configs) > 0:
        ax1.axvline(x=on_count+off_count-0.5, color='black', linestyle='--', alpha=0.5)
    
    # Add legend
    handles1, labels1 = ax1.get_legend_handles_labels()
    handles2, labels2 = ax2.get_legend_handles_labels()
    
    # Create custom handles for DCA status
    from matplotlib.patches import Patch
    dca_on_patch = Patch(color='blue', label='DCA ON')
    dca_off_patch = Patch(color='orange', label='DCA OFF')
    xmem_sol_patch = Patch(color='green', label='X-Mem Sol')
    
    legend_handles = [dca_on_patch, dca_off_patch, xmem_sol_patch] + handles2
    ax1.legend(handles=legend_handles, loc='upper center', bbox_to_anchor=(0.5, -0.15), 
               shadow=True, ncol=4)
    
    # Adjust layout
    plt.tight_layout()
    plt.subplots_adjust(bottom=0.2)
    
    # Save figure in the same folder as the results file
    output_path = os.path.join(results_path, 'fig4.png')
    plt.savefig(output_path, dpi=300)
    
    print(f"Figure saved to {output_path}")
    
    # Show plot
    plt.show()

if __name__ == "__main__":
    main()
