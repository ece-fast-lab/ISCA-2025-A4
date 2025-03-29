import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
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
    
    # Split into configuration sections
    config_sections = re.split(r'(Shared|Isolated|SmartLLC_\d)', content)
    
    current_config = None
    for i in range(1, len(config_sections), 2):
        config_name = config_sections[i]
        config_data = config_sections[i+1]
        
        if config_name == "SmartLLC":
            # Handle SmartLLC with numbers
            match = re.search(r'SmartLLC_(\d)', config_data)
            if match:
                config_name = f"SmartLLC_{match.group(1)}"
            else:
                continue
        
        # Improved parsing to handle whitespace-separated values correctly
        
        # Function to extract and calculate mean of whitespace-separated values
        def extract_mean(pattern):
            # Add ^ to ensure pattern matches at beginning of line
            match = re.search(r'^' + pattern + r':\s+([\d.\s]+)$', config_data, re.MULTILINE)
            if match:
                values_str = match.group(1).strip()
                values = [float(x) for x in values_str.split() if x]
                return np.mean(values) if values else 0
            return 0
        
        # Average latency for fastclick
        fastclick_avg_latency = extract_mean(r'Average_e2e_latency')
        
        # Average latency breakdown for ffsb
        avg_latency_read = extract_mean(r'Average_latency_breakdown\(read\)')
        avg_latency_regex = extract_mean(r'Average_latency_breakdown\(regex\)')
        avg_latency_write = extract_mean(r'Average_latency_breakdown\(write\)')
        ffsb_avg_latency_sum = avg_latency_read + avg_latency_regex + avg_latency_write
        
        # IPC values for each benchmark
        fastclick_ipc = extract_mean(r'fastclick_IPC')
        ffsb_ipc = extract_mean(r'ffsb_IPC')
        redis_server_ipc = extract_mean(r'Redis-server_IPC')
        redis_ipc = extract_mean(r'Redis_IPC')
        x264_ipc = extract_mean(r'x264_r_IPC')
        parest_ipc = extract_mean(r'parest_r_IPC')
        xalancbmk_ipc = extract_mean(r'xalancbmk_r_IPC')
        lbm_ipc = extract_mean(r'lbm_r_IPC')
        omnetpp_ipc = extract_mean(r'omnetpp_r_IPC')
        exchange2_ipc = extract_mean(r'exchange2_r_IPC')
        bwaves_ipc = extract_mean(r'bwaves_r_IPC')
        
        # L3 hit rates - directly parsed from separate metrics in results file
        l3_hit_rate = extract_mean(r'L3_Hit_Rate\(%\)')  # Overall L3 hit rate (not a sum of LSW and BEW)
        LSW_L3_Hit_Rate = extract_mean(r'LSW_L3_Hit_Rate\(%\)')  # LSW (high-priority) workloads hit rate
        BEW_L3_Hit_Rate = extract_mean(r'BEW_L3_Hit_Rate\(%\)')  # BEW (low-priority) workloads hit rate
        fastclick_l3_hit = extract_mean(r'fastclick_L3_Hit_Rate\(%\)')
        ffsb_l3_hit = extract_mean(r'ffsb_L3_Hit_Rate\(%\)')
        redis_server_l3_hit = extract_mean(r'Redis-server_L3_Hit_Rate\(%\)')
        redis_l3_hit = extract_mean(r'Redis_L3_Hit_Rate\(%\)')
        x264_l3_hit = extract_mean(r'x264_r_L3_Hit_Rate\(%\)')
        parest_l3_hit = extract_mean(r'parest_r_L3_Hit_Rate\(%\)')
        xalancbmk_l3_hit = extract_mean(r'xalancbmk_r_L3_Hit_Rate\(%\)')
        lbm_l3_hit = extract_mean(r'lbm_r_L3_Hit_Rate\(%\)')
        omnetpp_l3_hit = extract_mean(r'omnetpp_r_L3_Hit_Rate\(%\)')
        exchange2_l3_hit = extract_mean(r'exchange2_r_L3_Hit_Rate\(%\)')
        bwaves_l3_hit = extract_mean(r'bwaves_r_L3_Hit_Rate\(%\)')
        
        data[config_name] = {
            'fastclick_avg_latency': fastclick_avg_latency,
            'ffsb_avg_latency_sum': ffsb_avg_latency_sum,
            'fastclick_ipc': fastclick_ipc,
            'ffsb_ipc': ffsb_ipc,
            'redis_server_ipc': redis_server_ipc,
            'redis_ipc': redis_ipc,
            'x264_ipc': x264_ipc,
            'parest_ipc': parest_ipc,
            'xalancbmk_ipc': xalancbmk_ipc,
            'lbm_ipc': lbm_ipc,
            'omnetpp_ipc': omnetpp_ipc,
            'exchange2_ipc': exchange2_ipc,
            'bwaves_ipc': bwaves_ipc,
            'l3_hit_rate': l3_hit_rate,  # Overall L3 hit rate for 'Total' summary
            'LSW_L3_Hit_Rate': LSW_L3_Hit_Rate,  # For 'HPWs' summary
            'BEW_L3_Hit_Rate': BEW_L3_Hit_Rate,  # For 'LPWs' summary
            'fastclick_l3_hit': fastclick_l3_hit,
            'ffsb_l3_hit': ffsb_l3_hit,
            'redis_server_l3_hit': redis_server_l3_hit,
            'redis_l3_hit': redis_l3_hit,
            'x264_l3_hit': x264_l3_hit,
            'parest_l3_hit': parest_l3_hit,
            'xalancbmk_l3_hit': xalancbmk_l3_hit,
            'lbm_l3_hit': lbm_l3_hit,
            'omnetpp_l3_hit': omnetpp_l3_hit,
            'exchange2_l3_hit': exchange2_l3_hit,
            'bwaves_l3_hit': bwaves_l3_hit
        }
        
        # Print some debug info
        print(f"Config: {config_name}")
        print(f"  fastclick_avg_latency: {fastclick_avg_latency}")
        print(f"  fastclick_ipc: {fastclick_ipc}")
        print(f"  ffsb_avg_latency_sum: {ffsb_avg_latency_sum}")
        print(f"  L3_hit_rate (Total): {l3_hit_rate}")
        print(f"  LSW_L3_Hit_Rate (HPWs): {LSW_L3_Hit_Rate}")
        print(f"  BEW_L3_Hit_Rate (LPWs): {BEW_L3_Hit_Rate}")
    
    return data

