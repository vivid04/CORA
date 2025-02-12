function res = test_linearSys_reach_09_decomp()
% test_linearSys_reach_09_decomp - unitTest for the decomposed reachability
%    algorithm from [1], compared to standard reach
%Sys
% Syntax:  
%    res = test_linearSys_reach_09_decomp
%
% Inputs:
%    no
%
% Outputs:
%    res - boolean 
%
% Example: -
%
% References: 
%   [1] S. Bogomolov, M. Forets, G. Frehse, A. Podelski, C. Schilling
%       "Decomposing Reach Set Computations with Low-dimensional Sets
%            and High-Dimensional Matrices"

% Author:       Mark Wetzlinger
% Written:      25-June-2019
% Last update:  14-Aug-2019
%               23-April-2020 (restructure params/options)
% Last revision:---

%------------- BEGIN CODE --------------

res = true;

% Parameters --------------------------------------------------------------

dim_x = 5;
params.tFinal = 3; 
params.R0 = zonotope(ones(dim_x,1),0.1*eye(dim_x));
% for particular solution only ->
% params.R0 = zonotope(zeros(dim,1));
params.U = 0.5*zonotope([1; 0; 0; 0.5; -0.5],diag([0.2, 0.5, 0.2, 0.5, 0.5]));
% for homogeneous solution only ->
% params.U = zonotope(zeros(dim,1));


% Reachability Settings ---------------------------------------------------

options.timeStep      = 0.1;
options.taylorTerms   = 3;
options.zonotopeOrder = 100;


% PART I: no C matrix -> output = states ----------------------------------

A = [-1 -4 0 0 0; 4 -1 0 0 0; 0 0 -3 1 0; 0 0 -1 -3 0; 0 0 0 0 -2];
B = 1;
fiveDimSys=linearSys('fiveDimSys',A,B);

% Reachability Analysis ---------------------------------------------------

options.linAlg = 'fromStart';
tic;
R_fromStart = reach(fiveDimSys, params, options);
tComp = toc;
disp(['computation time of reachable set: ',num2str(tComp)]);

options.linAlg = 'decomp';
options.partition = [1,2; 3,4; 5,5];
tic;
R_decomp = reach(fiveDimSys, params, options);
tComp = toc;
disp(['computation time of reachable set: ',num2str(tComp)]);



% Simulation --------------------------------------------------------------

simOpt.points = 1;
simOpt.fracVert = 0.5;
simOpt.fracInpVert = 0.5;
simOpt.inpChanges = 10;
tic;
simRes = simulateRandom(fiveDimSys, params, simOpt);
tComp = toc;
disp(['computation time of simulation: ',num2str(tComp)]);


% Visualization -----------------------------------------------------------

plotting = false;
plotSim = false;

if plotting
    for plot_run = 1:2
        if plot_run == 1
            projDims = [1 2];
        elseif plot_run == 2
            projDims = [3 4];
        end

        figure;
        hold on

        % plot reachable sets - fromStart
        plot(R_fromStart,projDims,'FaceColor',[.8 .8 .8],'EdgeColor','b');

        % plot reachable sets - decomp
        if plot_run == 1
            plot(R_decomp(1),projDims,'FaceColor',[.6 .6 .6],'EdgeColor','r');
        elseif plot_run == 2
            plot(R_decomp(2),projDims,'FaceColor',[.6 .6 .6],'EdgeColor','r');
        end

        % plot initial set
        plot(params.R0,projDims,'g-','lineWidth',2);

        if plotSim
            % plot simulation results
            plot(simRes,projDims,'y');
        end


        % label plot
        xlabel(['x_{',num2str(projDims(1)),'}']);
        ylabel(['x_{',num2str(projDims(2)),'}']);
    end
end



% compare solutions numerically -------------------------------------------

IH_reach = interval(R_fromStart.timeInterval.set{end});
intTemp = interval(project(R_decomp(1).timeInterval.set{end},...
    options.partition(1,1):options.partition(1,2)));
for b=2:size(options.partition,1)
	intTemp = [intTemp; interval(project(R_decomp(b).timeInterval.set{end},...
       options.partition(b,1):options.partition(b,2)))];
end
IH_decomp = intTemp;

% check if slightly bloated versions enclose each other
res_1 = (IH_reach <= enlarge(IH_decomp,1+1e-8));
res_2 = (IH_decomp <= enlarge(IH_reach,1+1e-8));

% final result
res_zono = res_1 && res_2;

if nnz(~res_zono)
    res = false;
    return
end
% -------------------------------------------------------------------------



% PART II: explicit C matrix ----------------------------------------------

% explicit C matrix
C = [1 -1 0 0 0; -1 1 0 0 0];
fiveDimSys = linearSys('fiveDimSys',A,B,[],C);

% Reachability Analysis ---------------------------------------------------

params.tFinal = 3;
options.linAlg = 'fromStart';
options = rmfield(options,'partition'); % for optionsCheck
tic;
R_fromStart = reach(fiveDimSys, params, options);
tComp = toc;
disp(['computation time of reachable set: ',num2str(tComp)]);

options.linAlg = 'decomp';
options.partition = [1,2; 3,4; 5,5];
tic;
R_decomp = reach(fiveDimSys, params, options);
tComp = toc;
disp(['computation time of reachable set: ',num2str(tComp)]);


% Visualization -----------------------------------------------------------

plotting = false;

if plotting
    projDims = [1 2];

    figure;
    hold on
    
    % plot reachable sets - decomp
    plot(R_decomp(1),projDims,'FaceColor',[.6 .6 .6],'EdgeColor','r');

    % plot reachable sets - standard reach
    plot(R_fromStart,projDims,'FaceColor',[.8 .8 .8],'EdgeColor','b');

    % label plot
    xlabel(['x_{',num2str(projDims(1)),'}']);
    ylabel(['x_{',num2str(projDims(2)),'}']);
end


% compare solutions numerically -------------------------------------------

IH_reach = interval(R_fromStart.timeInterval.set{end});
IH_decomp = interval(project(R_decomp(1).timeInterval.set{end},...
    options.partition(1,1):options.partition(1,2))); % only two dimensions

% check if slightly bloated versions enclose each other
res_1 = (IH_reach <= enlarge(IH_decomp,1+1e-3));
res_2 = (IH_decomp <= enlarge(IH_reach,1+1e-3));

% final result
res_zono = res_1 && res_2;

if ~res_zono
    res = false;
end


%------------- END OF CODE --------------

