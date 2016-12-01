% DC1565A-D / LTC2152-12 Interface Example
%
% This program demonstrates how to communicate with the LTC2152-12 demo board 
% using Matlab. Examples are provided for reading data captured by the ADC, 
% or test data generated by the ADC.
% 
% REVISION HISTORY
% $Revision: 5756 $
% $Date: 2016-09-16 12:58:34 -0700 (Fri, 16 Sep 2016) $
%
% Copyright (c) 2016, Linear Technology Corp.(LTC)
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
% 1. Redistributions of source code must retain the above copyright notice, 
%    this list of conditions and the following disclaimer.
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
% ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
% ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
% ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 
% The views and conclusions contained in the software and documentation are those
% of the authors and should not be interpreted as representing official policies,
% either expressed or implied, of Linear Technology Corp.

function varargout = ltc2152_12_dc1565a_d(num_samples, spi_registers, is_verbose, do_plot, do_write_to_file)
    if ~exist('num_samples', 'var'); num_samples = 32 * 1024; end
    if ~exist('spi_registers', 'var')
        spi_registers = [ ... address        value
                              hex2dec('00'), hex2dec('80'), ...
                              hex2dec('01'), hex2dec('00'), ...
                              hex2dec('02'), hex2dec('00'), ...
                              hex2dec('03'), hex2dec('00'), ...
                              hex2dec('04'), hex2dec('00'), ...
                        ];
    end

    do_demo = false;
    if nargout == 0
        do_demo = true;
    end
    if ~exist('is_verbose', 'var'); is_verbose = do_demo; end
    if ~exist('do_plot', 'var'); do_plot = do_demo; end
    if ~exist('do_write_to_file', 'var'); do_write_to_file = do_demo; end
   
    controller = init_controller(spi_registers, is_verbose);
    [ch0] = ...
        controller.collect(num_samples, llt.common.LtcControllerComm.TRIGGER_NONE);
    
    if do_plot
        llt.common.plot_channels(controller.get_num_bits(), ...
            ch0, ...
            is_verbose);
    end
    
    if do_write_to_file
        llt.common.write_channels_to_file_32_bit('data.txt', ...
            ch0, ...
            is_verbose);
    end
    
    channels = { ch0 };
    varargout(1:nargout) = channels(1:nargout);
end

function controller = init_controller(spi_registers, is_verbose)
    lcc = llt.common.LtcControllerComm();
    controller = llt.common.Dc1371(lcc, 'DC1565A-D', ... dc_number
                                        'S2157', ... fpga_load
                                        1, ... num_channels
                                        12, ... num_bits
                                        16, ... alignmnent
                                        true, ... is_bipolar
                                        '0x20000000', ... demo_config
                                        spi_registers, is_verbose);
end