def calculate_relative_performance(data):
    # Initialize dictionaries for results
    relative_perf = {config: {} for config in data.keys()}
    
    # Calculate relative performance for each benchmark
    for config in data.keys():
        # For fastclick, use reciprocal of average latency
        relative_perf[config]['fastclick'] = data['Shared']['fastclick_avg_latency'] / data[config]['fastclick_avg_latency']
        
        # For ffsb, use reciprocal of sum of average latency breakdown
        relative_perf[config]['ffsb'] = data['Shared']['ffsb_avg_latency_sum'] / data[config]['ffsb_avg_latency_sum']
        
        # For others, use IPC
        relative_perf[config]['redis_server'] = data[config]['redis_server_ipc'] / data['Shared']['redis_server_ipc']
        relative_perf[config]['redis'] = data[config]['redis_ipc'] / data['Shared']['redis_ipc']
        relative_perf[config]['x264'] = data[config]['x264_ipc'] / data['Shared']['x264_ipc']
        relative_perf[config]['parest'] = data[config]['parest_ipc'] / data['Shared']['parest_ipc']
        relative_perf[config]['xalancbmk'] = data[config]['xalancbmk_ipc'] / data['Shared']['xalancbmk_ipc']
        relative_perf[config]['lbm'] = data[config]['lbm_ipc'] / data['Shared']['lbm_ipc']
        relative_perf[config]['omnetpp'] = data[config]['omnetpp_ipc'] / data['Shared']['omnetpp_ipc']
        relative_perf[config]['exchange2'] = data[config]['exchange2_ipc'] / data['Shared']['exchange2_ipc']
        relative_perf[config]['bwaves'] = data[config]['bwaves_ipc'] / data['Shared']['bwaves_ipc']
        
        # Calculate weighted averages for HPWs
        hpw_weights = {'fastclick': 4, 'redis_server': 1, 'redis': 1, 'x264': 1, 'parest': 1, 'xalancbmk': 1, 'lbm': 1}
        total_hpw_weight = sum(hpw_weights.values())
        
        hpw_weighted_sum = (
            hpw_weights['fastclick'] * relative_perf[config]['fastclick'] +
            hpw_weights['redis_server'] * relative_perf[config]['redis_server'] +
            hpw_weights['redis'] * relative_perf[config]['redis'] +
            hpw_weights['x264'] * relative_perf[config]['x264'] +
            hpw_weights['parest'] * relative_perf[config]['parest'] +
            hpw_weights['xalancbmk'] * relative_perf[config]['xalancbmk'] +
            hpw_weights['lbm'] * relative_perf[config]['lbm']
        )
        
        relative_perf[config]['HPWs'] = hpw_weighted_sum / total_hpw_weight
        
        # Calculate weighted averages for LPWs
        lpw_weights = {'ffsb': 4, 'omnetpp': 1, 'exchange2': 1, 'bwaves': 1}
        total_lpw_weight = sum(lpw_weights.values())
        
        lpw_weighted_sum = (
            lpw_weights['ffsb'] * relative_perf[config]['ffsb'] +
            lpw_weights['omnetpp'] * relative_perf[config]['omnetpp'] +
            lpw_weights['exchange2'] * relative_perf[config]['exchange2'] +
            lpw_weights['bwaves'] * relative_perf[config]['bwaves']
        )
        
        relative_perf[config]['LPWs'] = lpw_weighted_sum / total_lpw_weight
        
        # Calculate total weighted average
        all_weights = {**hpw_weights, **lpw_weights}
        total_weight = sum(all_weights.values())
        
        all_weighted_sum = hpw_weighted_sum + lpw_weighted_sum
        
        relative_perf[config]['Total'] = all_weighted_sum / total_weight
    
    return relative_perf

