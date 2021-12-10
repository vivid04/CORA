function [y] = reset(obj,x)
% reset - resets the continuous state according the reset function
%
% Syntax:  
%    y = reset(obj,x)
%
% Inputs:
%    obj - transition object
%    x - state value before the reset
%
% Outputs:
%    y - state value after the reset
%
% References:
%    [1] N. Kochdumper and et al. "Reachability Analysis for Hybrid Systems
%        with Nonlinear Guard Sets", HSCC 2020
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: transition

% Author:       Matthias Althoff, Niklas Kochdumper
% Written:      04-May-2007 
% Last update:  07-October-2008
%               10-December-2021 (NK, added nonlinear reset functions)
% Last revision: ---

%------------- BEGIN CODE --------------

    % get correct orientation of x
    m = size(x,2);
    if m ~= 1
        x = x';
    end

    % loop over all points
    if ~iscell(x)
        if isfield(obj.reset,'A')                       % linear reset
            y = obj.reset.A*x + obj.reset.b;
        else                                            % nonlinear reset
            if isnumeric(x)
               y = obj.reset.f(x);
            else
               y = nonlinearReset(obj,x); 
            end
        end
    else
        y = cell(length(x));
        for i = 1:length(x)
            if ~isempty(x{i})
                if isfield(obj.reset,'A')               % linear reset
                    y{i} = obj.reset.A*x{i}+b;
                else                                    % nonlinear reset
                    if isnumeric(y{i})
                        y{i} = obj.reset.f(x{i});
                    else
                        y{i} = nonlinearReset(obj,x{i});
                    end
                end
            end
        end
    end
end


% Auxiliary Functions -----------------------------------------------------

function Y = nonlinearReset(obj,X)
% compute the resulting set for a nonlinear reset function using the
% approach described in Sec. 4.4 in [1]

    % Taylor series expansion point
    p = center(X);
    
    % interval enclosure of set
    int = interval(X);
    
    % evaluate derivatives
    f = obj.reset.f(p);
    J = obj.reset.J(p);
    
    Q = cell(length(f),1);
    for i = 1:length(f)
       funHan = obj.reset.Q{i};
       Q{i} = funHan(p);
    end
    
    T = cell(size(J));
    for i = 1:size(J,1)
        for j = 1:size(J,2)
            if ~isempty(obj.reset.T{i,j})
                funHan = obj.reset.T{i,j};
                T{i,j} = funHan(int);
            end
        end
    end

    % compute Largrange remainder
    int = int - p;
    rem = interval(zeros(size(T,1),1));
    
    for i = 1:size(T,1)
        for j = 1:size(T,2)
            if ~isempty(T{i,j})
                rem(i) = rem(i) + int(j) * transpose(int) * T{i,j} * int;
            end
        end
    end
    
    rem = zonotope(1/6*rem);

    % compute over-approximation using a Taylor series of order 2
    Y = f + J * (X + (-p)) + 0.5*quadMap((X + (-p)),Q) + rem;
end

%------------- END OF CODE --------------