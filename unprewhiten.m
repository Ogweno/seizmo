function [data]=unprewhiten(data)
%UNPREWHITEN    Undo prewhitening of SEIZMO data records
%
%    Usage:    data=unprewhiten(data)
%
%    Description: UNPREWHITEN(DATA) restores the predictable portion of
%     records in DATA by inversely applying the prediction error filter
%     stored in the .misc.pef field in DATA.  This effectively undoes
%     PREWHITEN.  Records are required to have the .misc.prewhitened' field
%     set to TRUE.  See function PREWHITEN and the suggested reading in the
%     Notes section for more detailed information.  The returned dataset
%     DATA will have each record's .misc.pef field set to an empty array
%     and the .misc.prewhitened field set to FALSE.
%
%    Notes:
%     - Suggested Reading:
%       - Vaidyanathan, P. P., The Theory of Linear Prediction, Synthesis
%         Lectures on Signal Processing #3, Morgan and Claypool Publishers,
%         183 pp.
%
%    Header changes: DEPMIN, DEPMAX, DEPMEN
%
%    Examples:
%     Try prewhitening and unprewhitening first.  Then try comparing some
%     operation without prewhiten/unprewhiten with one including it to get
%     a feel for how important/detrimental it is.  Plotting the difference:
%      plot1(subtractrecords(data,unprewhiten(prewhiten(data))))
%
%    See also: PREWHITEN, LEVINSON, FILTER, WHITEN

%     Version History:
%        June  8, 2009 - initial version
%        June  9, 2009 - renamed from UNWHITEN to UNPREWHITEN, doc fixes
%        Sep. 22, 2009 - pushed .pef & .prewhitened to .misc.pef &
%                        .misc.prewhitened (avoids struct cat errors)
%        Oct. 13, 2009 - minor doc update
%        Jan. 27, 2010 - seizmoverbose support, better error messages,
%                        force dim stuff
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Jan. 27, 2010 at 23:40 GMT

% todo:

% check number of inputs
msg=nargchk(1,1,nargin);
if(~isempty(msg)); error(msg); end

% check data structure
msg=seizmocheck(data,'dep');
if(~isempty(msg)); error(msg.identifier,msg.message); end

% turn off struct checking
oldseizmocheckstate=get_seizmocheck_state;
set_seizmocheck_state(false);

% attempt header check
try
    % check headers
    data=checkheader(data);
    
    % turn off header checking
    oldcheckheaderstate=get_checkheader_state;
    set_checkheader_state(false);
catch
    % toggle checking back
    set_seizmocheck_state(oldseizmocheckstate);
    
    % rethrow error
    error(lasterror)
end

% attempt prewhitening
try
    % verbosity
    verbose=seizmoverbose;

    % number of records
    nrecs=numel(data);

    % get some header fields
    leven=getlgc(data,'leven');
    iftype=getenumid(data,'iftype');
    ncmp=getncmp(data);

    % require evenly-spaced time series, general x vs y
    if(any(~strcmpi(leven,'true')))
        error('seizmo:unprewhiten:illegalOperation',...
            ['Record(s):\n' sprintf('%d ',find(strcmpi(leven,'false'))) ...
            '\nIllegal operation on unevenly sampled record(s)!']);
    elseif(any(~strcmpi(iftype,'itime') & ~strcmpi(iftype,'ixy')))
        error('seizmo:unprewhiten:illegalOperation',...
            ['Record(s):\n' sprintf('%d ',...
            find(~strcmpi(iftype,'itime') & ~strcmpi(iftype,'ixy'))) ...
            '\nDatatype of record(s) must be Timeseries or XY!']);
    end

    % pull .misc field out
    misc=[data.misc];

    % error for nonprewhitened
    if(isfield(misc,'prewhitened') && ...
            isfield(misc,'pef') && ...
            islogical([misc.prewhitened]) && ...
            numel([misc.prewhitened])==nrecs)
        idx=[misc.prewhitened];
    else
        % prepare a decent list for the error msg
        try
            % list records that are unset or false
            [misc(cellfun('isempty',...
                {misc.prewhitened})).prewhitened]=deal(false);
            idx=[misc.prewhitened];
        catch
            % list them all
            idx=false(nrecs,1);
        end
    end
    if(any(~idx))
        i=find(~idx);
        error('seizmo:unprewhiten:recordsNotPrewhitened',...
            ['Record(s): ' sprintf('%d ',i) '\n'...
            'Cannot unprewhiten non-prewhitened records!']);
    end

    % detail message
    if(verbose)
        disp('Un-Prewhitening Record(s)');
        print_time_left(0,nrecs);
    end

    % loop through whitened records
    depmen=nan(nrecs,1); depmin=depmen; depmax=depmen;
    for i=find(idx)
        % get class
        oclass=str2func(class(data(i).dep));

        % check pef matches ncmp
        if(size(data(i).misc.pef,1)~=ncmp(i))
            error('seizmo:unprewhiten:ncmpInconsistent',...
                'Record: %d\nNCMP has changed since WHITEN operation!',i);
        end

        % unwhiten filter
        for j=1:ncmp(i)
            data(i).dep(:,j)=oclass(...
                filter(1,data(i).misc.pef(j,:),...
                double(data(i).dep(:,j)),[],1));
        end

        % unset prewhitened, clear pef
        data(i).misc.prewhitened=false;
        data(i).misc.pef=[];

        % detail message
        if(verbose); print_time_left(i,nrecs); end

        % update dep*
        if(isempty(data(i).dep)); continue; end
        depmen(i)=mean(data(i).dep(:));
        depmin(i)=min(data(i).dep(:));
        depmax(i)=max(data(i).dep(:));
    end
    
    % detail message
    if(verbose && i~=nrecs)
        print_time_left(nrecs,nrecs);
    end

    % update header
    data=changeheader(data,...
        'depmen',depmen,'depmin',depmin,'depmax',depmax);

    % toggle checking back
    set_seizmocheck_state(oldseizmocheckstate);
    set_checkheader_state(oldcheckheaderstate);
catch
    % toggle checking back
    set_seizmocheck_state(oldseizmocheckstate);
    set_checkheader_state(oldcheckheaderstate);
    
    % rethrow error
    error(lasterror)
end

end
