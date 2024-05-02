%% Car Control FIS
format compact
clear
clc

%% Creating Fuzzy Inference System
fis=newfis('tipper','mamdani');

%Add input - output variables and fuzzy partition
fis = addvar(fis,'input', 'dv',[0, 1]);
fis = addmf(fis, 'input', 1, 'VS', 'trimf', [-0.25 0 0.25]);
fis = addmf(fis, 'input', 1, 'S', 'trimf', [0 0.25 0.5]);
fis = addmf(fis, 'input', 1, 'M', 'trimf', [0.25 0.5 0.75]);
fis = addmf(fis, 'input', 1, 'L', 'trimf', [0.5 0.75 1]);
fis = addmf(fis, 'input', 1, 'VL', 'trimf', [0.75 1 1.25]);


fis = addvar(fis,'input', 'dh',[0, 1]);
fis = addmf(fis, 'input', 2, 'VS', 'trimf', [-0.25 0 0.25]);
fis = addmf(fis, 'input', 2, 'S', 'trimf', [0 0.25 0.5]);
fis = addmf(fis, 'input', 2, 'M', 'trimf', [0.25 0.5 0.75]);
fis = addmf(fis, 'input', 2, 'L', 'trimf', [0.5 0.75 1]);
fis = addmf(fis, 'input', 2, 'VL', 'trimf', [0.75 1 1.25]);

fis = addvar(fis,'input', 'theta',[-180, 180]);
fis = addmf(fis, 'input', 3, 'NL', 'trimf', [-270 -180 -90]);
fis = addmf(fis, 'input', 3, 'NS', 'trimf', [-180 -90 0]);
fis = addmf(fis, 'input', 3, 'ZE', 'trimf', [-90 0 90]);
fis = addmf(fis, 'input', 3, 'PS', 'trimf', [0 90 180]);
fis = addmf(fis, 'input', 3, 'PL', 'trimf', [90 180 270]);

fis = addvar(fis,'output', 'dtheta',[-130, 130]);
fis = addmf(fis, 'output', 1, 'NL', 'trimf', [-195 -130 -65]);
fis = addmf(fis, 'output', 1, 'NS', 'trimf', [-130 -65 0]);
fis = addmf(fis, 'output', 1, 'ZE', 'trimf', [-65 0 65]);
fis = addmf(fis, 'output', 1, 'PS', 'trimf', [0 65 130]);
fis = addmf(fis, 'output', 1, 'PL', 'trimf', [65 130 195]);


%Add Fuzzy Rule Base Description
rule1 = 'If (dh is not S) and (theta is NL) then (dtheta is PL)' ;
rule2 = 'If (dh is not S) and (theta is NS) then (dtheta is PS) ' ;
rule3 = 'If (dh is not S) and (theta is ZE) then (dtheta is ZE)' ;
rule4 = 'If (dh is not S) and (theta is PL) then (dtheta is NL)' ;
rule5 = 'If (dh is not S) and (theta is PS) then (dtheta is NS)' ;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rule6 = 'If (dh is S) and (theta is NL) then (dtheta is NL)' ;
rule7 = 'If (dh is S) and (theta is NS) then (dtheta is PL)' ;
rule8 = 'If (dh is S) and (theta is ZE) then (dtheta is PL)' ;
rule9 = 'If (dh is S) and (theta is PS) then (dtheta is ZE)' ; 
rule10 = 'If (dh is S) and (theta is PL) then (dtheta is NS)' ;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rule11 = 'If (dh is VS) and (theta is NL) then (dtheta is NL) ' ;
rule12 = 'If (dh is VS) and (theta is NS) then (dtheta is PL)' ;
rule13 = 'If (dh is VS) and (theta is ZE) then (dtheta is PL)' ;
rule14 = 'If (dh is VS) and (theta is PL) then (dtheta is NS)' ;
rule15 = 'If (dh is VS) and (theta is PS) then (dtheta is ZE)' ;



 % Add rules to the FIS
ruleList = char(rule1, rule2, rule3, rule4, rule5, rule6, rule7, ...
    rule8, rule9, rule10, rule11, rule12, rule13, rule14, rule15);

fis = addRule(fis,ruleList);

writeFIS(fis,'Car_Control_flc.fis');
