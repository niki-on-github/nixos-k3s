# Hardware

At October 2024 i switched the Node Hardware from Supermicro Intel System to an AMD based System.

The goal was to build a system that provides all necessary services with less than 50W power requirement and 10gb ethernet. In addition I wanted to have ecc ram as I have had corrupted files in the past due to unrecognized memory errors (Lesson Lerned: Never ever run a server without ECC RAM!).

In order to meet the energy requirements I have made the following decisions:

- Mainboard without a IPMI and BMC (-10W).
- Use B550 instead of x570 chipset (-5W).
- Use only 2 RAM DIMM (-4W).
- Use SFP+ instead of RJ45 10GB Ethernet (-5W).

## Components

- Mainboard: ASRock B550M Pro4 AMD
- CPU: AMD Ryzen 7 Pro 5750GE (35W TDP)
- RAM: 2 x 32GB Kingston KSM32ED8/32HC DDR4-3200 DIMM CL22 Single (ECC)
- PSU: Supermicro PWS-203-1H 200W
- NVME: 4TB Lexar NM790 M.2 2280
- NIC: Intel X710-DA2 10GbE
- SSD1: 1TB WD Red SA500
- SSD2: 1TB Samsung 870 Evo
- Geekworm X650 PiKVM (seperate power)

## Power Consumption

Measured with PiKVM off.

- Idle (No Kubernetes Running): 26W
- Normal Operation (Approx 12% Load): 40W
- Max Load: 65W
