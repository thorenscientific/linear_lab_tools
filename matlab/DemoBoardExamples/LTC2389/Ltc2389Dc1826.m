function Ltc2389Dc1826
    verbose = 1;
    plotData = 1;
    writeToFile = 1;
    trigger = 1;
    numSamples = 32 * 1024;
    timeOut = 15;
    SAMPLE_BYTES = 3;
    
    % Returns the object in the class constructor
    comm = LtcControllerComm();  
    
    % find demo board with correct ID
    EEPROM_ID = '[0074 DEMO 10 DC1532A-A LTC2268-14 D2175]';
    eepromIdSize = length(EEPROM_ID);
    fprintf('Looking for a DC718 with a DC1826A demoboard\n');
    
    deviceInfoList = comm.ListControllers(comm.TYPE_DC718, 1);
	
	% Open communication to the device
    cId = comm.Init(deviceInfoList);
    
    for info = deviceInfoList
        % if strcmp(EEPROM_ID(1 : eepromIdSize - 1), comm.EepromReadString(cId, eepromIdSize))
		if(~isempty(strfind(comm.EepromReadString(cId, eepromIdSize), 'DC1826')))
            break;
        end
        cId = comm.Cleanup(cId);
    end
    
    if(cId == 0)
        fprintf('Device not found\n');
    else
        fprintf('Device Found\n');
    end
    
    if(verbose)
        fprintf('Starting data collect\n');
    end
    
    comm.DataSetCharacteristics(cId, false, SAMPLE_BYTES, false);
    
    if(trigger)
        comm.DataStartCollect(cId, numSamples, comm.TRIGGER_START_POSITIVE_EDGE);
        for i = 1:timeOut
            isDone = comm.DataIsCollectDone(cId);
            if(isDone)
                break;
            end
            pause(0.1);
            fprintf('Waiting up to %d seconds...%d\n', timeOut, i);
        end
    else
        comm.DataStartCollect(cId, numSamples, comm.TRIGGER_NONE);
        for i = 1:10
            isDone = comm.DataIsCollectDone();
            if(isDone)
                break;
            end
            pause(0.2);
        end
    end
    
    if(isDone ~= true)
        error('LtcControllerComm:HardwareError', ...
            'Data collect timed out (missing clock?)\n');
    end
    
    if(verbose)
        fprintf('Data collect done\n.');
        fprintf('Reading data\n');
    end
    dataBytes = comm.DataReceiveBytes(cId, numSamples * SAMPLE_BYTES);
    if(verbose)
        fprintf('Data read done, parsing done...\n');
    end

    data = zeros(1, numSamples);
    for i = 1:numSamples
        d1 = bitand(uint32(dataBytes(i * 3 - 2)), 255) * 65536;
        d1 = bitshift(d1, -16);
        d1 = bitand(d1, 255);
        d1 = bitshift(d1, 16);
        % d1 = bitand((uint8(dataBytes(i * 3 - 2)) * 65536), 16711680);
        d2 = bitand(uint32(dataBytes(i * 3 - 1)), 255) * 256;
        d2 = bitshift(d2, -8);
        d2 = bitand(d2, 255);
        d2 = bitshift(d2, 8);
        % d2 = bitand((uint8(dataBytes(i * 3 - 1)) * 256), 65280);
        d3 = bitand(uint32(dataBytes(i * 3)), 255);
        data(i) = bitor(bitor(d1, d2), d3);
        if(data(i) > 131072)
            data(i) = data(i) - 262144;
        end
    end

    if(writeToFile)
        if(verbose)
            fprintf('Writing data to file\n');
        end    

        fileID = fopen('data.txt','w');

        for i = 1:numSamples
            fprintf(fileID,'%d\n', data(i));
        end

        fclose(fileID);
        fprintf('File write done\n');
    end
    
    if(plotData)
        figure(1)
        plot(data)
        title('Time Domain Data')

        adcAmplitude = 262144.0 / 2.0;

        windowScale = (numSamples) / sum(blackman(numSamples));
        fprintf('Window scaling factor: %d\n', windowScale);
        
        data = data - mean(data);
        windowedData = data' .* blackman(numSamples);
        windowedData = windowedData .* windowScale; % Apply Blackman window
        freqDomain = fft(windowedData)/(numSamples); % FFT
        freqDomainMagnitude = abs(freqDomain); % Extract magnitude
        freqDomainMagnitudeDb = 20 * log10(freqDomainMagnitude/adcAmplitude);

        figure(2)
        plot(freqDomainMagnitudeDb)
        title('Frequency Domain')
    end
end