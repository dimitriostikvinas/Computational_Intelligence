%% Tikvinas Dimitrios 9998
% Regression best model

%%
close all; 
clear all;


% loading the data and apply normalization in every column except the last
% one being the target variable
data = csvread('superconduct.csv',1,0);
norm_data = data(:,1:end-1);
norm_data = normalize(norm_data);
data = [norm_data(:,1:end) data(:,end)];


% Evaluation function 
Rsq = @(ypred,y) 1-sum((ypred-y).^2)/sum((y-mean(y)).^2);

% splitting the data during the cross validation and not beforehand

kept_features = 12;
radius = 0.4;

% 5-fold cross validation
k = 5;

% Using the built in Matlab function Relief to reduce the number of features 
[idx,weights] = relieff(data(:,1:end-1),data(:,end),6);

% Matrix to store the metrics 
all_metrics = zeros(4);

% Matrix to store the calculated metrics after the cross validation
metrics_of_cross_val = zeros(k,4);



% cv partition for the k-fold
% splitting the data into 80% train and 20% test 
part_for_kfold1 = cvpartition(data(:,end),'KFold',5,'Stratify',true);

% counter gia na metraw tis epanalipseis na mporw na kanw debug
counter = 0;

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
    
    % fis
    my_fis = genfis2(training_data(:,1:end-1), training_data(:,end), radius);
    
    % mf before training
    if repetition == 5
        figure();
        plotmf(my_fis,'input',1);
        titlos = "Input 1 before training";
        title(titlos);
        
        figure();
        plotmf(my_fis,'input',10);
        titlos = "Input 10 before training";
        title(titlos);
    end
    
    % training the model for 120 epoches
    [trnFis,trnError,~,valFis,valError] = anfis(training_data,my_fis,[120 0 0.01 0.9 1.1],[],checking_data);
    
    % calculating all the desired metrics using the training data 
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
all_metrics(1) = sum(metrics_of_cross_val(:,1))/k;
all_metrics(2) = sum(metrics_of_cross_val(:,2))/k;
all_metrics(3) = sum(metrics_of_cross_val(:,3))/k;
all_metrics(4) = sum(metrics_of_cross_val(:,4))/k;

% PLOTS----------------------------------------------------------------

y = zeros(size(Y,1),1);
for i= 1:size(Y,1)
    y(i) = i;
end

% Predicted target variable's values 
figure();
scatter(y,Y); grid on;
xlabel('data'); ylabel('Predicted Values');
title('Predicted Values');


% Real target variable's values 
figure();
scatter(y,testing_data(:,end)); grid on;
xlabel('data'); ylabel('Real Values');
title('Real Values');

%Error plot in test data (prediction)
predict_error = testing_data(:,end) - Y;
figure();
plot(predict_error);
grid on;
xlabel('data');ylabel('Error');
titlos = " Error of Best Modelou ";
title(titlos);


% learning curve
figure();
grid on;
plot([trnError valError]);
xlabel('# of Iterations'); ylabel('Error');
legend('Training Error','Validation Error');
titlos = "Best TSK Model Learning curve";
title(titlos);

% fuzzy sets in their latest form 
figure();
plotmf(valFis,'input',1);
titlos = "Input 1 after training";
title(titlos);

figure();
plotmf(valFis,'input',10);
titlos = "Input 10 after training";
title(titlos);


number_of_rules = size(valFis.Rules,2);

