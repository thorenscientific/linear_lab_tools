% DC1369 / LTC2261 Interface Example
% LTC2261: 12-Bit, 125Msps Ultralow Power 1.8V ADCs
%
% This program demonstrates how to communicate with the LTC2261 demo board 
% using Matlab. Examples are provided for reading data captured by the ADC, 
% or test data generated by the ADC.
% 
% Board setup is described in Demo Manual 1369. Follow the procedure in 
% this manual, and verify operation with the PScope software. Once 
% operation is verified, exit PScope and run this script.
% 
% Demo board documentation:
% http://www.linear.com/demo/1369
% http://www.linear.com/product/LTC2261#demoboards
% 
% LTC2261 product page
% http://www.linear.com/product/LTC2261
% 
% REVISION HISTORY
% $Revision$
% $Date$
%
% Copyright (c) 2015, Linear Technology Corp.(LTC)
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

% NOTE:
% 	ADD THE ABSOLUTE PATH TO "linear_lab_tools\matlab" FOLDER BEFORE RUNNING THE SCRIPT.
%   RUN "mex -setup" TO SET UP COMPILER AND CHOSE THE OPTION "Lcc-win32 C".
	
function Ltc2261Dc1369(arg1NumSamples, arg2Verbose)
    
import Llt.Utils.BlackmanHarris92

    if(~nargin)
        numAdcSamples = 64 * 1024;
        % Print extra information to console
        verbose = true;
    else
        numAdcSamples = arg1NumSamples;
        verbose = arg2Verbose;
    end
    
    plotData = true;
    
    % set testDataReg to one of these constants
    DATA_REAL = 0;
    DATA_ALL_ZEROS = 8;
    DATA_ALL_ONES = 24;
    DATA_CHECKERBOARD = 40;
    DATA_ALTERNATING = 56;
    %testDataReg = DATA_CHECKERBOARD
    testDataReg = DATA_REAL;
    
    NUM_ADC_SAMPLES_PER_CH = numAdcSamples / 2;
    NUM_ADC_SAMPLES_X2 = numAdcSamples * 2;
    sampleBytes = 2;
 	
	% Returns the object in the class constructor
    comm = Llt.Common.LtcControllerComm();  
    
    % find demo board with correct ID
    EEPROM_ID = 'LTC2261-14,D9002,DC1369A-A,YEE232T,DLVDS,-------';
    eepromIdSize = length(EEPROM_ID);
    fprintf('Looking for a DC890 with a DC1369A demoboard\n');
    
    deviceInfoList = comm.ListControllers(comm.TYPE_DC890);
    cId = comm.Init(deviceInfoList);
    
    for info = deviceInfoList
        % if strcmp(EEPROM_ID(1 : eepromIdSize - 1), comm.EepromReadString(cId, eepromIdSize))
		if ~isempty(strfind(comm.EepromReadString(cId, eepromIdSize), 'DC1369'))
            break;
        end
        cId = comm.Cleanup(cId);
    end
    
    if(cId == 0)
        fprintf('\nDevice not found');
    else
        fprintf('\nDevice Found');
    end
    
    comm.DC890GpioSetByte(cId, 248);
    comm.DC890GpioSpiSetBits(cId, 3, 0, 1);
    
    if (verbose)
        fprintf('Configuring SPI registers');
    end
    
    if (testDataReg == DATA_REAL)
        fprintf('\nSet to read real data');
    else
        fprintf('\nSet to generate test data');
    end
    
    comm.SpiSendByteAtAddress(cId, 0, 128);
    comm.SpiSendByteAtAddress(cId, 1, 0);
    comm.SpiSendByteAtAddress(cId, 2, 0);
    comm.SpiSendByteAtAddress(cId, 3, 113);
    comm.SpiSendByteAtAddress(cId, 4, testDataReg);
    
    if (comm.FpgaGetIsLoaded(cId, 'DLVDS'))
       if(verbose)
            fprintf('\nLoading FPGA');
       end 
       comm.FpgaLoadFile(cId, 'DLVDS');
    else
       if(verbose)
            fprintf('\nFPGA already loaded');
       end 
    end
    
    if(verbose)
        fprintf('\nStarting Data Collect');
    end 
    
    comm.DataSetCharacteristics(cId, true, sampleBytes, true);
    comm.DataStartCollect(cId, NUM_ADC_SAMPLES_X2, comm.TRIGGER_NONE);
    
    for i = 1: 10
        isDone = comm.DataIsCollectDone(cId);
        if(isDone)
            break;
        end
        pause(0.2);
    end
    
    if(isDone ~= true)
        comm.ErrorOnBadStatus(cId, 1);   %HardwareError
    end
    
    if(verbose)
        fprintf('\nData Collect done');
    end
    
    comm.DC890Flush(cId);
    
    if(verbose)
        fprintf('\nReading data');
    end
    
    [data, numBytes] = comm.DataReceiveUint16Values(cId, NUM_ADC_SAMPLES_X2);
    
    if(verbose)
        fprintf('\nData Read done');
    end
    
    % Split data into two channels
    dataCh1 = zeros(1, NUM_ADC_SAMPLES_PER_CH);
    
    for i = 1 : NUM_ADC_SAMPLES_PER_CH
        dataCh1(i) = bitand(data(2*i - 1), 16383);
    end
    
    if(verbose)
        fprintf('\nWriting data to file');
    end    
    
    fileID = fopen('data.txt','w');
    
    for i = 1:size(data)
        if(mod(i, 2) == 0)
            fprintf(fileID,'%d\r\n', data(i));
        end
    end
    
    fclose(fileID);
    fprintf('\nFile write done');
    if(plotData == true)
        figure(1)
        plot(dataCh1)
        title('Time Domain Data')

        adcAmplitude = 16384.0 / 2.0;

        windowScale = (numAdcSamples/2) / sum(BlackmanHarris92(numAdcSamples/2));
        fprintf('\nWindow scaling factor: %d', windowScale);

        dataCh1 = dataCh1 - mean(dataCh1);
        windowedDataCh1 = dataCh1' .* BlackmanHarris92(numAdcSamples/2);
        windowedDataCh1 = windowedDataCh1 .* windowScale; % Apply BlackmanHarris92 window
        freqDomainCh1 = fft(windowedDataCh1)/(NUM_ADC_SAMPLES_PER_CH); % FFT
        freqDomainMagnitudeCh1 = abs(freqDomainCh1); % Extract magnitude
        freqDomainMagnitudeDbCh1 = 20 * log10(freqDomainMagnitudeCh1/adcAmplitude);

        figure(2)
        plot(freqDomainMagnitudeDbCh1)
        title('Frequency Domain Data')  
    end
    fprintf('\nAll finished');
end