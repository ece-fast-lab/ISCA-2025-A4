#ifndef _MAIN_H_
#define _MAIN_H_

#define RX_RING_SIZE 2048

#define NUM_MBUFS 4095
#define MBUF_CACHE_SIZE 512
#define BURST_SIZE 64

#define MAX_RX_CORES 128


static const struct rte_eth_conf port_conf_default = {
    .rxmode = {
        .mq_mode = RTE_ETH_MQ_RX_RSS,
	    .max_lro_pkt_size = RTE_ETHER_MAX_LEN,
    },
    .rx_adv_conf = {
        .rss_conf = {
            .rss_key = NULL,
            .rss_hf = RTE_ETH_RSS_IP | RTE_ETH_RSS_UDP | RTE_ETH_RSS_TCP,
        }
    },
    .txmode = {
        .mq_mode = RTE_ETH_MQ_TX_NONE
    }
};

struct my_pps { 
    double data[600]; 
}; 
static uint16_t test_pps = 0;
static uint16_t call_main = 1;
volatile struct my_pps pps_arr[MAX_RX_CORES];
static int pps_size = 0;


static struct rte_ether_addr my_ether_addr;
static uint16_t port_id = 0;
static unsigned int interval = 1;
static uint32_t pkts_per_sec = 0;
static uint32_t latency_size = 0;
static unsigned long dummy_delay = 1000;

// used for applications
static int app_id = 0;
static int app_arg1;
static int app_arg2;

static uint64_t last_lcore_rx_pkts[MAX_RX_CORES];
static volatile uint64_t lcore_rx_pkts[MAX_RX_CORES];
static uint64_t last_lcore_tx_pkts[MAX_RX_CORES];
static volatile uint64_t lcore_tx_pkts[MAX_RX_CORES];
// If the program is receiving packets
static volatile int keep_receiving = 1;

// Print usage of the program
static void print_usage(const char *prgname);

// Parse program arguments. Return 0 on success.
static int parse_args(int argc, char **argv);

// Parse argument 'port'. Return 0 on success.
static int parse_port(char *arg);

// Parse argument 'interval'. Return 0 on success.
static int parse_interval(char *arg);

// Parse argument 'latency'. Return 0 on success.
static int parse_latency(char *arg);

// Parse argument 'packet rate'. Return 0 on success.
static int parse_pkt_rate(char *arg);

// Parse argument 'test-pps'. Return 0 on success.
static int parse_test_pps(char *arg);

static int parse_call_main(char *arg);

static int parse_delay(char *arg);

static int parse_app_id(char *arg);
static int parse_app_arg1(char *arg);
static int parse_app_arg2(char *arg);

void delay_nanoseconds(unsigned long microseconds);

// Print the configuration of the program
static void print_config();

// Initialzie a port. Return 0 on success.
//  port: ID of the port to initialize
//  mbuf_pool: packet buffer pool for RX packets
//  nb_tx_rings: number of TX rings
//  nb_rx_rings: number of RX rings
//  tx_ring_size: number of descriptors to allocate for the TX ring
//  rx_ring_size: number of descriptors to allocate for the RX ring
static int port_init(uint16_t port,
                     struct rte_mempool *mbuf_pool,
                     uint16_t nb_tx_rings,
                     uint16_t nb_rx_rings,
                     uint16_t tx_ring_size,
                     uint16_t rx_ring_size);

// Process RX packets in a logical core
static int lcore_rx(void *arg);

// Handle signal and stop receiving packets
static void stop_rx(int sig);

// Print usage of the program
static void print_usage(const char *prgname)
{
    printf("%s [EAL options] -- [-p PORT]\n"
           "    -p, --port=<PORT>           port to receive packets (default %hu)\n"
           "    -i, --interval=<INTERVAL>   seconds between periodic reports, only appliable when call_main is disabled (default %u)\n"
           "    -l, --latency=<LATENCY>     test latency, it will store an array of latency stats (default array size is %u)\n"
           "    -r, --packet-rate=<RATE>    maximum number of packets to receive per second (no rate limiting by default)\n"
           "    -t, --test-pps              whether record pps, enable=1, disable=0 (default disable)\n"
           "    -m, --call-main             whether call main thread, enable=1, disable=0 (default enable)\n"
           "    -d, --delay=<DUMMY DELAY>   add dummy delay after touching the payload (default %lu nanoseconds)\n"
           "    -a, --app-id                application id, enable=1, disable=0 (default 0, add dummy delay)\n"
           "    -b, --app-arg1              first application argument\n"
           "    -c, --app-arg2              second application argument\n"
           "    -h, --help                  print usage of the program\n",
           prgname, port_id, interval, latency_size, dummy_delay);
}

