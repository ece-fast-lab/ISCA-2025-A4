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
    sections = re.findall(r'==========Monitoring Result \((0x[0-9A-Fa-f]+)\)==========(.*?)(?===========|\Z)', 
                         content, re.DOTALL)
    
    # Print found sections for debugging
    print(f"Found {len(sections)} sections in the results file")
    
    data = {}
    for section in sections:
        config = section[0]
        content = section[1].strip()
        
        # Process each line in the section
        metrics = {}
        for line in content.split('\n'):
            # Skip empty lines
            if not line.strip():
                continue
                
            # Split the line into field name and values
            parts = line.split()
            if len(parts) < 2:
                continue
                
            field_name = parts[0]
            # Extract all numeric values (skip the field name)
            values = [float(val) for val in parts[1:] if re.match(r'^[\d.]+$', val)]
            
            if values:
                metrics[field_name] = np.mean(values)
        
        # Extract required metrics if they exist
        if 'Average_latency' in metrics and '99%_tail_latency' in metrics and 'Average_read_BW' in metrics and 'Average_write_BW' in metrics:
            data[config] = {
                'Average Latency': metrics['Average_latency'],
                '99% Tail Latency': metrics['99%_tail_latency'],
                'Read BW': metrics['Average_read_BW'] / 1000,  # Convert to GB/s
                'Write BW': metrics['Average_write_BW'] / 1000  # Convert to GB/s
            }
        else:
            print(f"Warning: Missing required metrics for {config}")
    
    return data

def main():
    # Get the full path from command line argument
    if len(sys.argv) > 1:
        results_path = sys.argv[1]
    else:
        print("Usage: python gen_fig7.py <full_path_to_results_folder>")
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
    
    # Extract available configuration IDs from data
    available_configs = list(data.keys())
    available_configs.sort(key=lambda x: int(x, 16))
    
    if not available_configs:
        print("Error: No valid configurations found in results file")
        sys.exit(1)
    
    # Use available configurations instead of predefined list
    configs = available_configs
    
    # Extract data for plotting in the defined order
    avg_latencies = [data[config]['Average Latency'] for config in configs]
    tail_latencies = [data[config]['99% Tail Latency'] for config in configs]
    # Calculate yerr for error bars (difference between 99% tail and average)
    error_bars = [tail - avg for tail, avg in zip(tail_latencies, avg_latencies)]
    read_bws = [data[config]['Read BW'] for config in configs]
    write_bws = [data[config]['Write BW'] for config in configs]
    
    # Create figure with dual y-axes
    fig, ax1 = plt.subplots(figsize=(12, 7))
    ax2 = ax1.twinx()
    
    # Set ylim for main y-axis (Latency)
    ax1.set_ylim(0, 800)
    
    # Set ylim for secondary y-axis (Memory Bandwidth)
    ax2.set_ylim(0, 8)
    
    # Set positions for bars
    bar_positions = np.arange(len(configs))
    bar_width = 0.6
    
    # Plot average latency as bars with 99% tail latency as error bars
    # Use yerr with a 2D array to make error bars only go upward
    # First row is all zeros (no downward bars), second row is the error values (upward bars)
    bars = ax1.bar(bar_positions, avg_latencies, bar_width, 
                   yerr=np.vstack([[0]*len(error_bars), error_bars]),
                   alpha=0.7, color='steelblue', capsize=5, 
                   label='Avg Latency (99% Tail as Error Bar)')
    
    # Plot memory bandwidth as lines on secondary y-axis
    line1 = ax2.plot(bar_positions, read_bws, 'r-o', linewidth=2, 
                     label='Read BW', zorder=5)
    line2 = ax2.plot(bar_positions, write_bws, 'g-s', linewidth=2, 
                     label='Write BW', zorder=5)
    
    # Set labels and title
    ax1.set_xlabel('DPDK Way Allocation')
    ax1.set_ylabel('Latency (μs)')
    ax2.set_ylabel('Memory Bandwidth (GB/s)')
    plt.title('Latency and Memory Bandwidth vs. DPDK Way Allocation')
    
    # Set x-ticks
    plt.xticks(bar_positions, configs, rotation=45)
    
    # Create combined legend
    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper right')
    
    # Adjust layout
    plt.tight_layout()
    
    # Save figure in the same folder as the results file
    output_path = os.path.join(results_path, 'fig7.png')
    plt.savefig(output_path, dpi=300)
    
    print(f"Figure saved to {output_path}")
    
    # Show plot
    plt.show()

if __name__ == "__main__":
    main()
