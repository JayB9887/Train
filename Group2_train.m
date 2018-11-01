%% Group: 2         Time: Tues-Thurs
%  Names: Jay, James, Michael, Noah


clear    all;
close    all;
delete(instrfindall);
clc;
tic();
%% Connect equipment
a = arduino('COM4');
a.servoAttach(1);
a.servoWrite(1, 170);
a.pinMode(14, 'output');
a.pinMode(15, 'output');
%right led pin number
rLed = 14;
%left led pin number
lLed = 15;
approach = 2;
departure = 3;

%% Infinite While loop
%setup motor
a.motorRun(1,'forward');
a.motorSpeed(1, 170);
%variables to keep track of time delay
delay1 = 0;
delay2 = 0;
% used to track only one value from sensors
delaydone1 = 0;
delaydone2 = 0;
while 1
    %checking approach sensor
    if(a.analogRead(approach) > 250 && ~delaydone1)
        delaydone2 = 0;
        delay1 = toc();
        fprintf('\nDelay for 1 half loop is %.2f seconds',delay1 - delay2);
        delaydone1 = 1;
    end
    %checking departure sensor
    if(a.analogRead(departure) > 250 && ~delaydone2)
        delaydone1 = 0;
        delay2 = toc();
        fprintf('\nDelay for 1 half loop is %.2f seconds',delay2 - delay1);
        delaydone2 = 1;
    end
end
    
    