static struct option long_options[] = {
    {"port",        required_argument,  0,  'p'},
    {"interval",    required_argument,  0,  'i'},
    {"latency",     required_argument,  0,  'l'},
    {"rate",        required_argument,  0,  'r'},
    {"test-pps",    required_argument,  0,  't'},
    {"call-main",   required_argument,  0,  'm'},
    {"delay",       required_argument,  0,  'd'},
    {"app-id",      required_argument,  0,  'a'},
    {"app-arg1",    required_argument,  0,  'b'},
    {"app-arg2",    required_argument,  0,  'c'},
    {"help",        no_argument,        0,  'h'},
    {0,             0,                  0,  0 }
};

// Parse the argument given in the command line of the application
static int parse_args(int argc, char **argv)
{
    char *prgname = argv[0];
    const char short_options[] = "p:i:l:r:t:m:d:a:b:c:h";
    int c;
    int ret;

    while ((c = getopt_long(argc, argv, short_options, long_options, NULL)) != EOF) {
        switch (c) {
            case 'p':
                ret = parse_port(optarg);
                if (ret < 0) {
                    printf("Failed to parse port\n");
                    return -1;
                }
                break;

            case 'i':
                ret = parse_interval(optarg);
                if (ret < 0) {
                    printf("Failed to parse interval\n");
                    return -1;
                }
                break;

            case 'l':
                ret = parse_latency(optarg);
                if (ret < 0) {
                    return -1;
                }
                break;

            case 'r':
                ret = parse_pkt_rate(optarg);
                if (ret < 0) {
                    printf("Failed to parse pkt rate\n");
                    return -1;
                }
                break;

            case 't':
                ret = parse_test_pps(optarg);
                if (ret < 0) {
                    printf("Failed to parse test pps option\n");
                    return -1;
                }
                break;

            case 'm':
                ret = parse_call_main(optarg);
                if (ret < 0) {
                    printf("Failed to parse call main option\n");
                    return -1;
                }
                break;

            case 'd':
                ret = parse_delay(optarg);
                if (ret < 0) {
                    printf("Failed to parse dummy delay\n");
                    return -1;
                }
                break;

            case 'a':
                ret = parse_app_id(optarg);
                if (ret < 0) {
                    printf("Failed to parse pkt rate\n");
                    return -1;
                }
                break;
            
            case 'b':
                ret = parse_app_arg1(optarg);
                if (ret < 0) {
                    printf("Failed to parse pkt rate\n");
                    return -1;
                }
                break;

            case 'c':
                ret = parse_app_arg2(optarg);
                if (ret < 0) {
                    printf("Failed to parse pkt rate\n");
                    return -1;
                }
                break;
            
            case 'h':
            default:
                printf("Why go to help???\n");
                print_usage(prgname);
                return -1;
        }
    }

    if (optind >= 0) {
        argv[optind-1] = prgname;
    }

    // reset getopt lib
    optind = 1;

	return 0;
}

// Parse argument 'port'
static int parse_port(char *arg)
{
    long n;
    char **endptr;

    n = strtol(optarg, endptr, 10);
    if (n < 0) {
        fprintf(stderr, "PORT should be a non-negative integer argument\n");
        return -1;
    }

    port_id = (uint16_t)n;
    uint16_t nb_ports = rte_eth_dev_count_avail();
    if (port_id >= nb_ports) {
        fprintf(stderr, "PORT should be smaller than %hu (# of available ports)\n", nb_ports);
        return -1;
    }

    return 0;
}

// Parse argument 'interval'
static int parse_interval(char *arg)
{
    unsigned int n;
    char **endptr;

    n = strtoul(optarg, endptr, 10);
    if (n == 0) {
        fprintf(stderr, "INTERVAL should be a positive integer argument\n");
        return -1;
    }

    interval = n;
    return 0;
}

