function []=print_time_left(act_step,tot_step,redraw)
%PRINT_TIME_LEFT    Ascii progress bar
%
%    Usage:    print_time_left(act_step,tot_step)
%              print_time_left(act_step,tot_step,redraw)
%
%    Description: PRINT_TIME_LEFT(ACT_STEP,TOT_STEP) draws an ascii
%     progress bar in the command window with the remaining time left
%     estimated based on having ACT_STEP steps out of TOT_STEPS completed.
%     The progress bar shows the rounded percentage completed within the
%     progress bar along with the steps and the estimated time remaining.
%     Subsequent calls update the previous.  If any outside text is written
%     between calls, use the next usage form to draw a new progress bar
%     that avoids overwriting the outside text.
%
%     PRINT_TIME_LEFT(ACT_STEP,TOT_STEP,REDRAW) redraws the ascii progress
%     bar without deleting any previous text.  Useful for cases when some
%     output occurs from another function.
%
%    Notes:
%     - Only updates when the rounded percent increases.
%
%    Examples:
%     Standard usage format for this function:
%      print_time_left(0,100); % initialize internal timer
%      for i=1:100
%          ... do something ...
%          print_time_left(1,100);
%      end
%
%    See also: WAITBAR

%     Version History:
%        July 20, 2005 - initial version
%        Oct. 14, 2009 - made into single function (with subfunction)
%        Jan. 26, 2010 - fixed bug where no redraw is done when specified,
%                        now updates when last and current steps differ in
%                        percent, some caller detection added
%
%     Written by Nicolas Le Roux (lerouxni at iro dot umontreal dot ca)
%                Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Jan. 26, 2010 at 17:25 GMT

% todo:
% - preceeding warning message links are missing occasionally?

% check nargin
msg=nargchk(2,3,nargin);
if(~isempty(msg)); error(msg); end

% check steps
if(~isscalar(act_step) || ~isnumeric(act_step))
    error('seizmo:print_time_left:badInput',...
        'ACT_STEP must be a numeric scalar!');
elseif(~isscalar(tot_step) || ~isnumeric(tot_step))
    error('seizmo:print_time_left:badInput',...
        'TOT_STEP must be a numeric scalar!');
end

% declare persistent vars
persistent nb i old_step old_fun
if(~exist('old_step','var') || isempty(old_step)); old_step=act_step-1; end

% who called last time & this time
[st]=dbstack;
cur_fun=st(2).name;
if(~exist('old_fun','var') || isempty(old_fun)); old_fun=cur_fun; end

% default redraw
if(nargin==2); redraw=false; end

% redraw if new caller (should help catch some bugs)
if(~strcmpi(old_fun,cur_fun)); redraw=true; end
old_fun=cur_fun;

% percent complete
old_perc_complete=floor(100*old_step/tot_step);
perc_complete=floor(100*act_step/tot_step);
old_step=act_step;

% update if redrawing or new percent or if 0th step
if(old_perc_complete~=perc_complete || ~act_step || redraw)
    % internally keep track of output length and timer
    if(~act_step || ~exist('nb','var') || isempty(nb)); nb=0; end
    if(~act_step || ~exist('i','var') || isempty(i)); i=tic; end
    if(redraw); nb=0; end
    
    % time spent so far
    time_spent=toc(i);
    
    % estimated time per step
    est_time_per_step=time_spent/act_step;
    
    % estimated remaining time
    est_rem_time=(tot_step-act_step)*est_time_per_step;
    
    % create steps string
    str_steps=[' ' num2str(act_step) '/' num2str(tot_step)];
    
    % correctly print the remaining time
    if(floor(est_rem_time/60)>=1)
        str_time=[' ' num2str(floor(est_rem_time/60)) 'm' ...
            num2str(floor(rem(est_rem_time,60))) 's'];
    else
        str_time=[' ' num2str(floor(rem(est_rem_time,60))) 's'];
    end
    
    % create the string [***** xx%    ] act_step/tot_step (1m36s)
    str_pb=progress_bar(perc_complete);
    str_tot=strcat(str_pb,str_steps,str_time);
    
    % print progress
    fprintf(1,strcat(repmat('\b',1,nb),str_tot,'\n'));
    nb=numel(str_tot); % account for %% and linefeed
end

% clear persistent vars if done (for later calls)
if(act_step==tot_step); nb=[]; i=[]; old_step=[]; old_fun=[]; end

end

function [str_pb]=progress_bar(percentage)
%PROGRESS_BAR    Creates ascii progress bar based on percentage complete

% percentage string
str_perc = [' ' num2str(percentage) '%%'];

% only need to consider the closest integer
percentage=floor(percentage);

% which half?
if(percentage<51)
    % [##=  XX%    ]
    str_hash=char(ones(1,fix(percentage/2))*35);
    str_equal=char(ones(1,mod(percentage,2))*61);
    str_dash_beg=...
        char(ones(1,max(0,25-numel(str_hash)-numel(str_equal)))*45);
    str_dash_end=char([32 ones(1,25)*45]);
    str_pb=strcat(...
        '[',str_hash,str_equal,str_dash_beg,str_perc,str_dash_end,']');
else
    % [#### XX% ##= ]
    str_hash_beg=char(ones(1,25)*35);
    str_hash_end=char(ones(1,max(0,fix((percentage-50)/2)))*35);
    str_equal=char(ones(1,mod(percentage,2))*61);
    str_dash=char(ones(1,25-numel(str_hash_end)-numel(str_equal))*45);
    str_pb=char(strcat('[',str_hash_beg,str_perc,...
        {' '},str_hash_end,str_equal,str_dash,']'));
end

end
