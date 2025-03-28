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
        tail_latency = np.mean([float(x) for x in re.findall(r'99%_tail_latency\s+([\d.]+)', content)])
        
        data[combined_config] = {
            'Xmem L3 Miss Rate': xmem_miss_rate,
            '99% Tail Latency': tail_latency,
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
    
    # Sort configurations by XMem way allocation
    def sort_by_xmem(configs):
        return dict(sorted(configs.items(), key=lambda x: int(x[0].split('\n')[1], 16)))
    
    ddio_on_configs = sort_by_xmem(ddio_on_configs)
    ddio_off_configs = sort_by_xmem(ddio_off_configs)
    
    # Combine all configurations in the desired order
    all_configs = list(ddio_on_configs.keys()) + list(ddio_off_configs.keys()) + list(xmem_sol_configs.keys())
    
    # Extract data for plotting
    xmem_miss_rates = [data[config]['Xmem L3 Miss Rate'] for config in all_configs]
    tail_latencies = [data[config]['99% Tail Latency'] for config in all_configs]
    
    # Create figure with dual y-axes
    fig, ax1 = plt.subplots(figsize=(12, 7))
    ax2 = ax1.twinx()
    
    # Set positions for bars
    bar_positions = np.arange(len(all_configs))
    bar_width = 0.6
    
    # Set colors based on DCA status
    bar_colors = ['blue' if 'DCA ON' in config else 'orange' if 'DCA OFF' in config else 'green' for config in all_configs]
    
    # Plot bars for tail latency
    bars = ax1.bar(bar_positions, tail_latencies, bar_width, alpha=0.7, 
                   color=bar_colors, label='99% Tail Latency')
    
    # Plot line for XMem L3 miss rate on secondary y-axis
    line = ax2.plot(bar_positions, xmem_miss_rates, 'r-', marker='o', 
                    label='X-Mem L3 Miss Rate', linewidth=2.5, markersize=8, zorder=5)
    
    # Set labels and title
    ax1.set_xlabel('Configuration')
    ax1.set_ylabel('99% Tail Latency (μs)')
    ax2.set_ylabel('X-Mem L3 Miss Rate (%)')
    plt.title('Tail Latency and X-Mem L3 Miss Rate vs. Configuration')
    
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
