import matplotlib.pyplot as plt
import numpy as np
import os
import re
import sys

def parse_results(filepath):
    with open(filepath, 'r') as f:
        content = f.read().splitlines()
    
    # Lists to store data
    dca_on_data = {}
    dca_off_data = {}
    
    # Block sizes
    block_sizes = ['4k', '8k', '16k', '32k', '64k', '128k', '256k', '512k', '1024k', '2048k']
    
    # First half is DCA ON, second half is DCA OFF
    halfway = len(block_sizes)
    
    # Parse DCA ON data
    for i, size in enumerate(block_sizes):
        # Find the corresponding lines in the file
        read_line = content[i*3]
        write_line = content[i*3 + 1]
        io_line = content[i*3 + 2]
        
        # Extract values
        read_values = re.findall(r'[\d.]+', read_line)
        write_values = re.findall(r'[\d.]+', write_line)
        io_values = re.findall(r'[\d.]+', io_line)
        
        dca_on_data[size] = {
            'read_bw': float(read_values[1]),
            'write_bw': float(write_values[1]),
            'io_read': float(io_values[1])
        }
    
    # Parse DCA OFF data
    for i, size in enumerate(block_sizes):
        # Find the corresponding lines in the file
        read_line = content[(i+halfway)*3]
        write_line = content[(i+halfway)*3 + 1]
        io_line = content[(i+halfway)*3 + 2]
        
        # Extract values
        read_values = re.findall(r'[\d.]+', read_line)
        write_values = re.findall(r'[\d.]+', write_line)
        io_values = re.findall(r'[\d.]+', io_line)
        
        dca_off_data[size] = {
            'read_bw': float(read_values[2]),  # Second column for DCA OFF
            'write_bw': float(write_values[2]),
            'io_read': float(io_values[2])
        }
    
    return block_sizes, dca_on_data, dca_off_data

def main():
    # Get the full path from command line argument
    if len(sys.argv) > 1:
        results_path = sys.argv[1]
    else:
        print("Usage: python gen_fig5.py <full_path_to_results_folder>")
        sys.exit(1)
    
    # Validate the path and construct the results.txt path
    if not os.path.isdir(results_path):
        results_path = os.path.dirname(results_path)
    
    results_file = os.path.join(results_path, 'results.txt')
    if not os.path.exists(results_file):
        print(f"Error: Results file not found at {results_file}")
        sys.exit(1)
    
    # Parse data
    block_sizes, dca_on_data, dca_off_data = parse_results(results_file)
    
    # Extract data for plotting
    dca_on_read_bw = [dca_on_data[size]['read_bw'] for size in block_sizes]
    dca_on_write_bw = [dca_on_data[size]['write_bw'] for size in block_sizes]
    dca_on_io_read = [dca_on_data[size]['io_read'] for size in block_sizes]
    
    dca_off_read_bw = [dca_off_data[size]['read_bw'] for size in block_sizes]
    dca_off_write_bw = [dca_off_data[size]['write_bw'] for size in block_sizes]
    dca_off_io_read = [dca_off_data[size]['io_read'] for size in block_sizes]
    
    # Create figure
    fig, ax = plt.subplots(figsize=(12, 8))
    
    # Set positions for bars and x-ticks
    bar_width = 0.35
    index = np.arange(len(block_sizes))
    
    # Plot bars for storage I/O
    dca_on_io_bars = ax.bar(index - bar_width/2, dca_on_io_read, bar_width, 
                            alpha=0.6, color='lightblue', label='Storage I/O (DCA ON)')
    dca_off_io_bars = ax.bar(index + bar_width/2, dca_off_io_read, bar_width, 
                             alpha=0.6, color='lightcoral', label='Storage I/O (DCA OFF)')
    
    # Plot lines for memory BW
    ax.plot(index, dca_on_read_bw, 'b-', marker='o', linewidth=2, 
            label='Memory Read BW (DCA ON)', zorder=5)
    ax.plot(index, dca_on_write_bw, 'g-', marker='s', linewidth=2, 
            label='Memory Write BW (DCA ON)', zorder=5)
    ax.plot(index, dca_off_read_bw, 'r-', marker='^', linewidth=2, 
            label='Memory Read BW (DCA OFF)', zorder=5)
    ax.plot(index, dca_off_write_bw, 'c-', marker='d', linewidth=2, 
            label='Memory Write BW (DCA OFF)', zorder=5)
    
    # Add labels and title
    ax.set_xlabel('Block Size')
    ax.set_ylabel('Bandwidth (MB/s)')
    ax.set_title('Memory and Storage I/O Bandwidth vs. Block Size')
    
    # Set x-ticks
    ax.set_xticks(index)
    ax.set_xticklabels(block_sizes, rotation=45)
    
    # Set y-axis limit to show the data clearly
    ax.set_ylim(0, 14000)
    
    # Add legend
    ax.legend(loc='lower right')
    
    # Adjust layout
    plt.tight_layout()
    
    # Save figure in the same folder as the results file
    output_path = os.path.join(results_path, 'fig5.png')
    plt.savefig(output_path, dpi=300)
    
    print(f"Figure saved to {output_path}")
    
    # Show plot
    plt.show()

if __name__ == "__main__":
    main()
