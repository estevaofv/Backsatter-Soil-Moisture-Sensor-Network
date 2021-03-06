
close all;
clear all;

multiWaitbar( 'CloseAll' );
clc;



Fs = 1e6;            %Same as gnuradio
Ts = 1/Fs;

Resolution = 0.5;        % in Hz
N_F = Fs/Resolution;
F_axis = -Fs/2:Fs/N_F:Fs/2-Fs/N_F;

%Subcarrier center Freq
SUB_CENTER = [108500]

PBAR = 1; %Only one of each must be enabled
PLOT=0;
fig=0;

if(PBAR)
 %progressbar('%SM Sensor 1','%SM Sensor 2') % Init single bar
progressbar('%Soil Moisture ') % Init single bar
end
SUB_BW = 1.2e3;

%%
fi = fopen('rtlfifo', 'rb');

t_sampling = 0.1 ;      % seconds
N_samples = round(Fs*t_sampling);

t = 0:Ts:t_sampling-Ts;

counter = 0;
packets = 0;

HIST_SIZE = 100;

F_sense_hist = zeros(HIST_SIZE,1);


while(1)
    
    
    x = fread(fi, 2*N_samples, 'float32');% get samples (*2 for I-Q)
    x = x(1:2:end) + j*x(2:2:end);      % deinterleaving
    counter = counter + 1;
    
    
    
    if mod(counter, 2) == 0
        packets = packets + 1;
        
        % fft
        x_fft = fftshift(fft(x, N_F));
        
        % cfo estimate
        [mval mpos] = max(abs(x_fft).^2);
        
        DF_est = F_axis(mpos);
        
        % cfo correction
        x_corr = x.*exp(-j*2*pi*DF_est*t).';
        
        % corrected cfo
        x_corr_fft = fftshift(fft(x_corr, N_F));
        
        % sensor's fft
        
        
        for(ii = 1:length(SUB_CENTER))
            LEFT = SUB_CENTER(ii) - SUB_BW;
            RIGHT = SUB_CENTER(ii) + SUB_BW;
            
            x_sensor_fft = x_corr_fft;
            x_sensor_fft(F_axis < -RIGHT) = 0;
            x_sensor_fft(F_axis > RIGHT) = 0;
            x_sensor_fft(abs(F_axis) < LEFT) = 0;
            
            
            
            %find subcarrier
            [mval mpos] = max(abs(x_sensor_fft));
            
            F_sensor_est(ii) = abs(F_axis(mpos));
            F_sensor_power = round(mval);
           fprintf('ID=%d|N=%d|F=%5.1f|Power=%ld\n',ii,packets,F_sensor_est,F_sensor_power) 
           
            
            
            
            if fig
               
                figure(1);
                subplot(2, 1, 1);
                plot(t, real(x_corr));
                hold on;
                plot(t, imag(x_corr), 'g--');
                hold off;
                drawnow;
                subplot(2, 1, 2);
                semilogy(F_axis, abs(x_corr_fft).^2);
                grid on;
                axis tight;
                drawnow;
                
                
            end
            
            if PLOT
                if(ii == 1)
                    figure(1);
                    semilogy(F_axis, abs(x_corr_fft).^2);
                    axis tight;
                end
            end
        end
        
        
        if(PBAR)
            %bw = [1500 1600];
            bw = [1000];
            per = bw./(F_sensor_est - SUB_CENTER + bw./2);            
           
            per(1) = per(1)-0.93;
            
            %per(2) = per(2) - 1;
            
            if(per(1) >= 1)
                
                per(1) = 0.9999;
            end
            
            if(per(1) <= 0)
                
                per(1) = 0.001;
            end
            
%             if(per(2) >= 1)
%                 
%                 per(2) = 0.9999;
%             end
%             
%             if(per(2) <= 0)
%                 
%                 per(2) = 0.001;
%             end

            
            progressbar(per(1))
            
        end
    end
    
    
    
    
    
end







