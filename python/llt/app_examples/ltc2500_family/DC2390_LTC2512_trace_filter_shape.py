# -*- coding: utf-8 -*-
"""
    Description:
        The purpose of this module is to perform a sweep of frequencies to
        trace the filter shape of the LTC2512.


    Created by: Noe Quintero
    E-mail: nquintero@linear.com

    REVISION HISTORY
    $Revision: 2583 $
    $Date: 2014-06-27 17:21:46 -0700 (Fri, 27 Jun 2014) $
    
    Copyright (c) 2015, Linear Technology Corp.(LTC)
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, 
       this list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright 
       notice, this list of conditions and the following disclaimer in the 
       documentation and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
    ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.

    The views and conclusions contained in the software and documentation are 
    those of the authors and should not be interpreted as representing official
    policies, either expressed or implied, of Linear Technology Corp.


"""

###############################################################################
# Libraries
###############################################################################

import sys #, os, socket, ctypes, struct
import numpy as np
#from subprocess import call
from time import sleep
from matplotlib import pyplot as plt
# Okay, now the big one... this is the module that communicates with the SoCkit
from llt.common.mem_func_client_2 import MemClient ## Updated to client_2
#from llt.utils.DC2390_functions import *
from llt.utils.DC2390_functions import * # Leaving here as a commend during restructuring
from llt.utils.sockit_system_functions import *
import time


###############################################################################
# Script Parameters
# Change the parameters to run different scenarios.  
###############################################################################


# Uncomment one choice. The differences are that the LTC2500 does not
# require manual configuration, and has a maximum MCLK sample rate of 1MSPS
# vs. 1.6MSPS for the LTC2512.

#ADC = 2512
ADC = 2500


#ADC 'U1' and 'U2' are the choices. UN-comment selected ADC
ADC = 'U1'
#ADC = 'U2'

# DF of 32, 16, 8, 4 are the choices for the LTC2512
#DF = 4
#DF = 8
DF = 16
#DF = 32

# Set sample depth, for each frequency that is tested
NUM_SAMPLES = 8192
# Number of frequencies to plot
NUM_FREQS = 256

# Plot out first bin time domain data, count bits for this point. Useful
# for hardware / software / Verilog debugging
DEBUG = False

if ADC == 'U1':
    mux_port = DC2390_FIFO_ADCA_FIL
else:
    mux_port = DC2390_FIFO_ADCB_FIL

if DF == 4:
    down_sample_factor = LTC2500_DF_4
elif DF == 8:
    down_sample_factor = LTC2500_DF_8
elif DF == 16:
    down_sample_factor = LTC2500_DF_16
else:
    down_sample_factor = LTC2500_DF_32
    
master_clock = 50000000 # 50MHz, standard setting for DC2390
SYSTEM_CLOCK_DIVIDER = 99 # Divide by 100, 500ksps Nyquist rate



###############################################################################
# Global Constants
###############################################################################

LUT_NCO_DIVIDER = 0xFFFF # NCO updates every cycle
nco_word_width = 32

###############################################################################
# Main program
###############################################################################

print "\n/////////////////////////////////////////////"
print "// LTC2512 / LTC2500 Trace Filter Shape Demo //"
print "///////////////////////////////////////////////"



if ADC == 2512:
    if DF == 4:
        raw_input("\nPlease set SEL1, SEL0 jumpers to 0, 0 \nthen hit enter")
    elif DF == 8:
        raw_input("\nPlease set SEL1, SEL0 jumpers to 0, 1 \nthen hit enter")
    elif DF == 16:
        raw_input("\n\nPlease set SEL1, SEL0 jumpers to 1, 0 \nthen hit enter")
    else:
        raw_input("\n\nPlease set SEL1, SEL0 jumpers to 1, 1 \nthen hit enter")

# Get the host from the command line argument. Can be numeric or hostname.
HOST = sys.argv[1] if len(sys.argv) == 2 else '127.0.0.1'

print '\nStarting client'
client = MemClient(host=HOST)

# Read FPGA type and revision
rev_id = client.reg_read(REV_ID_BASE)
type_id = rev_id & 0x0000FFFF
rev = (rev_id >> 16) & 0x0000FFFF
print 'FPGA load type ID: %04X' % type_id
print 'FPGA load revision: %04X' % rev

start_time = time.time();

print("Setting up system parameters.\n");
client.reg_write(SYSTEM_CLOCK_BASE, ((LUT_NCO_DIVIDER << 16) | SYSTEM_CLOCK_DIVIDER))
client.reg_write(NUM_SAMPLES_BASE, NUM_SAMPLES)

# Set the LTC6954 to output 50 MHz
# Divisors of 5, 6 will give CLK frequencies of 40MHz, 33.3MHz. This may be
# useful for debugging FPGA timing.
LTC6954_configure(client, 4 )
client.reg_write(LED_BASE, (LTC2500_DF_64 | LTC2500_SSCIN_FLAT_FILT)) # Initial LTC2500 SYNC