// Parse argument 'latency'. Return 0 on success.
static int parse_latency(char *arg)
{
    uint32_t n;
    char **endptr;

    n = (uint32_t)strtoul(arg, endptr, 10);
    latency_size = n;
    return 0;
}

// Parse argument 'packet rate'. Return 0 on success.
static int parse_pkt_rate(char *arg)
{
    uint32_t n;
    char **endptr;

    n = (uint32_t)strtoul(arg, endptr, 10);
    if (n == 0) {
        fprintf(stderr, "PKT_RATE should be a positive integer argument\n");
        return -1;
    }

    pkts_per_sec = n;
    return 0;
}

// Parse argument 'test-pps'. Return 0 on success.
static int parse_test_pps(char *arg)
{
    uint32_t n;
    char **endptr;

    n = (uint32_t)strtoul(arg, endptr, 10);
    test_pps = n;
    return 0;
}

// Parse argument 'delay'. Return 0 on success.
static int parse_delay(char *arg)
{
    uint32_t n;
    char **endptr;

    n = (unsigned long)strtoul(arg, endptr, 10);
    dummy_delay = n;
    return 0;
}


// Parse argument 'call-main'. Return 0 on success.
static int parse_call_main(char *arg)
{
    uint32_t n;
    char **endptr;

    n = (uint32_t)strtoul(arg, endptr, 10);
    call_main = n;
    return 0;
}


// Parse argument 'app id'. Return 0 on success.
static int parse_app_id(char *arg)
{
    uint32_t n;
    char **endptr;

    n = (uint32_t)strtoul(arg, endptr, 10);
    if (n == 0) {
        fprintf(stderr, "PKT_RATE should be a positive integer argument\n");
        return -1;
    }

    app_id = n;
    return 0;
}

// Parse argument 'app arg 1'. Return 0 on success.
static int parse_app_arg1(char *arg)
{
    uint32_t n;
    char **endptr;

    n = (uint32_t)strtoul(arg, endptr, 10);
    if (n == 0) {
        fprintf(stderr, "PKT_RATE should be a positive integer argument\n");
        return -1;
    }

    app_arg1 = n;
    return 0;
}

// Parse argument 'app arg 2'. Return 0 on success.
static int parse_app_arg2(char *arg)
{
    uint32_t n;
    char **endptr;

    n = (uint32_t)strtoul(arg, endptr, 10);
    if (n == 0) {
        fprintf(stderr, "PKT_RATE should be a positive integer argument\n");
        return -1;
    }

    app_arg2 = n;
    return 0;
}

// Print the configuration of the program
static void print_config()
{
    printf("================ Configuration ================\n");
    printf("Port:           %u\n", port_id);
    printf("Interval:       %u sec\n", interval);
    printf("Packet Rate:    ");
    if (pkts_per_sec == 0) {
        printf("N/A (no rate limiting)\n");
    } else {
        printf("%u\n", pkts_per_sec);
    }
    printf("===============================================\n");
}

