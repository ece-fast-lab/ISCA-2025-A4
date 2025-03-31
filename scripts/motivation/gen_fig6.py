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
    
    print(f"Found {len(sections)} sections in the results file")
    
    data = {}
    for section in sections:
        config = section[0]
        section_content = section[1].strip()
        
        # Only look at ddio0 and ddio1 configs
        if 'ddio2' in config:
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
        
        dca_status = 'on' if 'ddio1' in config else 'off'
        
        # Process each line to extract metrics
        avg_latency_values = []
        tail_latency_values = []
        storage_throughput_values = []
        
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
                
            # Match with specific metrics we need
            if field_name == "Average_latency":
                avg_latency_values.extend(values)
            elif field_name == "99%_tail_latency":
                tail_latency_values.extend(values)
            elif field_name == "Storage1_Throughput_R(GB/s)":
                storage_throughput_values.extend(values)
        
        # Calculate averages if we have values
        if avg_latency_values and tail_latency_values and storage_throughput_values:
            key = (block_size, dca_status)
            data[key] = {
                'Average Latency': np.mean(avg_latency_values),
                '99% Tail Latency': np.mean(tail_latency_values),
                'Storage Throughput': np.mean(storage_throughput_values)
            }
        else:
            print(f"Warning: Missing data for configuration {config}")
            print(f"  Avg Latency: {len(avg_latency_values)} values")
            print(f"  Tail Latency: {len(tail_latency_values)} values")
            print(f"  Storage Throughput: {len(storage_throughput_values)} values")
    
    return data

def main():
    # Get the full path from command line argument
    if len(sys.argv) > 1:
        results_path = sys.argv[1]
    else:
        print("Usage: python gen_fig6.py <full_path_to_results_folder>")
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
    
    # Define block size order
    block_sizes = ['4k', '8k', '16k', '32k', '64k', '128k', '256k', '512k', '1024k', '2048k', 'dpdk_solo']
    
    # Extract data for plotting
    dca_on_latency = []
    dca_on_tail = []
    dca_on_throughput = []
    
    dca_off_latency = []
    dca_off_tail = []
    dca_off_throughput = []
    
    for block_size in block_sizes:
        on_key = (block_size, 'on')
        off_key = (block_size, 'off')
        
        if on_key in data:
            dca_on_latency.append(data[on_key]['Average Latency'])
            dca_on_tail.append(data[on_key]['99% Tail Latency'] - data[on_key]['Average Latency'])
            dca_on_throughput.append(data[on_key]['Storage Throughput'])
        else:
            dca_on_latency.append(0)
            dca_on_tail.append(0)
            dca_on_throughput.append(0)
            
        if off_key in data:
            dca_off_latency.append(data[off_key]['Average Latency'])
            dca_off_tail.append(data[off_key]['99% Tail Latency'] - data[off_key]['Average Latency'])
            dca_off_throughput.append(data[off_key]['Storage Throughput'])
        else:
            dca_off_latency.append(0)
            dca_off_tail.append(0)
            dca_off_throughput.append(0)
    
    # Create figure with dual y-axes
    fig, ax1 = plt.subplots(figsize=(14, 8))
    ax2 = ax1.twinx()
    
    # Set y-axis limits
    ax1.set_ylim(0, 1000)  # Main y-axis (Latency)
    ax2.set_ylim(0, 15)   # Secondary y-axis (Throughput)
    
    # Set positions for bars
    x = np.arange(len(block_sizes))
    width = 0.35
    
    # Plot bars for latency with error bars for tail latency
    bars1 = ax1.bar(x - width/2, dca_off_latency, width, label='DCA OFF Avg Latency', 
                   color='lightcoral', alpha=0.7)
    ax1.errorbar(x - width/2, dca_off_latency, yerr=[np.zeros_like(dca_off_tail), dca_off_tail], 
                fmt='none', ecolor='darkred', capsize=5)
    
    bars2 = ax1.bar(x + width/2, dca_on_latency, width, label='DCA ON Avg Latency', 
                   color='lightblue', alpha=0.7)
    ax1.errorbar(x + width/2, dca_on_latency, yerr=[np.zeros_like(dca_on_tail), dca_on_tail], 
                fmt='none', ecolor='darkblue', capsize=5)
    
    # Create separate data for storage throughput (excluding dpdk_solo positions)
    non_solo_indices = [i for i, bs in enumerate(block_sizes) if bs != 'dpdk_solo']
    x_filtered = [x[i] for i in non_solo_indices]
    dca_off_throughput_filtered = [dca_off_throughput[i] for i in non_solo_indices]
    dca_on_throughput_filtered = [dca_on_throughput[i] for i in non_solo_indices]
    
    # Plot lines for storage throughput (only for non-dpdk_solo points)
    line1 = ax2.plot(x_filtered, dca_off_throughput_filtered, 'r-', linewidth=2, marker='o', 
                    label='DCA OFF Storage Throughput')
    line2 = ax2.plot(x_filtered, dca_on_throughput_filtered, 'b-', linewidth=2, marker='s', 
                    label='DCA ON Storage Throughput')
    
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
    output_path = os.path.join(results_path, 'fig6.png')
    plt.savefig(output_path, dpi=300)
    
    print(f"Figure saved to {output_path}")
    
    # Show plot
    plt.show()

if __name__ == "__main__":
    main()
