function vprintf(v,l,varargin)
% VPRINTF(verbosity, verbosity_level_of_statement,sprintf_style_arguments
% 
% example: 
% 
% verbosity = 1;
% vprintf(verbosity,1,'This will print if verbosity is at least 1\n Verbosity = %i\n',verbosity);

if v>=l % if verbosity level is >= level of this statment
%     keyboard;
    fprintf(varargin{:});
end