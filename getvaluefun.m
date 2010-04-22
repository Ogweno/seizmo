function [value]=getvaluefun(data,func,type,scalar)
%GETVALUEFUN    Applies a function to SEIZMO records and returns the value
%
%    Usage:    value=getvaluefun(data,func)
%              value=getvaluefun(data,func,cmptype)
%              value=getvaluefun(data,func,cmptype,scalarOutput)
%
%    Description: VALUE=GETVALUEFUN(DATA,FUNC) applies the function handle
%     FUNC to the dependent component of records in SEIZMO struct DATA.
%     The function FUNC is expected to return a scalar value.  The values
%     are returned in VALUE (a Nx1 column vector where N is the number of
%     records in DATA).
%
%     VALUE=GETVALUEFUN(DATA,FUNC,CMPTYPE) specifies whether FUNC is
%     applied to the dependent or independent data using CMPTYPE.  CMPTYPE
%     must be either 'dep' or 'ind'.  The default value is 'dep'.  An empty
%     value ([]) also will specify the default value.
%
%     VALUE=GETVALUEFUN(DATA,FUNC,CMPTYPE,SCALAROUTPUT) allows returning
%     non-scalar output in VALUE when SCALAROUTPUT is set FALSE.  VALUE
%     will be a Nx1 cell array in this case.  The default SCALAROUTPUT is
%     TRUE.
%
%    Notes:
%     - Both .dep & .ind data fields are always passed in double precision.
%
%    Examples:
%     Get dependent data medians:
%      medians=getvaluefun(data,@median);
%
%     If you have multi-cmp records the following may be necessary:
%      medians=getvaluefun(data,@(x)median(x(:)));
%     or (if you want the median for each component):
%      medians=getvaluefun(data,@median,[],false);
%
%     Get a robust RMS:
%      rms=getvaluefun(data,@(x)sqrt(median(x.^2-median(x).^2)));
%
%     Get maximum amplitude of multi-cmp records assuming each component is
%     orthogonal (was an old function called getnorm):
%      normalizers=getvaluefun(data,@(x)max(sqrt(sum(x.^2,2))));
%
%    See also: SEIZMOFUN, SLIDINGFUN, RECORDFUN

%     Version History:
%        Mar. 18, 2010 - initial version
%        Mar. 20, 2010 - fixed bug that added extra time point
%        Mar. 26, 2010 - added example to copy GETNORM (now deprecated)
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Mar. 26, 2010 at 17:45 GMT

% todo:

% check nargin
msg=nargchk(2,4,nargin);
if(~isempty(msg)); error(msg); end

% check data structure
versioninfo(data,'dep');

% turn off struct checking
oldseizmocheckstate=seizmocheck_state(false);

% attempt to apply function
try
    % verbosity
    verbose=seizmoverbose;
    
    % defaults
    if(nargin<3 || isempty(type)); type='dep'; end
    if(nargin<4 || isempty(scalar)); scalar=true; end

    % check other arguments
    if(~isa(func,'function_handle'))
        error('seizmo:getvaluefun:badInput',...
            'FUNC must be a function handle!');
    elseif(~ischar(type) || size(type,1)~=1 || ...
            ~any(strcmpi(type,{'dep' 'ind'})))
        error('seizmo:getvaluefun:badInput',...
            'CMPTYPE must be one of the following:\n''DEP'' or ''IND''');
    elseif(~isscalar(scalar) || ~islogical(scalar))
        error('seizmo:getvaluefun:badInput',...
            'SCALAROUTPUT must be TRUE or FALSE!');
    end

    % number of records
    nrecs=numel(data);

    % preallocate value
    if(scalar)
        value=nan(nrecs,1);
    else
        value=cell(nrecs,1);
    end

    % which cmp are we working on?
    type=lower(type);
    switch type
        case 'dep'
            % detail message
            if(verbose)
                disp('Getting Value From Dependent Data of Record(s)');
                print_time_left(0,nrecs);
            end
            
            % apply function
            if(scalar)
                for i=1:nrecs
                    value(i)=func(double(data(i).dep));
                    
                    % detail message
                    if(verbose); print_time_left(i,nrecs); end
                end
            else
                for i=1:nrecs
                    value{i}=func(double(data(i).dep));
                    
                    % detail message
                    if(verbose); print_time_left(i,nrecs); end
                end
            end
        case 'ind'
            % fill .ind for evenly spaced arrays
            even=~strcmpi(getlgc(data,'leven'),'false');
            
            % are any are evenly spaced?
            if(any(even))
                % pull header values
                [b,delta,npts]=getheader(data(even),'b','delta','npts');
                
                % loop over even, add .ind
                idx=find(even);
                for i=1:sum(even)
                    data(idx(i)).ind=b(i)+(0:npts(i)-1)'*delta(i);
                end
            end
            
            % detail message
            if(verbose)
                disp('Getting Value From Independent Data of Record(s)');
                print_time_left(0,nrecs);
            end

            % apply function
            if(scalar)
                for i=1:nrecs
                    value(i)=func(double(data(i).ind));
                    
                    % detail message
                    if(verbose); print_time_left(i,nrecs); end
                end
            else
                for i=1:nrecs
                    value{i}=func(double(data(i).ind));
                    
                    % detail message
                    if(verbose); print_time_left(i,nrecs); end
                end
            end
    end

    % toggle checking back
    seizmocheck_state(oldseizmocheckstate);
catch
    % toggle checking back
    seizmocheck_state(oldseizmocheckstate);

    % rethrow error
    error(lasterror)
end

end