# Set Mux for filtered data
# Set Dac A for SIN and Dac B for LUT
client.reg_write(DATAPATH_CONTROL_BASE, mux_port | 
                 DC2390_DAC_B_NCO_COS | DC2390_DAC_A_NCO_SIN | 
                 DC2390_LUT_ADDR_COUNT | DC2390_LUT_RUN_CONT)
#ltc2500_cfg_led_on  = ((down_sample_factor | LTC2500_SINC_FILT)) | 0x03# | (LTC2500_N_FACTOR << 16)
#ltc2500_cfg_led_off = ((down_sample_factor | LTC2500_SINC_FILT))# | (LTC2500_N_FACTOR << 16)
ltc2500_cfg_led_on  = (((down_sample_factor | LTC2500_SSCIN_FLAT_FILT)) | 0x03) # | (LTC2500_N_FACTOR << 16)
ltc2500_cfg_led_off = (((down_sample_factor | LTC2500_SSCIN_FLAT_FILT))       )# | (LTC2500_N_FACTOR << 16)

client.reg_write(LED_BASE, ltc2500_cfg_led_on)
sleep(0.1)
client.reg_write(LED_BASE, ltc2500_cfg_led_off)
sleep(0.1)



# Sweep the DAC freq and measure the filter respose
filter_shape = []
freq_bin = []

fig1 = plt.figure(1)
plt.subplot(1, 1, 1)

plt.title('LTC25xx Filter Shape')
plt.xlabel("Bin")
plt.ylabel("dB")
plt.xlim([0,NUM_FREQS])
mng = plt.get_current_fig_manager()
#mng.window.showMaximized()
plt.ion() # Go interactive...


for x in range(0, NUM_FREQS):
    print("Data point: " + str(x))
    # Calculate the NCO to coherent bin
    bin_number = (x+1)*8 # Number of cycles over the time record
    bin_number = (x+1)*1 # Number of cycles over the time record
    
    # Produce different bin ranges based on DF
    if DF == 4:
        bin_number *= 8 
    elif DF == 8:
        bin_number *= 4 
    elif DF == 16:
        bin_number *= 2
    
    sample_rate = master_clock / (SYSTEM_CLOCK_DIVIDER + 1) # 250ksps for 50M clock, 200 clocks per sample
    cycles_per_sample = float(bin_number) / float(NUM_SAMPLES)
    cycles_per_dac_sample = cycles_per_sample / (SYSTEM_CLOCK_DIVIDER + 1)
    tuning_word = int(cycles_per_dac_sample * 2**nco_word_width)
    print("Tuning Word:" + str(tuning_word))
    print("Bin Number:" + str(bin_number) + " / " + str(NUM_SAMPLES/2))
    freq_bin.append(bin_number)
    
    # Set the NCO
    client.reg_write(TUNING_WORD_BASE, tuning_word)
    
    # Capture the data
#    data = capture(client, NUM_SAMPLES, timeout = 1.0) # Updating to new capture...
    sleep(0.5)
    data_pre = sockit_capture(client, NUM_SAMPLES, trigger = TRIG_NOW, timeout = 1.0)
    data = sockit_uns32_to_signed32(data_pre)
    
    # Remove DC content
    data -= np.average(data)
    
    # Apply windowing to data    
    data = data * np.blackman(NUM_SAMPLES)    
    
    # Convert time domain data to frequncy domain
    fftdata = np.abs(np.fft.fft(data))
    
    if x == 0:
        max_amp = np.amax(fftdata)
    
    # Convert to dB
    fftdb = 20*np.log10(fftdata / max_amp)
    amplitude = np.amax(fftdb[5:NUM_SAMPLES/2-1])
    print("Amplitude of filtered data: " + str(amplitude))
    filter_shape.append(amplitude)

    plt.cla()
    plt.title('LTC25xx Filter Shape')
    plt.xlabel("Bin")
    plt.ylabel("dB")

    plt.plot(freq_bin, filter_shape, marker='o', linestyle='-', color="green")
    plt.show()
    plt.pause(0.0001) # Small delay







    # Extra debug info - for first bin, plot time domain data and bit counter    
    if(x == 1 and DEBUG == True):
    # Plot time domain data
        plt.figure(2) # Plot for time domain data
        plt.plot(data)
        plt.show()        
        
        bitmask = 1
        for bit in range (0, 32):
            bitcount = 0
            for point in range(0, NUM_SAMPLES):
                if((data_pre[point] & bitmask) == bitmask):
                    bitcount += 1
            print("Number of 1s in bit " + str(bit) + ": " + str(bitcount))
            bitmask *= 2 # Test next bit...


# Plot the results
#plt.figure(1)
#plt.plot(freq_bin,filter_shape)
#plt.title('LTC2512 Filter Shape')
#plt.xlabel("Bin")
#plt.ylabel("dB")
#plt.show()

print "The program took", (time.time() - start_time)/60, "min to run"
