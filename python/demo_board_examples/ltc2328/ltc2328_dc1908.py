# -*- coding: utf-8 -*-
'''
DC1908 / LTC2328-18 Interface Example

This program demonstrates how to communicate with the LTC2328-18 demo board through Python.
Examples are provided for reading data captured by the ADC, or test data generated by
the ADC.

Board setup is described in Demo Manual 1908. Follow the procedure in this manual, and
verify operation with the PScope software. Once operation is verified, exit PScope
and run this script.

Tested with Python 2.7, Anaconda distribution available from Continuum Analytics,
http://www.continuum.io/

Demo board documentation:
http://www.linear.com/demo/1908
http://www.linear.com/product/LTC2328#demoboards

LTC2328 product page
http://www.linear.com/product/LTC2328


REVISION HISTORY
$Revision: 4276 $
$Date: 2015-10-20 10:38:41 -0700 (Tue, 20 Oct 2015) $

Copyright (c) 2015, Linear Technology Corp.(LTC)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of Linear Technology Corp.
'''

from time import sleep
import numpy as np
# Import communication library
import sys
sys.path.append("../../")
print sys.path
import ltc_controller_comm as comm

# Print extra information to console
verbose = True
plot_data = True

def ltc2328_dc1908(num_samples, verbose=True, do_demo=True):
    
    SAMPLE_BYTES = 3
    EEPROM_ID_SIZE = 50
    
    def vprint(s):
        """Print string only if verbose is on"""
        if verbose:
            print s

    if do_demo:
        plot_data = True
        write_to_file = True
    else:
        plot_data = False
        write_to_file = False
        
    # find demo board with correct ID
    # Full EEPROM string is 'LTC2328-18,D2315,DC1908A-D,YII101Q,NONE,--------'
    device_info = None
    print 'Looking for a DC718 with a DC1908 demoboard'
    for info in comm.list_controllers(comm.TYPE_DC718):
        with comm.Controller(info) as device:
            eeprom_id = device.eeprom_read_string(EEPROM_ID_SIZE)
            if 'DC1908' in eeprom_id:
                if verbose:
                    print 'Found a DC1908 demoboard'
                device_info = info
                break
    if device_info is None:
        raise(comm.HardwareError('Could not find a compatible device'))
    # Open communication to the demo board
    with comm.Controller(device_info) as controller:
    
        vprint('Starting data collect')
        controller.data_set_characteristics(False, SAMPLE_BYTES, False)
        controller.data_start_collect(num_samples, comm.TRIGGER_NONE)
    
        for i in range(10):
            is_done = controller.data_is_collect_done()
            if is_done:
                break
            sleep(0.2)
    
        if not is_done:
            controller.data_cancel_collect()
            raise comm.HardwareError('Data collect timed out (missing clock?)')
    
        vprint('Data collect done.')
        vprint('Reading data')
        num_bytes, data_bytes = controller.data_receive_bytes(end=num_samples*SAMPLE_BYTES)
        vprint('Data read done, parsing data...')
            
        data = [0] * num_samples
        for i in range(num_samples):
            data[i] = (((data_bytes[3*i]&0xFF) * 65536) & 0xFF0000) | (((data_bytes[3*i + 1]&0xFF) * 256) & 0x00FF00) | ((data_bytes[3*i + 2]&0xFF) & 0x0000FF)
            if(data[i] >= 0x20000):
                data[i] -= 0x40000
                
        if write_to_file == True:
            # write the data to a file
            vprint('Writing data to file')
            with open('data.txt', 'w') as f:
                for i, item in enumerate(data):
                    f.write(str(item) + '\n')
        
            vprint('File write done.')
    
        vprint('All finished!')
    
    
        if plot_data:
            from matplotlib import pyplot as plt
            plt.figure(1)
            plt.plot(data)
            plt.title('Time Domain Data')
    
            plt.show()
    
            ADC_AMPLITUDE = 262144.0 / 2.0
    
            windowscale = (num_samples) / sum(np.blackman(num_samples))
            vprint("Window scaling factor: " + str(windowscale))
    
            data -= np.average(data)
            windowed_data = data * np.blackman(num_samples) * windowscale # Apply Blackman window
            freq_domain_ch1 = np.fft.fft(windowed_data)/(num_samples) # FFT
            freq_domain_magnitude_ch1 = np.abs(freq_domain_ch1) # Extract magnitude
            freq_domain_magnitude_db = 20 * np.log10(freq_domain_magnitude_ch1/ADC_AMPLITUDE)
    
            plt.figure(2)
            plt.title('Frequency Domain')
            plt.plot(freq_domain_magnitude_db)
    
            plt.show()
        return(data)

if __name__ == '__main__':
    # How many points to capture, un-comment one line
#    NUM_SAMPLES = 1 * 1024
#    NUM_SAMPLES = 2 * 1024
#    NUM_SAMPLES = 4 * 1024
#    NUM_SAMPLES = 8 * 1024
#    NUM_SAMPLES = 16 * 1024
    NUM_SAMPLES = 32 * 1024
    
    # to use this function in your own code you would typically do
    # data = ltc2328_dc1908(num_samples)
    # Valid number of samples are 1024 to 65536 (powers of two)
    testdata = ltc2328_dc1908(NUM_SAMPLES, verbose=True, do_demo=True)
