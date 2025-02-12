function matP = matPolytope(matI)
% matPolytopes - converts an interval matrix to a matrix polytope
%
% Syntax:  
%    matP = matPolytope(matI)
%
% Inputs:
%    matI - interval matrix 
%
% Outputs:
%    matP - polytope matrix
%
% Example: 
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: plus

% Author:       Matthias Althoff
% Written:      21-June-2010 
% Last update:  06-May-2021
% Last revision:---

%------------- BEGIN CODE --------------

%obtain vertices
V = vertices(matI);

%instantiate matrix polytope
matP=matPolytope(V);

%------------- END OF CODE --------------