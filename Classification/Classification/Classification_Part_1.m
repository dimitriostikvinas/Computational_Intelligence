%% Tikvinas Dimitrios 9998 
% Classification Part 1
%%

close all; 
clear all;

% Loading the data
data = load('haberman.data');
preproc = 1;

% Splitting the data using split_scale according to the percentages 60/20/20 
[trnData,chkData,tstData]=split_scale(data,preproc);   % opws sto arxeio TSK_Regression

% After reviewing the data, we find out that we have two classes for the target variable,
% the 1 and 2

% The variable which will determine the number of fuzzy rules will be the clusters' radius
% So, according to the requests, we will use two extreme values, 0.2 and
% 0.9, in order to make the results clearer
radius = [0.2 0.9];

% Matrices to store the depended's metrics
OA_dep = zeros(2,1);
PA_dep = zeros(2,2);
UA_dep = zeros(2,2);
K_dep = zeros(2,1);
error_matrix_dep = zeros(2,2,2);
fuzzy_rules_dep = zeros(2,1);

% Matrices to store the independed's metrics
OA_indep = zeros(2,1);
PA_indep = zeros(2,2);
UA_indep = zeros(2,2);
K_indep = zeros(2,1);
error_matrix_indep = zeros(2,2,2);
fuzzy_rules_indep = zeros(2,1);

% Counter in order to make the addmf() work
mf_name = strings(10000,1);
for i = 1:10000
    mf_name(i) = "mf"+i;
end
counter = 0;

% We will run two models for each radius each time,
% one for class independent and one for class dependent

