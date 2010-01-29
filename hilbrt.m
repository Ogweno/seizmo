function [data]=hilbrt(data)
%HILBRT    Return Hilbert transform of SEIZMO records
%
%    Usage:    data=hilbrt(data)
%
%    Description: HILBRT(DATA) calculates and returns the Hilbert transform
%     of SEIZMO records.  The Hilbert tranform is simply a -90 degree phase
%     shift.
%
%    Notes:
%
%    Header changes: DEPMEN, DEPMIN, DEPMAX
%
%    Examples:
%     To do a positive 90 degree phase shift:
%      data=hilbrt(multiply(data,-1))
%
%    See also: ENVELOPE, INSTANTPHASE

%     Version History:
%        Jan. 30, 2008 - initial version
%        Feb. 28, 2008 - seischk support and class support
%        Mar.  4, 2008 - doc update
%        May  12, 2998 - dep* fix
%        June 12, 2008 - minor doc update
%        July 17, 2008 - history update, doc update, now uses
%                        SEIZMO functions rather than Matlab's hilbert
%        Nov. 22, 2008 - doc update, update for new name schema
%        Apr. 23, 2009 - fix nargchk for octave, move usage up
%        Oct. 15, 2009 - does data and header checking now, try/catch will
%                        assure checking state is kept correct, no longer
%                        calls other SEIZMO functions
%        Oct. 19, 2009 - added checks for IFTYPE and LEVEN
%        Jan. 29, 2010 - seizmoverbose support, better warnings
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Jan. 29, 2010 at 17:50 GMT
% todo:

% check nargin
msg=nargchk(1,1,nargin);
if(~isempty(msg)); error(msg); end

% check data structure
msg=seizmocheck(data,'dep');
if(~isempty(msg)); error(msg.identifier,msg.message); end

% turn off struct checking
oldseizmocheckstate=seizmocheck_state(false);

% attempt hilbert
try
    % check header
    data=checkheader(data);

    % verbosity
    verbose=seizmoverbose;

    % number of records
    nrecs=numel(data);
    
    % get header info
    [npts,ncmp]=getheader(data,'npts','ncmp');
    nspts=2.^(nextpow2n(npts)+1);
    leven=getlgc(data,'leven');
    iftype=getenumid(data,'iftype');
    
    % cannot do spectral/xyz records
    if(any(~strcmpi(iftype,'itime') & ~strcmpi(iftype,'ixy')))
        error('seizmo:hilbrt:badIFTYPE',...
            ['Record(s):\n' sprintf('%d ',...
            find(~strcmpi(iftype,'itime') & ~strcmpi(iftype,'ixy'))) ...
            '\nDatatype of record(s) in DATA must be Timeseries or XY!']);
    end
    
    % cannot do unevenly sampled records
    if(any(strcmpi(leven,'false')))
        error('seizmo:hilbrt:badLEVEN',...
            ['Record(s):\n' sprintf('%d ',find(strcmpi(leven,'false'))) ...
            '\nInvalid operation on unevenly sampled record(s)!']);
    end
    
    % detail message
    if(verbose)
        disp('Getting Hilbert Transform of Record(s)');
        print_time_left(0,nrecs);
    end
    
    % loop over records
    depmin=nan(nrecs,1); depmen=depmin; depmax=depmin;
    for i=1:nrecs
        % skip dataless
        if(isempty(data(i).dep))
            % detail message
            if(verbose); print_time_left(i,nrecs); end
            continue;
        end
        
        % save class and convert to double precision
        oclass=str2func(class(data(i).dep));
        data(i).dep=double(data(i).dep);
        
        % multiplier to give analytic signal
        h=zeros(nspts(i),1);
        h([1 nspts(i)/2+1])=1;
        h(2:(nspts(i)/2))=2;
        
        % get hilbert
        data(i).dep=imag(ifft(...
            fft(data(i).dep,nspts(i),1).*h(:,ones(1,ncmp(i))),[],1));
        
        % truncate to original length and change class back
        data(i).dep=oclass(data(i).dep(1:npts(i),:));
        
        % dep*
        depmen(i)=mean(data(i).dep(:)); 
        depmin(i)=min(data(i).dep(:)); 
        depmax(i)=max(data(i).dep(:));
        
        % detail message
        if(verbose); print_time_left(i,nrecs); end
    end
    
    % update header
    data=changeheader(data,...
        'depmen',depmen,'depmin',depmin,'depmax',depmax);
    
    % toggle checking back
    seizmocheck_state(oldseizmocheckstate);
catch
    % toggle checking back
    seizmocheck_state(oldseizmocheckstate);
    
    % rethrow error
    error(lasterror)
end

end
