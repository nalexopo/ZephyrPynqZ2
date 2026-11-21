#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

#include <zephyr/kernel.h>
#include <zephyr/net/socket.h>
#include <zephyr/posix/arpa/inet.h>

#include <zephyr/net/net_if.h>
#include <zephyr/net/phy.h>

#define BIND_PORT 4242



int main(void)
{
	int serv;
	struct sockaddr_in bind_addr;
	printf("Booting Echo Server application...\n");
	
	// 1. Wipe and configure the IPv4 socket address structure cleanly
    memset(&bind_addr, 0, sizeof(bind_addr));
    bind_addr.sin_family = AF_INET;
    bind_addr.sin_port = htons(4242);            // Your Echo Server Port
    bind_addr.sin_addr.s_addr = htonl(INADDR_ANY); // <-- FIX: Changes fr
	
	// Explicitly target the IP address configured in your prj.conf
	// if (inet_pton(AF_INET, "192.168.1.98", &bind_addr.sin_addr) <= 0) {
	// 	printf("error: invalid address configuration\n");
	// 	exit(1);
	// }

	// 2. Open the UDP Socket (SOCK_DGRAM)
	serv = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (serv < 0) {
		printf("error: socket: %d\n", errno);
		exit(1);
	}


	// 3. Bind the socket directly
	if (bind(serv, (struct sockaddr *)&bind_addr, sizeof(bind_addr)) < 0) {
		printf("error: bind: %d\n", errno);
		exit(1);
	}

	printf("Proceed\n");

	// 4. Processing Loop
	while (1) {
		char buf[128];
		struct sockaddr_in client_addr;
		socklen_t client_len = sizeof(client_addr);
		printk(".");
		int len = recvfrom(serv, buf, sizeof(buf) - 1, 0,
				   (struct sockaddr *)&client_addr, &client_len);
		if (len > 0) {
			buf[len] = '\0'; // Safe null-termination
			printf("Received UDP packet: %s\n", buf);
			
			// Send it right back to the client
			sendto(serv, buf, len, 0, (struct sockaddr *)&client_addr, client_len);
		}
		k_msleep(10);
	}

	return 0;
}