// Initialzie a port. Return 0 on success.
//  port: ID of the port to initialize
//  mbuf_pool: packet buffer pool for RX packets
//  nb_tx_rings: number of TX rings
//  nb_rx_rings: number of RX rings
//  tx_ring_size: number of transmission descriptors to allocate for the TX ring
//  rx_ring_size: number of transmission descriptors to allocate for the RX ring
static int port_init(uint16_t port,
                     struct rte_mempool *mbuf_pool,
                     uint16_t nb_tx_rings,
                     uint16_t nb_rx_rings,
                     uint16_t tx_ring_size,
                     uint16_t rx_ring_size)
{
    struct rte_eth_conf port_conf = port_conf_default;
    uint16_t nb_txd = tx_ring_size;
    uint16_t nb_rxd = rx_ring_size;
    int retval;
    struct rte_eth_dev_info dev_info;

    printf("Init port %hu\n", port);

    if (!rte_eth_dev_is_valid_port(port)) {
        printf("DEBUG: No valid port %hu\n", port);
        //printf("DEBUG: port state is: %hu\n", rte_eth_dev[port_id].state);
		return -1;
    }

    // Get device information
    retval = rte_eth_dev_info_get(port, &dev_info);
    if (retval != 0) {
        fprintf(stderr, "Error during getting device (port %u) info: %s\n", port, strerror(-retval));
        return retval;
    }
    printf("PCI address: %s\n", dev_info.device->name);

    // Configure RSS
    port_conf.rx_adv_conf.rss_conf.rss_hf &= dev_info.flow_type_rss_offloads;
    if (port_conf.rx_adv_conf.rss_conf.rss_hf !=
        port_conf_default.rx_adv_conf.rss_conf.rss_hf) {
            printf("Port %u modifies RSS hash function based on hardware support,"
                   "requested:%#"PRIx64" configured:%#"PRIx64"\n",
                   port,
                   port_conf_default.rx_adv_conf.rss_conf.rss_hf,
                   port_conf.rx_adv_conf.rss_conf.rss_hf);
    }

    // Configure the Ethernet device
    retval = rte_eth_dev_configure(port, nb_rx_rings, nb_tx_rings, &port_conf);
    if (retval != 0) {
        fprintf(stderr, "Error during rte_eth_dev_configure\n");
        return retval;
    }

    // Adjust # of descriptors for each TX/RX ring
    printf("Ring size before adjustion RX-%hu, TX-%hu", nb_rxd, nb_txd);
    retval = rte_eth_dev_adjust_nb_rx_tx_desc(port, &nb_rxd, &nb_txd);
    if (retval != 0) {
        fprintf(stderr, "Error during rte_eth_dev_adjust_nb_rx_tx_desc\n");
        return retval;
    }
    printf("Ring size after adjudtion: set to RX-%hu, TX-%hu", nb_rxd, nb_txd);

    int socket_id = rte_eth_dev_socket_id(port);
    //printf("Socket ID = %d\n", socket_id);

    // TX setup
    for (uint16_t q = 0; q < nb_tx_rings; q++) {
        retval = rte_eth_tx_queue_setup(port, q, nb_txd, socket_id, NULL);
        if (retval < 0) {
            fprintf(stderr, "Error during rte_eth_tx_queue_setup for queue %hu\n", q);
			return retval;
        }
    }
    printf("Set up %hu TX rings (%hu descriptors per ring)\n", nb_tx_rings, nb_txd);

    // RX setup
    for (uint16_t q = 0; q < nb_rx_rings; q++) {
        retval = rte_eth_rx_queue_setup(port, q, nb_rxd, socket_id, NULL, mbuf_pool);
        if (retval < 0) {
            fprintf(stderr, "Error during rte_eth_rx_queue_setup for queue %hu\n", q);
            return retval;
        }
    }
    printf("Set up %hu RX rings (%hu descriptors per ring)\n", nb_rx_rings, nb_rxd);

    // Start the Ethernet port.
    retval = rte_eth_dev_start(port);
    if (retval < 0) {
        fprintf(stderr, "Error during rte_eth_dev_start\n");
        return retval;
    }

    // Display the port MAC address
    struct rte_ether_addr addr;
    retval = rte_eth_macaddr_get(port, &addr);
    if (retval != 0) {
        fprintf(stderr, "Error during rte_eth_macaddr_get\n");
        return retval;
    }
    printf("Port %hu MAC: %02" PRIx8 " %02" PRIx8 " %02" PRIx8
           " %02" PRIx8 " %02" PRIx8 " %02" PRIx8 "\n",
           port, addr.addr_bytes[0], addr.addr_bytes[1], addr.addr_bytes[2],
           addr.addr_bytes[3], addr.addr_bytes[4], addr.addr_bytes[5]);
    
    my_ether_addr = addr;

	// Enable RX in promiscuous mode for the Ethernet device.
    // retval = rte_eth_promiscuous_enable(port);
    // if (retval != 0) {
    //     fprintf(stderr, "Error during rte_eth_promiscuous_enable\n");
    //     return retval;
    // }

	return 0;
}

// Handle signal and stop receiving packets
static void stop_rx(int sig)
{
    keep_receiving = 0;
}


// dummy timer
void delay_nanoseconds(unsigned long nanoseconds) {
    struct timespec start, end;
    long elapsed_nanoseconds;

    clock_gettime(CLOCK_MONOTONIC, &start);
    do {
        clock_gettime(CLOCK_MONOTONIC, &end);
        elapsed_nanoseconds = (end.tv_sec - start.tv_sec) * 1000000000L + (end.tv_nsec - start.tv_nsec);
    } while (elapsed_nanoseconds < nanoseconds);
}

#endif /* _MAIN_H_ */
