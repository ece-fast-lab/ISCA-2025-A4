import matplotlib.pyplot as plt
import numpy as np
import os
import re
import sys

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
        
        # Only look at ddio0 and ddio2 configs
        if 'ddio1' in config:
            continue
            
        # Extract block size and DCA status
        if 'dpdk_solo' in config:
            block_size = 'dpdk_solo'
        else:
            match = re.search(r'dpdk1024\+fio(\d+k)', config)
            if match:
                block_size = match.group(1)
            else:
                continue
        
        # Set DCA status: ddio0 = DCA Both ON, ddio2 = STG DCA OFF
        dca_status = 'stg_off' if 'ddio2' in config else 'both_on'
        
        # Extract metrics
        avg_latency_match = re.search(r'Average_latency\s+([\d.]+)', content)
        tail_latency_match = re.search(r'99%_tail_latency\s+([\d.]+)', content)
        storage_throughput_match = re.search(r'Storage1_Throughput_R\(GB/s\)\s+([\d.]+)', content)
        
        if avg_latency_match and tail_latency_match and storage_throughput_match:
            avg_latency = float(avg_latency_match.group(1))
            tail_latency = float(tail_latency_match.group(1))
            storage_throughput = float(storage_throughput_match.group(1))
            
            key = (block_size, dca_status)
            data[key] = {
                'Average Latency': avg_latency,
                '99% Tail Latency': tail_latency,
                'Storage Throughput': storage_throughput
            }
    
    return data

def main():
    # Get the full path from command line argument
    if len(sys.argv) > 1:
        results_path = sys.argv[1]
    else:
        print("Usage: python gen_fig8a.py <full_path_to_results_folder>")
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
    
    # Define block size order - limit to 16k through 512k
    block_sizes = ['16k', '32k', '64k', '128k', '256k', '512k']
    
    # Extract data for plotting
    dca_both_on_latency = []
    dca_both_on_tail = []
    dca_both_on_throughput = []
    
    dca_stg_off_latency = []
    dca_stg_off_tail = []
    dca_stg_off_throughput = []
    
    for block_size in block_sizes:
        both_on_key = (block_size, 'both_on')
        stg_off_key = (block_size, 'stg_off')
        
        if both_on_key in data:
            dca_both_on_latency.append(data[both_on_key]['Average Latency'])
            dca_both_on_tail.append(data[both_on_key]['99% Tail Latency'] - data[both_on_key]['Average Latency'])
            dca_both_on_throughput.append(data[both_on_key]['Storage Throughput'])
        else:
            dca_both_on_latency.append(0)
            dca_both_on_tail.append(0)
            dca_both_on_throughput.append(0)
            
        if stg_off_key in data:
            dca_stg_off_latency.append(data[stg_off_key]['Average Latency'])
            dca_stg_off_tail.append(data[stg_off_key]['99% Tail Latency'] - data[stg_off_key]['Average Latency'])
            dca_stg_off_throughput.append(data[stg_off_key]['Storage Throughput'])
        else:
            dca_stg_off_latency.append(0)
            dca_stg_off_tail.append(0)
            dca_stg_off_throughput.append(0)
    
    # Create figure with dual y-axes
    fig, ax1 = plt.subplots(figsize=(14, 8))
    ax2 = ax1.twinx()
    
    # Set y-axis limits
    ax1.set_ylim(0, 900)  # Main y-axis (Latency)
    ax2.set_ylim(0, 15)   # Secondary y-axis (Throughput)
    
    # Set positions for bars
    x = np.arange(len(block_sizes))
    width = 0.35
    
    # Plot bars for latency with error bars for tail latency
    bars1 = ax1.bar(x - width/2, dca_both_on_latency, width, label='DCA Both ON Avg Latency', 
                   color='lightcoral', alpha=0.7)
    ax1.errorbar(x - width/2, dca_both_on_latency, yerr=[np.zeros_like(dca_both_on_tail), dca_both_on_tail], 
                fmt='none', ecolor='darkred', capsize=5)
    
    bars2 = ax1.bar(x + width/2, dca_stg_off_latency, width, label='STG DCA OFF Avg Latency', 
                   color='lightblue', alpha=0.7)
    ax1.errorbar(x + width/2, dca_stg_off_latency, yerr=[np.zeros_like(dca_stg_off_tail), dca_stg_off_tail], 
                fmt='none', ecolor='darkblue', capsize=5)
    
    # Create separate data for storage throughput
    # Since we don't have dpdk_solo in our filtered list anymore, we can use all indices
    x_filtered = x
    dca_both_on_throughput_filtered = dca_both_on_throughput
    dca_stg_off_throughput_filtered = dca_stg_off_throughput
    
    # Plot lines for storage throughput
    line1 = ax2.plot(x_filtered, dca_both_on_throughput_filtered, 'r-', linewidth=2, marker='o', 
                    label='DCA Both ON Storage Throughput')
    line2 = ax2.plot(x_filtered, dca_stg_off_throughput_filtered, 'b-', linewidth=2, marker='s', 
                    label='STG DCA OFF Storage Throughput')
    
    # Set labels and title
    ax1.set_xlabel('FIO Block Size')
    ax1.set_ylabel('Network Latency (μs)')
    ax2.set_ylabel('Storage Throughput (GB/s)')
    plt.title('Network Latency and Storage Throughput vs. FIO Block Size')
    
    # Set x-ticks
    plt.xticks(x, block_sizes, rotation=45)
    
    # Create combined legend
    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper left')
    
    # Adjust layout
    plt.tight_layout()
    
    # Save figure in the same folder as the results file
    output_path = os.path.join(results_path, 'fig8a.png')
    plt.savefig(output_path, dpi=300)
    
    print(f"Figure saved to {output_path}")
    
    # Show plot
    plt.show()

if __name__ == "__main__":
    main()
