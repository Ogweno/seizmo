function [X]=submat(X,varargin)
%SUBMAT    Returns a submatrix reduced along indicated dimensions
%
%    Description: Y=SUBMAT(X,DIM,LIST) creates a matrix Y that is
%     the matrix X reduced along dimension DIM to the indices in LIST.  If
%     DIM is a list of dimensions, LIST is used to reduce each dimension.
%
%     Y=SUBMAT(X,DIM1,LIST1,DIM2,LIST2,...) allows for access to
%     multiple dimensions independently.
%
%    Notes:
%
%    Tested on: Matlab r2007b
%
%    Usage:    Y=submat(X,DIM1,LIST1,DIM2,LIST2,...)
%
%    Examples:
%      Return x reduced to only the elements in index 1 of dimension 5:
%      x=submat(x,5,1)
%
%    See also: submat_eval, colon operator (:), repmat

%     Version History:
%        Nov. 12, 2008 - initial version
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Nov. 12, 2008 at 04:25 GMT

% todo:

% CHECK VARARGIN
if(~mod(nargin,2))
    error('SAClab:submat:badNumArgs',...
        'dimension argument must be followed by indices argument');
end

% DEFAULT TO ENTIRE MATRIX AND EXPAND TO MAX INPUT DIMENSION
list(1:max([ndims(X) [varargin{1:2:end}]]))={':'};

% REDUCED/REPLICATED DIMENSIONS
for i=1:2:nargin-2
    [list{[varargin{i}]}]=deal(varargin{i+1});
end

% SUBSET
X=X(list{:});

end
