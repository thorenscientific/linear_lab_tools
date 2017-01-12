% DC751A-K / LTC2224 Interface Example
%
% This program demonstrates how to communicate with the LTC2224 demo board 
% using Matlab. Examples are provided for reading data captured by the ADC, 
% or test data generated by the ADC.
%  
% REVISION HISTORY
% $Revision: 5756 $
% $Date: 2016-09-16 12:58:34 -0700 (Fri, 16 Sep 2016) $
%
% Copyright (c) 2017, Linear Technology Corp.(LTC)
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

function varargout = ltc2224_dc751a_k(num_samples, is_verbose, do_plot, do_write_to_file)
    if ~exist('num_samples', 'var'); num_samples = 32 * 1024; end
    
    do_demo = false;
    if nargout == 0
        do_demo = true;
    end
    if ~exist('is_verbose', 'var'); is_verbose = do_demo; end
    if ~exist('do_plot', 'var'); do_plot = do_demo; end
    if ~exist('do_write_to_file', 'var'); do_write_to_file = do_demo; end
    
    controller = init_controller(is_verbose);
    
    data = controller.collect(num_samples, llt.common.LtcControllerComm.TRIGGER_NONE);
    
    if do_plot
        llt.common.plot(controller.get_num_bits(), data, 0, is_verbose);
    end
    if do_write_to_file
        llt.common.write_to_file_32_bit('data.txt', data, false, is_verbose);
    end
    
    if nargout > 0
        varargout{1} = data;
    end
end

function controller = init_controller(is_verbose)
    % Returns the object in the class constructor
    lcc = llt.common.LtcControllerComm();  
    controller = llt.common.Dc718(lcc, 'DC751A-K', ... dc_number
                                       false, ... is_positive_clock
                                       12, ... num_bits
                                       14, ... alignment
                                       true, ... is_bipolar
                                       is_verbose);
end