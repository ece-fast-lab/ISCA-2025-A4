import matplotlib.pyplot as plt
import numpy as np
import re
import os
import sys
import glob

def parse_result_file(file_path):
    configurations = ["Shared", "Isolated", "SmartLLC_1", "SmartLLC_2", "SmartLLC_3", "SmartLLC_0"]
    
    # Initialize dictionary to store data
    data = {config: {} for config in configurations}
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Split content by configuration sections
    for config in configurations:
        # Fix the syntax error by separating the string construction
        joined_configs = "|".join(configurations)
        pattern = f"{config}(.*?)(?=(?:{joined_configs})|$)"
        match = re.search(pattern, content, re.DOTALL)
        if not match:
            print(f"Configuration {config} not found in file")
            continue
        
        config_data = match.group(1)
        
        # Function to extract and calculate mean of whitespace-separated values
        def extract_mean(pattern):
            values = []
            for line in config_data.splitlines():
                if re.match(f"^{pattern}", line):
                    # Extract values after the pattern
                    parts = line.split(':', 1) if ':' in line else line.split(pattern, 1)
                    if len(parts) > 1:
                        # Process all numbers on the line
                        nums = [float(x) for x in parts[1].strip().split() if x.strip() and re.match(r'^[\d.]+$', x)]
                        values.extend(nums)
            return np.mean(values) if values else 0
        
        # Extract latency breakdown values - cumulate all values
        latency_read = extract_mean(r'Average_latency_breakdown\(read\)')
        latency_regex = extract_mean(r'Average_latency_breakdown\(regex\)')
        latency_write = extract_mean(r'Average_latency_breakdown\(write\)')
        
        # Extract I/O throughput
        storage_read = extract_mean(r'Storage_Throughput_R')
        storage_write = extract_mean(r'Storage_Throughput_W')
        network_read = extract_mean(r'Network_Throughput_R')
        network_write = extract_mean(r'Network_Throughput_W')
        
        # Extract memory consumption
        mem_read = extract_mean(r'Mem_[rR]ead')
        mem_write = extract_mean(r'Mem_[wW]rite')
        
        # Store data in dictionary
        data[config] = {
            # Latency breakdown - divide by 1000 to convert to ms
            'read_latency': latency_read / 1000,
            'regex_latency': latency_regex / 1000,
            'write_latency': latency_write / 1000,
            
            # I/O throughput
            'storage_read': storage_read,
            'storage_write': storage_write,
            'network_read': network_read,
            'network_write': network_write,
            
            # Memory consumption
            'mem_read': mem_read,
            'mem_write': mem_write
        }
    
    return data

def create_stacked_bar(ax, data, configs, metrics, title, ylabel, colors=None, legend_loc='upper right'):
    """Create a stacked bar chart on the given axis."""
    if not colors:
        colors = plt.cm.tab10.colors
    
    # Width of a bar 
    width = 0.8
    
    # Bottom baseline for stacking
    bottoms = np.zeros(len(configs))
    
    # For legend
    handles = []
    labels = []
    
    # Create stacked bars
    for i, metric in enumerate(metrics):
        values = [data[config].get(metric, 0) for config in configs]
        bars = ax.bar(configs, values, width, bottom=bottoms, label=metric, color=colors[i % len(colors)])
        bottoms += values
        handles.append(bars)
        labels.append(metric.replace('_', ' ').title())
    
    # Set title and labels
    ax.set_title(title)
    ax.set_ylabel(ylabel)
    ax.set_xticks(range(len(configs)))
    ax.set_xticklabels(configs, rotation=45, ha='right')
    
    # Add legend
    ax.legend(loc=legend_loc)
    
    return ax

def main():
    # Check command line arguments
    if len(sys.argv) != 2:
        # Find file in current directory if not provided
        result_files = glob.glob("step_real_result_2048k.txt")
        if not result_files:
            print("Usage: python gen_fig14.py <path_to_step_real_result_2048k.txt or directory>")
            print("Error: step_real_result_2048k.txt not found in current directory")
            sys.exit(1)
        else:
            input_file = result_files[0]
            print(f"Using: {input_file}")
    else:
        input_path = sys.argv[1]
        
        # Check if the path is a directory
        if os.path.isdir(input_path):
            # Look for step_real_result_2048k.txt in the directory
            result_file = os.path.join(input_path, "step_real_result_2048k.txt")
            if os.path.exists(result_file):
                input_file = result_file
                print(f"Using: {input_file}")
            else:
                # Try to find any result file in the directory
                result_files = glob.glob(os.path.join(input_path, "*result*.txt"))
                if result_files:
                    input_file = result_files[0]
                    print(f"Using: {input_file}")
                else:
                    print(f"Error: No result files found in directory: {input_path}")
                    sys.exit(1)
        else:
            # Assume it's a file path
            input_file = input_path
            if not os.path.exists(input_file):
                print(f"Error: File not found: {input_file}")
                sys.exit(1)
    
    output_dir = os.path.dirname(input_file)
    
    # Parse data from file
    data = parse_result_file(input_file)
    
    # Define configuration order
    configs = ["Shared", "Isolated", "SmartLLC_1", "SmartLLC_2", "SmartLLC_3", "SmartLLC_0"]
    
    # Create figure with 3 subplots
    fig, axes = plt.subplots(3, 1, figsize=(10, 18), constrained_layout=True)
    
    # 1. FFSB latency breakdown - all values cumulated
    ffsb_metrics = ['read_latency', 'regex_latency', 'write_latency']
    ffsb_colors = ['#8dd3c7', '#ffffb3', '#bebada']
    create_stacked_bar(
        axes[0], data, configs, ffsb_metrics,
        'FFSB Latency Breakdown', 'Latency (ms)',
        colors=ffsb_colors
    )
    
    # 2. I/O throughput
    io_metrics = ['storage_read', 'storage_write', 'network_read', 'network_write']
    io_colors = ['#66c2a5', '#fc8d62', '#8da0cb', '#e78ac3']
    create_stacked_bar(
        axes[1], data, configs, io_metrics,
        'I/O Throughput', 'Throughput (GB/s)',
        colors=io_colors
    )
    
    # 3. Memory consumption
    mem_metrics = ['mem_read', 'mem_write']
    mem_colors = ['#a6cee3', '#1f78b4']
    create_stacked_bar(
        axes[2], data, configs, mem_metrics,
        'Memory Consumption', 'Bandwidth (GB/s)',
        colors=mem_colors
    )
    
    # Set overall title
    fig.suptitle('Performance Metrics Across Different Configurations', fontsize=16)
    
    # Save figure as fig14.png
    output_path = os.path.join(output_dir, 'fig14.png')
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    
    print(f"Figure saved to {output_path}")
    
    # Show plot
    plt.show()

if __name__ == "__main__":
    main()
