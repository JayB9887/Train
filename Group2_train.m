%% Group: 2         Time: Tues-Thurs
%  Names: Jay, James, Michael, Noah


clear    all;
close    all;
delete(instrfindall);
clc;

%% Connect equipment
a = arduino('COM4');
a.servoAttach(1);
a.pinMode(14, 'output');
a.pinMode(15, 'output');
%right led pin number
rLed = 14;
%left led pin number
lLed = 15;
approach = 2;
departure = 3;
