import strings
import strconv
import os { input }
import term

fn usage() {
	println("Usage : ./subnet_calc [IP_ADDR/MASK]")
	exit(1)
}

fn banner() {
	println('
███████╗██╗   ██╗██████╗ ███╗   ██╗███████╗████████╗     ██████╗ █████╗ ██╗      ██████╗
██╔════╝██║   ██║██╔══██╗████╗  ██║██╔════╝╚══██╔══╝    ██╔════╝██╔══██╗██║     ██╔════╝
███████╗██║   ██║██████╔╝██╔██╗ ██║█████╗     ██║       ██║     ███████║██║     ██║     
╚════██║██║   ██║██╔══██╗██║╚██╗██║██╔══╝     ██║       ██║     ██╔══██║██║     ██║     
███████║╚██████╔╝██████╔╝██║ ╚████║███████╗   ██║       ╚██████╗██║  ██║███████╗╚██████╗
╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝        ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝')
println('${term.highlight_command('Type "exit" to quit.')}')
}

fn check_ip(cidr string) bool {
	if cidr.split('/').len != 2 {
		return false
	}else if cidr.split('/')[1].int() > 30{
		println("Invalid mask.")
		return false
	}
	byte_arr := cidr.split('/')[0].split('.')
	if byte_arr.len != 4 {
		return false
	}
	for b in byte_arr {
		if b.int() < 0 || b.int() > 256{
			return false
		}
	}
	return true
}

fn ip_to_bin(ip string) []string {
	mut ip_arr := ip.split('.')
	for mut ip_byte in ip_arr {
		mut bin_byte := strconv.format_int(ip_byte.int(),2)
		if bin_byte.len != 8{
			bin_byte = strings.repeat(48, 8-bin_byte.len)+bin_byte
		}
		ip_byte = bin_byte
	}
	return(ip_arr)
}

fn mask_to_bin(mask int) []string {
	mut bytes_arr := []string{}
	for _ in 0..mask/8 {
		bytes_arr << '11111111'
	}
	bytes_arr << strings.repeat(49,mask%8)+strings.repeat(48,8-mask%8)
	for {
		if bytes_arr.len == 4 {
			break
		}else{
			bytes_arr << '00000000'
		}
	}
	return(bytes_arr)
}

fn get_network_infos(ip_addr string, net_mask int) !string {
	bin_mask := mask_to_bin(net_mask)
	bin_ip := ip_to_bin(ip_addr)

	net_addr := get_net_addr(bin_ip, bin_mask)!
	first_addr := get_first_addr(get_bin_net_addr(bin_ip, bin_mask))!
	last_addr := get_last_addr(get_bin_broadcast_addr(get_bin_net_addr(bin_ip, bin_mask), get_bin_wirldcard(bin_mask)))!
	mask := bin_addr_to_dec(bin_mask)!
	wildcard := get_wildcard(bin_mask)!
	broadcast := bin_addr_to_dec(get_bin_broadcast_addr(get_bin_net_addr(bin_ip, bin_mask), get_bin_wirldcard(bin_mask)))!
	ip_type := match bin_addr_to_dec(bin_ip)! {
		net_addr {'network address.'}
		broadcast {'broadcast address.'}
		else {'host address.'}
	}

	println(term.bright_blue("The IP address is a $ip_type"))
	println(term.bold('Network address:    ')+net_addr)
	println(term.bold('First address:      ')+first_addr)
	println(term.bold('Last address:       ')+last_addr)
	println(term.bold('Mask:               ')+mask)
	println(term.bold('Wildcard:           ')+wildcard)
	println(term.bold('Broadcast:          ')+broadcast)
	return 'Successful'
}

fn get_bin_net_addr(bin_ip []string, bin_mask []string) []string {
	mut net_addr_bin := []string{}
	for byte_num in 0..4 {
		mut byte_bin := ''
		for bit_num in 0..8 {
			mut net_bit := bin_ip[byte_num][bit_num].ascii_str().int() & bin_mask[byte_num][bit_num].ascii_str().int()
			byte_bin += net_bit.str()
		}
		net_addr_bin << byte_bin
	}
	return net_addr_bin
}

fn get_net_addr(bin_ip []string, bin_mask []string) !string {
	mut net_addr_bin := get_bin_net_addr(bin_ip, bin_mask)
	mut net_addr_arr := []string{}
	for net_addr_byte in net_addr_bin {
		net_addr_arr << strconv.parse_int(net_addr_byte, 2, 16) or {return 'Failed to decode in decimal.'}.str()
	}
	return net_addr_arr.join('.')
}

fn get_bin_wirldcard(bin_mask []string) []string {
	mut wildcard_bin := []string{}
	for mask_byte in bin_mask {
		mut wildcard_bin_byte := ''
		for mask_bit in mask_byte {
			if mask_bit.ascii_str().int() == 1 {
				wildcard_bin_byte += '0'
			}else{
				wildcard_bin_byte += '1'
			}
		}
		wildcard_bin << wildcard_bin_byte
	}
	return wildcard_bin
}

fn get_wildcard(bin_mask []string) !string {
	wildcard_bin := get_bin_wirldcard(bin_mask)
	mut wildcard_arr := []string{}
	for wildcard_byte in wildcard_bin {
		wildcard_arr << strconv.parse_int(wildcard_byte, 2, 16) or {return 'Failed to decode in decimal.'}.str()
	}
	return wildcard_arr.join('.')
}

fn get_first_addr(net_bin []string) !string {
	mut first_addr := net_bin[..3]
	first_addr << net_bin[3][..7]+'1'
	mut first_addr_arr := []string{}
	for fisrt_addr_byte in first_addr {
		first_addr_arr << strconv.parse_int(fisrt_addr_byte, 2, 16) or {return 'Failed to decode in decimal.'}.str()	
	}
	return first_addr_arr.join('.')
}

fn get_last_addr(broadcast_bin []string) !string {
	mut last_addr :=  broadcast_bin[..3]
	last_addr << broadcast_bin[3][..7]+'0'
	return bin_addr_to_dec(last_addr)!
}

fn get_bin_broadcast_addr(net_bin []string, wildcard_bin []string) []string {
	mut broadcast_bin := []string{}
	for i, wildcard_byte in wildcard_bin {
		mut broadcast_bin_byte := ''
		for j, wildcard_bit in wildcard_byte {
			if wildcard_bit.ascii_str().int() == 1 {
				broadcast_bin_byte += '1'
			}else{
				broadcast_bin_byte += net_bin[i][j].ascii_str()
			}
		}
		broadcast_bin << broadcast_bin_byte
	}
	return broadcast_bin
}

fn bin_addr_to_dec(bin_addr []string) !string{
	mut addr_arr := []string{}
	for addr_byte in bin_addr {
		addr_arr << strconv.parse_int(addr_byte, 2, 16) or {return 'Failed to decode in decimal.'}.str()
	}
	return addr_arr.join('.')
}

fn main() {
	mut ip_addr := ''
	mut net_mask := 0
	match os.args.len {
		1 {
			banner()
			for {
				cidr := input('\nType an IP address (${term.bold('ex: 192.168.1.1/24')}):\n|> ')
				if cidr == 'exit' || cidr == 'EXIT' { exit(0) }
				if !check_ip(cidr) {
					println(term.warn_message("Invalid IP address."))
					continue 
				}
				ip_addr = cidr.split('/')[0]
				net_mask = cidr.split('/')[1].int()
				get_network_infos(ip_addr,net_mask)!
			}
		}
		2 {
			if check_ip(os.args[1]) {
				ip_addr = os.args[1].split('/')[0]
				net_mask = os.args[1].split('/')[1].int()
			}else{
				usage()
			}
		}
		else { usage() }
	}
	get_network_infos(ip_addr,net_mask)!
}