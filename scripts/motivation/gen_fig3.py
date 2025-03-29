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
    sections = re.findall(r'==========Monitoring Result \(0x([0-9A-F]+)\)==========(.*?)(?===========|\Z)', 
                         content, re.DOTALL)
    
    data = {}
    for section in sections:
        config = '0x' + section[0]
        content = section[1]
        
        # Extract metrics
        dpdk_miss_rate = np.mean([float(x) for x in re.findall(r'DPDK L3 Miss Rate\s+([\d.]+)', content)])
        xmem_miss_rate = np.mean([float(x) for x in re.findall(r'Xmem L3 Miss Rate\s+([\d.]+)', content)])
        
        # Extract bandwidth data
        read_bw_pattern = r'Average Read BW \(0x[0-9A-F]+\)\s+([\d.]+)'
        read_bw = np.mean([float(x) for x in re.findall(read_bw_pattern, content)])
        
        write_bw_pattern = r'Average Write BW \(0x[0-9A-F]+\)\s+([\d.]+)'
        write_bw = np.mean([float(x) for x in re.findall(write_bw_pattern, content)])
        
        data[config] = {
            'DPDK L3 Miss Rate': dpdk_miss_rate,
            'Xmem L3 Miss Rate': xmem_miss_rate,
            'Read BW': read_bw,
            'Write BW': write_bw
        }
    
    return data

def main():
    # Get the full path from command line argument
    if len(sys.argv) > 1:
        results_path = sys.argv[1]
    else:
        print("Usage: python gen_fig3.py <full_path_to_results_folder>")
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
    
    # Sort configurations by value
    configs = sorted(data.keys(), key=lambda x: int(x, 16), reverse=True)
    
    # Extract data for plotting
    dpdk_miss_rates = [data[config]['DPDK L3 Miss Rate'] for config in configs]
    xmem_miss_rates = [data[config]['Xmem L3 Miss Rate'] for config in configs]
    read_bws = [data[config]['Read BW'] for config in configs]
    write_bws = [data[config]['Write BW'] for config in configs]
    
    # Create figure with dual y-axes
    fig, ax1 = plt.subplots(figsize=(10, 6))
    ax2 = ax1.twinx()
    
    # First plot the bars with some transparency
    width = 0.4
    bar_positions = np.arange(len(configs))
    read_bars = ax2.bar(bar_positions, read_bws, width, label='Read BW', 
                        color='lightgreen', alpha=0.7)
    write_bars = ax2.bar(bar_positions, write_bws, width, bottom=read_bws, 
                         label='Write BW', color='darkgreen', alpha=0.7)
    
    # Force draw the current figure to ensure bars are rendered first
    fig.canvas.draw()
    
    # Now plot the lines on top
    dpdk_line = ax1.plot(bar_positions, dpdk_miss_rates, 'b-', marker='o', 
                         label='DPDK L3 Miss Rate', linewidth=2.5, markersize=8)
    xmem_line = ax1.plot(bar_positions, xmem_miss_rates, 'r-', marker='s', 
                         label='Xmem L3 Miss Rate', linewidth=2.5, markersize=8)
    
    # Ensure lines appear on top in the final render
    plt.figure(fig.number)
    
    # Set labels and title
    ax1.set_xlabel('X-Mem Way Allocation')
    ax1.set_ylabel('L3 Miss Rate (%)')
    ax1.set_ylim(0,100)
    ax2.set_ylabel('Memory Bandwidth (GB/s)')
    plt.title('L3 Miss Rate and Memory Bandwidth vs. DDIO Configuration')
    
    # Set x-ticks
    plt.xticks(bar_positions, configs)
    
    # Create combined legend
    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax1.legend(lines1 + lines2, labels1 + labels2, loc='best')
    
    # Adjust layout
    plt.tight_layout()
    
    # Save figure with name based on directory
    dir_name = os.path.basename(results_path)
    if dir_name == "Fig3_dpdk-rx":
        output_filename = "fig3a.png"
    elif dir_name == "Fig3_nt-dpdk-rx":
        output_filename = "fig3b.png"
    else:
        output_filename = "fig3.png"
        
    output_path = os.path.join(results_path, output_filename)
    plt.savefig(output_path, dpi=300)
    
    print(f"Figure saved to {output_path}")
    
    # Show plot
    plt.show()

if __name__ == "__main__":
    main()