def plot_figure(data, relative_perf, output_dir):
    # Define configurations and benchmarks - change order to the requested one
    configs = ["Shared", "Isolated", "SmartLLC_1", "SmartLLC_2", "SmartLLC_3", "SmartLLC_0"]
    benchmarks = ['fastclick', 'redis_server', 'redis', 'x264', 'parest', 'xalancbmk', 'lbm', 
                'ffsb', 'omnetpp', 'exchange2', 'bwaves', 'HPWs', 'LPWs', 'Total']
    
    # Benchmark groups
    hpws = ['fastclick', 'redis_server', 'redis', 'x264', 'parest', 'xalancbmk', 'lbm']
    lpws = ['ffsb', 'omnetpp', 'exchange2', 'bwaves']
    special = ['HPWs', 'LPWs', 'Total']
    
    # Set up the figure and axes
    fig, ax1 = plt.subplots(figsize=(15, 8))
    ax2 = ax1.twinx()
    
    # Set positions for bars
    bar_width = 0.12
    index = np.arange(len(benchmarks))
    
    # Colors for different configurations
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b']
    
    # Plot bars for relative performance
    for i, config in enumerate(configs):
        performance_values = [relative_perf[config][bench] for bench in benchmarks]
        ax1.bar(index + i * bar_width, performance_values, bar_width, label=config, color=colors[i], alpha=0.8)
    
    # Plot LLC hit rate for each benchmark separately to avoid connecting lines between benchmarks
    for b_idx, bench in enumerate(benchmarks):
        # Get hit rate attribute name for this benchmark based on group
        if bench == 'HPWs':
            hit_rate_attr = 'LSW_L3_Hit_Rate'
        elif bench == 'LPWs':
            hit_rate_attr = 'BEW_L3_Hit_Rate'
        elif bench == 'Total':
            hit_rate_attr = 'l3_hit_rate'
        else:
            hit_rate_attr = f'{bench}_l3_hit'
        
        # Create data points for this benchmark only
        x_positions_bench = []
        llc_hit_rates_bench = []
        
        # Add hit rate for each configuration in specified order
        for c_idx, config in enumerate(configs):
            x_positions_bench.append(index[b_idx] + c_idx * bar_width)
            llc_hit_rates_bench.append(data[config][hit_rate_attr])
        
        # Plot a separate line for each benchmark
        label = "LLC Hit Rate" if b_idx == 0 else None  # Only add label for first benchmark
        ax2.plot(x_positions_bench, llc_hit_rates_bench, 'r-', linewidth=1.5, marker='o', 
                markersize=4, label=label)
    
    # Add vertical lines to separate benchmark groups
    ax1.axvline(x=len(hpws) - 0.5, color='black', linestyle='--', alpha=0.5)
    ax1.axvline(x=len(hpws) + len(lpws) - 0.5, color='black', linestyle='--', alpha=0.5)
    
    # Set labels, title and legend
    ax1.set_xlabel('Benchmarks')
    ax1.set_ylabel('Relative Performance (normalized to Shared)')
    ax2.set_ylabel('LLC Hit Rate (%)')
    plt.title('Fig 13a: Relative Performance and LLC Hit Rate Across Configurations')
    
    ax1.set_xticks(index + (len(configs) / 2 - 0.5) * bar_width)
    ax1.set_xticklabels(benchmarks, rotation=45, ha='right')
    
    # Add benchmark group labels
    ax1.text((len(hpws) / 2) - 0.5, -0.15, 'HPWs', transform=ax1.transData, ha='center', fontsize=12)
    ax1.text(len(hpws) + (len(lpws) / 2) - 0.5, -0.15, 'LPWs', transform=ax1.transData, ha='center', fontsize=12)
    ax1.text(len(hpws) + len(lpws) + (len(special) / 2) - 0.5, -0.15, 'Summary', transform=ax1.transData, ha='center', fontsize=12)
    
    # Combine legends
    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    
    # Set legend
    ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper center', bbox_to_anchor=(0.5, -0.2), 
              fancybox=True, shadow=True, ncol=len(configs))
    
    # Set y-axis limits
    ax1.set_ylim(0, 2.0)  # Adjust as needed
    ax2.set_ylim(0, 100)  # LLC hit rate percentage
    
    # Adjust layout
    plt.tight_layout()
    plt.subplots_adjust(bottom=0.25)
    
    # Save figure to the specified output directory
    output_path = os.path.join(output_dir, 'fig13a.png')
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"Figure saved to {output_path}")
    
    plt.show()

def main():
    # Check if a folder path was provided
    if len(sys.argv) > 1:
        folder_path = sys.argv[1]
    else:
        print("Usage: python gen_fig13a.py <folder_path>")
        sys.exit(1)
    
    # Make sure the path exists
    if not os.path.isdir(folder_path):
        print(f"Error: Directory {folder_path} does not exist.")
        sys.exit(1)
    
    # Find result files in the directory
    result_files = glob.glob(os.path.join(folder_path, "*result*.txt"))
    
    if not result_files:
        print(f"Error: No result files found in {folder_path}")
        sys.exit(1)
    
    # Use the first result file found
    file_path = result_files[0]
    print(f"Using result file: {file_path}")
    
    # Parse the data
    data = parse_result_file(file_path)
    
    # Calculate relative performance
    relative_perf = calculate_relative_performance(data)
    
    # Plot the figure and save to the same directory
    plot_figure(data, relative_perf, folder_path)

if __name__ == "__main__":
    main()