for k = 1:2
    
    %Clustering Per Class
    [c1,sig1]=subclust(trnData(trnData(:,end)==1,:),radius(k));
    [c2,sig2]=subclust(trnData(trnData(:,end)==2,:),radius(k));
    num_rules=size(c1,1)+size(c2,1);
    
    %Build FIS From Scratch 
    my_fis=newfis('FIS_SC','sugeno');
    
    %Add Input-Output Variables 
    names_in={'in1','in2','in3'};
    for i=1:size(trnData,2)-1
        my_fis=addvar(my_fis,'input',names_in{i},[0 1]);
    end
    my_fis=addvar(my_fis,'output','out1',[0 1]);
    
    %Add Input Membership Functions 
    name = 'sth';
    for i=1:size(trnData,2)-1
        for j=1:size(c1,1)
            counter = counter + 1;
            my_fis=addmf(my_fis,'input',i,mf_name(counter,1),'gaussmf',[sig1(i) c1(j,i)]);
        end
        for j=1:size(c2,1)
            counter = counter + 1;
            my_fis=addmf(my_fis,'input',i,mf_name(counter,1),'gaussmf',[sig2(i) c2(j,i)]);
        end
    end
    
    counter = 0;
    %Add Output Membership Functions 
    params=[zeros(1,size(c1,1)) ones(1,size(c2,1))];
    for i=1:num_rules
        counter = counter + 1;
        my_fis=addmf(my_fis,'output',1,mf_name(counter,1),'constant',params(i));
    end

    counter = 0;
    %Add FIS Rule Base
    ruleList=zeros(num_rules,size(trnData,2));
    for i=1:size(ruleList,1)
        ruleList(i,:)=i;
    end
    ruleList=[ruleList ones(num_rules,2)];
    my_fis=addrule(my_fis,ruleList);
    
    %Train & Evaluate ANFIS 
    % training for 100 epoches
    [trnFis,trnError,~,valFis,valError]=anfis(trnData,my_fis,[100 0 0.01 0.9 1.1],[],chkData);
    figure();
    plot([trnError valError],'LineWidth',2); grid on;
    legend('Training Error','Validation Error');
    xlabel('# of Epochs');
    ylabel('Error');
    titlos = "Class Dependent with radius = " + radius(k);
    title(titlos);
    Y=evalfis(tstData(:,1:end-1),valFis);
    Y=round(Y);
    % I want only two values, 1 and 2, just like the classes
    for i=1:size(Y,1)
        if Y(i) < 1
            Y(i) = 1;
        elseif Y(i) > 2
            Y(i) = 2;
        end
    end
    
    diff=tstData(:,end)-Y;
    
    
    % Plotting the membership functions needed for each feature
    for j = 1:size(trnData,2)-1 % as many as the features
        figure();
        plotmf(valFis,'input',j);
        titlos = "Model dependent " + k + " Feature " + j + " with radius = " + radius(k);
        title(titlos);
    end
    
    % Building the error matrix as prescribed 
    Error_matrix = zeros(2); % due to having 2 klaseis
    Error_matrix = confusionmat(tstData(:,end),Y);
    
    % Overall Accuracy
    TP = Error_matrix(1,1);
    FP = Error_matrix(2,1);
    TN = Error_matrix(2,2);
    FN = Error_matrix(1,2);
    OA = (TP + TN)/(TP + FP + TN + FN);
    
    % PA UA metrics
    PA1 = TP/(FN + TP);
    PA2 = TN/(FP + TN);
    UA1 = TP/(TP + FP);
    UA2 = TN/(TN + FN);
    
    % K
    N = size(tstData,1);
    K = (N*(TP + TN) - ((TP + FP)*(TP + FN) + (FN + TN)*(FP + TN)))/(N^2 - ((TP + FP)*(TP + FN) + (FN + TN)*(FP + TN)));
    
    % Storing dependent's calculations 
    OA_dep(k,1) = OA;
    PA_dep(k,1) = PA1;
    PA_dep(k,2) = PA2;
    UA_dep(k,1) = UA1;
    UA_dep(k,2) = UA2;
    K_dep(k,1) = K;
    error_matrix_dep(:,:,k) = Error_matrix;
    
    % number of fuzzy rules
    fuzzy_rules_dep(k,1) = size(valFis.Rules,2);
    
    
    %Compare with Class-Independent Scatter Partition 
    my_fis2=genfis2(trnData(:,1:end-1),trnData(:,end),radius(k));
    [trnFis,trnError,~,valFis,valError]=anfis(trnData,my_fis2,[100 0 0.01 0.9 1.1],[],chkData);
    
    figure();
    plot([trnError valError],'LineWidth',2); grid on;
    legend('Training Error','Validation Error');
    xlabel('# of Epochs');
    ylabel('Error');
    titlos = "Class Independent with radius = " + radius(k) ;
    title(titlos);
    
    Y=evalfis(tstData(:,1:end-1),valFis);
    Y=round(Y);
    
    % I want only two values, 1 and 2, just like the classes
    for i=1:size(Y,1)
        if Y(i) < 1
            Y(i) = 1;
        elseif Y(i) > 2
            Y(i) = 2;
        end
    end
    
    diff=tstData(:,end)-Y;
    
    % Plotting the membership functions needed for each feature
    for j = 1:size(trnData,2)-1 % as many as the features
        figure();
        plotmf(valFis,'input',j);
        titlos = "Model independent " + k + " Feature " + j + " with radius = " + radius(k) ;
        title(titlos);
    end
    
    % metrikes gia independent
    Error_matrix = confusionmat(tstData(:,end),Y);
    
    % overall accuracy
    TP = Error_matrix(1,1);
    FP = Error_matrix(2,1);
    TN = Error_matrix(2,2);
    FN = Error_matrix(1,2);
    OA = (TP + TN)/(TP + FP + TN + FN);
    
    % PA UA
    PA1 = TP/(FN + TP);
    PA2 = TN/(FP + TN);
    UA1 = TP/(TP + FP);
    UA2 = TN/(TN + FN);
    
    % K
    N = size(tstData,1);
    K = (N*(TP + TN) - ((TP + FP)*(TP + FN) + (FN + TN)*(FP + TN)))/(N^2 - ((TP + FP)*(TP + FN) + (FN + TN)*(FP + TN)));
    
    % Storing independent's calculations 
    OA_indep(k,1) = OA;
    PA_indep(k,1) = PA1;
    PA_indep(k,2) = PA2;
    UA_indep(k,1) = UA1;
    UA_indep(k,2) = UA2;
    K_indep(k,1) = K;
    error_matrix_indep(:,:,k) = Error_matrix;
    
    % number of fuzzy rules
    fuzzy_rules_indep(k,1) = size(valFis.Rules,2);
    
end

% Matrices' display
OA_dep 
PA_dep 
UA_dep 
K_dep 
error_matrix_dep 
fuzzy_rules_dep

OA_indep 
PA_indep 
UA_indep 
K_indep 
error_matrix_indep 
fuzzy_rules_indep






