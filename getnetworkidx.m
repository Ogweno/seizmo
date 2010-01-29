function [idx,networkcode]=getnetworkidx(data)
%GETNETWORKIDX    Returns index array for separating dataset into networks
%
%    Usage:    idx=getnetworkidx(data)
%              [idx,networkcode]=getnetworkidx(data)
%
%    Description: IDX=GETNETWOKIDX(DATA) returns an array of indices that
%     indicate records in SEIZMO structure DATA belonging to a network.  A
%     network is defined by the field KNETWK.
%
%     [IDX,STREAMCODE]=GETNETWORKIDX(DATA) also returns the unique network
%     codes used to separate the networks.
%
%    Notes:
%     - Case insensitive; all characters are upper-cased.
%
%    Examples:
%     Break a dataset up into separate networks:
%      idx=getnetworkidx(data)
%      for i=1:max(idx)
%          networkdata{i}=data(idx==i);
%      end
%
%    See also: GETSTREAMIDX, GETSTATIONIDX, GETCOMPONENTIDX

%     Version History:
%        June 28, 2009 - initial version
%        Jan. 29, 2010 - cleaned up unnecessary code
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Jan. 29, 2010 at 23:20 GMT

% todo:

% check nargin
msg=nargchk(1,1,nargin);
if(~isempty(msg)); error(msg); end

% get network groups
[networkcode,idx,idx]=unique(upper(getheader(data,'knetwk')));

end
