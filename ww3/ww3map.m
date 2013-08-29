function [varargout]=ww3map(s,rng,varargin)
%WW3MAP    Maps WaveWatch III hindcast data
%
%    Usage:    ww3map('file')
%              ww3map('file',rng)
%              ww3map('file',rng,'mmap_opt1',mmap_val1,...)
%              ww3map(s,...)
%              ax=ww3map(...)
%
%    Description:
%     WW3MAP('FILE') maps the WaveWatch III hindcast data contained in the
%     GRiB or GRiB2 file FILE averaged across all the records (basically
%     showing the average for the time span of the data in the GRiB file).
%     One map per data type (this only matters for wind which means the u/v
%     components are drawn seperately).  If no filename is given a GUI is
%     presented for the user to select a WW3 hindcast file.
%
%     WW3MAP('FILE',RNG) sets the colormap limits of the data. The default
%     is [0 15] which works well for significant wave heights.  A scale of
%     [0 25] will prevent saturation of wave heights & periods.
%
%     WW3MAP('FILE',RNG,'MMAP_OPT1',MMAP_VAL1,...) passes additional
%     options on to MMAP to alter the map.
%
%     WW3MAP('FILE',RNG,PROJOPT,FGCOLOR,BGCOLOR,AX) sets the axes to draw
%     in.  This is useful for subplots, guis, etc.  AX must have the same
%     number of elements as S.DATA (as in one plot per data type).  The
%     default creates a new figure.
%
%     WW3MAP(S,...) plots the WaveWatch III data contained in the
%     structure S created by WW3STRUCT.  The plots average the data across
%     all records for each data type.
%
%     AX=WW3MAP(...) returns the axes drawn in.
%
%    Notes:
%     - Requires that the njtbx toolbox is installed!
%     - Passing the 'parent' MMAP option requires as many axes as
%       datatypes.  This will only matter for wind data.
%
%    Examples:
%     % Read the first record of a NOAA WW3 grib file and map it:
%     s=ww3struct('nww3.hs.200607.grb',1);
%     ax=ww3map(s);
%
%    See also: WW3STRUCT, WW3MAPMOV, PLOTWW3, WW3MOV, WW3REC

%     Version History:
%        May   5, 2012 - initial version
%        Sep.  5, 2012 - set nan=0 for ice
%        Oct.  5, 2012 - no file bugfix for rng
%        Aug. 27, 2013 - use mmap image option
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Aug. 27, 2013 at 00:40 GMT

% todo:

% check ww3 input
if(nargin==0) % gui selection of grib file
    % attempt reading in first record of file
    % - this does the gui & checks file is valid
    s=ww3struct();
    if(~isscalar(s))
        error('seizmo:ww3map:badWW3',...
            'PLOTWW3 can only handle 1 file!');
    end
elseif(isstruct(s))
    valid={'path' 'name' 'description' 'units' 'data' ...
        'lat' 'lon' 'time' 'latstep' 'lonstep' 'timestep'};
    if(~isscalar(s) || any(~ismember(valid,fieldnames(s))))
        error('seizmo:ww3map:badWW3',...
            'S must be a scalar struct generated by WW3STRUCT!');
    end
elseif(ischar(s)) % filename given
    % attempt reading in first record of file
    % - this does the gui & checks file is valid
    s=ww3struct(s);
else
    error('seizmo:ww3map:badWW3',...
        'FILE must be a string!');
end

% default/check color limits
if(nargin<=1 || isempty(rng)); rng=[0 15]; end
if(~isreal(rng) || ~isequal(size(rng),[1 2]) || rng(1)>rng(2))
    error('seizmo:ww3map:badRNG',...
        'RNG must be a real-valued 2 element vector as [low high]!');
end

% check options are strings
if(~iscellstr(varargin(1:2:end)))
    error('seizmo:ww3map:badOption',...
        'All Options must be specified with a string!');
end

% check number of axes
ndata=numel(s.data);
defax=cell(ndata,1);
for i=1:2:numel(varargin)
    switch lower(varargin{i})
        case {'axis' 'ax' 'a' 'parent' 'pa' 'par'}
            if(numel(varargin{i+1})~=ndata)
                error('seizmo:ww3map:badAX',...
                    'Number of axes must equal the number of datatypes!');
            else
                defax=num2cell(varargin{i+1});
            end
    end
end

% a couple mmap default changes
% - use min/max of lat/lon as the map boundary
% - do not show land/ocean
varargin=[{'po' {'lat' [min(s.lat) max(s.lat)] ...
    'lon' [min(s.lon) max(s.lon)]} 'l' false 'o' false} varargin];

% time string
if(numel(s.time)==1)
    tstring=datestr(s.time,31);
else % >1
    tstring=[datestr(min(s.time),31) ' to ' datestr(max(s.time),31)];
end

% loop over data types
ax=nan(ndata,1);
for i=1:ndata
    % average data (convert nan to 0 to handle ice)
    s.data{i}(isnan(s.data{i}))=0;
    if(size(s.data{i},3)>1)
        s.data{i}=mean(s.data{i},3);
    end
    
    % draw map
    ax(i)=mmap('image',{s.lat s.lon s.data{i}.'},...
        varargin{:},'parent',defax{i});
    
    % extract color
    bg=get(get(ax(i),'parent'),'color');
    fg=get(findobj(ax(i),'tag','m_grid_box'),'color');
    
    % set colormap
    if(strcmp(bg,'w') || isequal(bg,[1 1 1]))
        colormap(ax(i),flipud(fire));
    elseif(strcmp(bg,'k') || isequal(bg,[0 0 0]))
        colormap(ax(i),fire);
    else
        if(ischar(bg)); bg=name2rgb(bg); end
        hsv=rgb2hsv(bg);
        colormap(ax(i),hsvcustom(hsv));
    end
    set(ax(i),'clim',rng);
    
    % labeling
    title(ax(i),...
        {'NOAA WaveWatch III Hindcast' s.description{i} tstring},...
        'color',fg);
    
    % colorbar
    c=colorbar('eastoutside','peer',ax(i),'xcolor',fg,'ycolor',fg);
    xlabel(c,s.units{i},'color',fg);
end

% output if wanted
set(ax,'tag','ww3map');
if(nargout); varargout{1}=ax; end

end
