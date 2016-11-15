% DC1565A-C / LTC2150-14 Interface Example
%
% This program demonstrates how to communicate with the LTC2150-14 demo board 
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

function varargout = Ltc2150_14Dc1565aC(nSamples, spiRegisters, isVerbose, doPlot, doWriteToFile)   
    if ~exist('nSamples', 'var'); nSamples = 32 * 1024; end
    if ~exist('spiRegisters', 'var')
        spiRegisters = [ ... address        value
                             hex2dec('00'), hex2dec('80'), ...
                             hex2dec('01'), hex2dec('00'), ...
                             hex2dec('02'), hex2dec('00'), ...
                             hex2dec('03'), hex2dec('00'), ...
                             hex2dec('04'), hex2dec('00'), ...
                       ];
    end

    doDemo = false;
    if nargout == 0
        doDemo = true;
    end
    if ~exist('isVerbose', 'var'); isVerbose = doDemo; end
    if ~exist('doPlot', 'var'); doPlot = doDemo; end
    if ~exist('doWriteToFile', 'var'); doWriteToFile = doDemo; end
   
    controller = InitController(spiRegisters, isVerbose);
    [ch0] = ...
        controller.Collect(nSamples, Llt.Common.LtcControllerComm.TRIGGER_NONE);
    
    if doPlot
        Llt.Common.PlotChannels(controller.GetNBits(), ...
            ch0, ...
            isVerbose);
    end
    
    if doWriteToFile
        Llt.Common.WriteChannelsToFile32Bit('data.txt', ...
            ch0, ...
            isVerbose);
    end
    
    channels = { ch0 };
    varargout(1:nargout) = channels(1:nargout);
end

function controller = InitController(spiRegisters, isVerbose)
    lcc = Llt.Common.LtcControllerComm();
    controller = Llt.Common.Dc1371(lcc, 'DC1565A-C', ... dcNumber
                                        'S2157', ... fpgaLoad
                                        1, ... nChannels
                                        14, ... nBits
                                        16, ... alignmnent
                                        true, ... isBipolar
                                        '0x20000000', ... demoConfig
                                        spiRegisters, isVerbose);
end
