%% Tikvinas Dimitrios 9998
% Regression Part 2

%%
close all; 
clear all;

% loading the data and apply normalization in every column except the last
% one being the target variable
data = csvread('superconduct.csv',0,0);
norm_data = data(:,1:end-1);
norm_data = normalize(norm_data);
data = [norm_data(:,1:end) data(:,end)];


% Evaluation function 
Rsq = @(ypred,y) 1-sum((ypred-y).^2)/sum((y-mean(y)).^2);

% splitting the data during the cross validation and not beforehand

% Grid Search 
% For the kept features' parameter we will use the values
% 3 6 9 12
% and for the clusters' radius the values 
% 0.2 0.4 0.6 0.8 1

parameters = zeros(4,5,2); % 4x5x2 due to having 4x5 trials for each of the 2 parameters

parameters(:,:,1) = [3 3 3 3 3; 6 6 6 6 6; 9 9 9 9 9; 12 12 12 12 12];
parameters(:,:,2) = [0.2 0.4 0.6 0.8 1; 0.2 0.4 0.6 0.8 1; 0.2 0.4 0.6 0.8 1; 0.2 0.4 0.6 0.8 1];

% Matrix to store the metrics  
all_metrics = zeros(4,5,4);

% 5-fold cross validation
k = 5;

% Using the built in Matlab function Relief to reduce the number of features 
[idx,weights] = relieff(data(:,1:end-1),data(:,end),6);

rmse = zeros(4,5);
rules = zeros(4,5);
kept_f = zeros(4,5);


% Grid Search
for i = 1:4
    for j = 1:5
        kept_features = parameters(i,j,1);
        aktina_r = parameters(i,j,2);
        % cv partition for the k-fold
        % splitting the data into 80% train and 20% test
        part_for_kfold1 = cvpartition(data(:,end),'KFold',5,'Stratify',true);
        
        % Matrix to store the metrics after the cross validation
        metrics_of_cross_val = zeros(k,4);
        
        
        for repetition = 1:part_for_kfold1.NumTestSets
           % splitting the training data into 60% training and 20% validation 
           midway_training_data = data(training(part_for_kfold1,repetition),:);
           testing_data = data(test(part_for_kfold1,repetition),:);

           % splitting the midway training data into 60% training data and
           % 20% testing data
           part_for_kfold2 = cvpartition(midway_training_data(:,end),'KFold',4,'Stratify',true);
           training_data = midway_training_data(training(part_for_kfold2,2),:);
           checking_data = midway_training_data(test(part_for_kfold2,2),:);
           
           % keeping the features accounted for each set in each iteration
           training_data = [training_data(:, idx(1:kept_features)) training_data(:,end)];
           checking_data = [checking_data(:, idx(1:kept_features)) checking_data(:,end)];
           testing_data = [testing_data(:, idx(1:kept_features)) testing_data(:,end)];
           
           %  fis
           my_fis = genfis2(training_data(:,1:end-1), training_data(:,end), aktina_r);
           
           %training the model for 100 epoches
           [trnFis,trnError,~,valFis,valError] = anfis(training_data,my_fis,[100 0 0.01 0.9 1.1],[],checking_data);
           
           % calculating all the desired metrics using the testing set
           Y = evalfis(testing_data(:,1:end-1),valFis); 
           R2 = Rsq(Y,testing_data(:,end));
           RMSE = sqrt(mse(Y,testing_data(:,end)));
           NMSE = 1 - R2; % R2 = 1 - NMSE
           NDEI = sqrt(NMSE);
           
           % gathering every error after the cross validation 
           metrics_of_cross_val(repetition,1) = R2;
           metrics_of_cross_val(repetition,2) = RMSE;
           metrics_of_cross_val(repetition,3) = NMSE;
           metrics_of_cross_val(repetition,4) = NDEI;
           
           % disp counter
           counter = counter + 1;
           deixe ="eimai stin " + counter ;
           disp(deixe);
           
        end
        
        % Calculating the mean of each metric after the 5-fold cross validation 
        all_metrics(i,j,1) = sum(metrics_of_cross_val(:,1))/k;
        all_metrics(i,j,2) = sum(metrics_of_cross_val(:,2))/k;
        all_metrics(i,j,3) = sum(metrics_of_cross_val(:,3))/k;
        all_metrics(i,j,4) = sum(metrics_of_cross_val(:,4))/k;
        
        %for plotting
        rmse(i,j) = all_metrics(i,j,2);
        rules(i,j) = size(valFis.Rules,2);
        kept_f(i,j) = kept_features;

    end
end

% PLOTS
% error relevant to number of rules
figure();
scatter(reshape(rmse,1,[]),reshape(rules,1,[])); grid on;
xlabel("RMSE"); 
ylabel("Number of Rules");
title("RMSE relevant to Number of Rules ");

% error relevant to kept features' number
figure();
scatter(reshape(rmse,1,[]),reshape(kept_f,1,[])); grid on;
xlabel("RMSE"); 
ylabel("Number of kept features");
title("RMSE relevant to Number of kept features ");

% error relevant to cluster's radius
figure();
scatter(reshape(rmse,1,[]),reshape(parameters(:,:,2),1,[])); grid on;
xlabel("RMSE"); 
ylabel("Aktina cluster");
title("RMSE relevant with cluster's radius ");

% error surface relevant to cluster's radius and number of features
figure();
surf(all_metrics(:,:,2),parameters(:,:,2),parameters(:,:,1)); grid on;
xlabel("Sfalma"); ylabel("aktina_r"); zlabel("Number of features");
title("Surface of RMSE relevant to cluster's radius and Number of features.");

